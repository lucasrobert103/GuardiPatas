class_name HomeScreen
extends Control
## Casinha interativa: cuidados individuais, banho com gestos, brincadeira e roupas.
signal go(screen: String, arg: Variant)

const FLOOR_Y := 0.48
var _pets: Array[Pet] = []
var _room: Room
var _hearts: Node2D
var _selected := ""
var _mode := "food"
var _tool := ""
var _soap := 0.0
var _rinse := 0.0
var _food_flash := ""
var _food_timer := 0.0
var _tick := 0.0
var _autosave := 0.0
var _dirty := false
var _status: Label
var _summary: Label
var _selector: OptionButton
var _actions: VBoxContainer
var _bars := {}
var _ball: Button
var _catches := 0
var _preview := ""
var _effects: CareEffects


class Pet:
	extends RefCounted
	var art: AnimalArt
	var x := 0.0
	var depth := 0.0
	var target := 0.0
	var wait := 0.0
	var happy := 0.0
	var hop := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_room = Room.new()
	add_child(_room)
	for species in PetCare.roster():
		var pet := Pet.new()
		pet.art = AnimalArt.new()
		pet.art.species = species
		pet.art.preview = true
		pet.art.accessory = Game.equipped(species)
		pet.x = randf_range(90, 630)
		pet.depth = randf()
		pet.target = pet.x
		pet.wait = randf_range(1.0, 3.0)
		add_child(pet.art)
		_pets.append(pet)
		PetCare.state(species)
	_selected = _pets[0].art.species
	_hearts = Node2D.new()
	_hearts.z_index = 16
	add_child(_hearts)
	_effects = CareEffects.new()
	_effects.home = self
	_effects.z_index = 15
	add_child(_effects)
	_build_ui()
	_refresh()
	_build_actions()
	Sfx.music("music_menu")


func _exit_tree() -> void:
	_flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_flush()


func _flush() -> void:
	if _dirty and Game.save():
		_dirty = false


func _label(text: String, size_px: int = 24) -> Label:
	var label := UiKit.label(text, size_px, Palette.UI_TEXT, 0, Palette.WHITE, true)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, callback: Callable, color: Color = Palette.UI_SECONDARY) -> Button:
	var button := UiKit.button(text, color, "", 0, 64)
	button.add_theme_font_size_override("font_size", UiKit.fs(24))
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		var style := button.get_theme_stylebox(state_name).duplicate() as StyleBoxFlat
		style.content_margin_left = 12
		style.content_margin_right = 12
		button.add_theme_stylebox_override(state_name, style)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	return button


func _build_ui() -> void:
	var top := UiKit.vbox(8)
	top.z_index = 20
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 20
	add_child(top)
	var header := UiKit.hbox(12)
	top.add_child(header)
	var back := _button("Voltar", func(): go.emit("title", null))
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	header.add_child(back)
	var title := _label("Casinha da Turma", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(title)
	var album := _button("Álbum", func(): go.emit("album", null))
	album.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(album)
	_selector = OptionButton.new()
	_selector.custom_minimum_size.y = 54
	_selector.add_theme_font_size_override("font_size", UiKit.fs(26))
	for pet in _pets:
		_selector.add_item(PetCare.pet_name(pet.art.species))
	_selector.item_selected.connect(func(index: int): _select(_pets[index].art.species))
	top.add_child(_selector)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(grid)
	for spec in [["food", "Barriguinha"], ["clean", "Higiene"], ["energy", "Energia"], ["love", "Carinho"]]:
		var col := UiKit.vbox(2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(col)
		var name_label := _label(spec[1], 20)
		col.add_child(name_label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 20)
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var track := StyleBoxFlat.new()
		track.bg_color = Color("e4d6d0")
		track.set_corner_radius_all(8)
		var fill := track.duplicate() as StyleBoxFlat
		fill.bg_color = Palette.UI_GOOD
		bar.add_theme_stylebox_override("background", track)
		bar.add_theme_stylebox_override("fill", fill)
		col.add_child(bar)
		_bars[spec[0]] = [name_label, bar, spec[1]]
	_summary = _label("", 20)
	top.add_child(_summary)
	var bottom := UiKit.panel(Color("fff7e8"))
	bottom.z_index = 20
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 12
	bottom.offset_right = -12
	bottom.offset_top = -400
	bottom.offset_bottom = -16
	add_child(bottom)
	var box := UiKit.vbox(8)
	bottom.add_child(box)
	var tabs := GridContainer.new()
	tabs.columns = 5
	tabs.add_theme_constant_override("h_separation", 6)
	box.add_child(tabs)
	for spec in [["food", "Comida"], ["bath", "Banho"], ["sleep", "Soneca"], ["play", "Brincar"], ["clothes", "Roupas"]]:
		tabs.add_child(_button(spec[1], _set_mode.bind(spec[0])))
	_status = _label("Escolha um cuidado e toque no bichinho. Os cuidados são gratuitos!", 22)
	_status.custom_minimum_size.y = 54
	box.add_child(_status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_actions = UiKit.vbox(8)
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_actions)
	_ball = _button("Bola", _play_ball, Palette.GOLD)
	_ball.z_index = 18
	_ball.custom_minimum_size = Vector2(100, 70)
	_ball.visible = false
	add_child(_ball)


func _select(species: String) -> void:
	if not PetCare.roster().has(species):
		return
	_selected = species
	_soap = 0.0
	_tool = ""
	_preview = ""
	for i in _pets.size():
		_pets[i].art.accessory = Game.equipped(_pets[i].art.species)
		if _pets[i].art.species == species:
			_selector.select(i)
	_refresh()
	_build_actions()


func _set_mode(mode: String) -> void:
	_mode = mode
	_tool = ""
	_preview = ""
	for pet in _pets:
		pet.art.accessory = Game.equipped(pet.art.species)
	_ball.visible = mode == "play"
	_ball.position = Vector2(size.x * 0.7, size.y * 0.42)
	_status.text = tr("Escolha um cuidado e toque no bichinho. Os cuidados são gratuitos!")
	_build_actions()


func _build_actions() -> void:
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	match _mode:
		"food":
			_actions.add_child(_label("Escolha a comida; depois toque no bichinho para dar na boca.", 22))
			var row := UiKit.hbox(8)
			_actions.add_child(row)
			for food in ["meal", "fruit"]:
				row.add_child(_button(PetCare.FOODS[food]["name"], _choose_food.bind(food), Palette.GOLD))
			_actions.add_child(_button("Petisco", _give_treat, Color("ffb3c7")))
		"bath":
			_actions.add_child(_label("Passe o sabão com toques ou esfregue o bichinho. Depois enxágue!", 22))
			var row := UiKit.hbox(8)
			_actions.add_child(row)
			row.add_child(_button("Sabão", func(): _tool = "soap"; _status.text = tr("Esfregue ou toque no bichinho até fazer bastante espuma.")))
			row.add_child(_button("Enxaguar", _rinse_pet, Color("9dd9f3")))
		"sleep":
			_actions.add_child(_label("A energia volta durante a soneca na Casinha. Fora do jogo, as necessidades ficam pausadas.", 22))
			_actions.add_child(_button("Acordar" if PetCare.state(_selected)["sleeping"] else "Apagar a luz e dormir", _sleep))
		"play":
			_actions.add_child(_label("Toque na bola na sala para brincar. Cada toque é uma nova rodada!", 22))
			_actions.add_child(_button("Jogar bola", _play_ball, Palette.GOLD))
			_actions.add_child(_button("Fazer carinho", func(): _care("pet"), Color("ffb3c7")))
		"clothes":
			_actions.add_child(_label(tr("Saldo: %d moedas") % Game.coins(), 22))
			_actions.add_child(_label("Experimente antes de comprar. Os cuidados não custam moedas.", 22))
			_actions.add_child(_button("Sem acessório", _wear.bind("")))
			for item in Game.ITEMS:
				var row := UiKit.hbox(6)
				_actions.add_child(row)
				var cfg: Dictionary = Game.ITEMS[item]
				row.add_child(_button(cfg["name"], _try_on.bind(item)))
				if Game.owns(item):
					row.add_child(_button("Vestir", _wear.bind(item), Palette.UI_GOOD))
				else:
					var buy := _button("%d moedas" % cfg["price"], _buy_clothing.bind(item), Palette.GOLD)
					buy.disabled = Game.coins() < int(cfg["price"])
					row.add_child(buy)


func _refresh() -> void:
	var needs := PetCare.state(_selected)
	for key in _bars:
		var entry: Array = _bars[key]
		(entry[0] as Label).text = "%s · %d/100" % [tr(entry[2]), int(needs[key])]
		(entry[1] as ProgressBar).value = needs[key]
	_summary.text = tr("Dormindo tranquilamente") if needs["sleeping"] else tr("Toque para fazer carinho ou usar o cuidado escolhido.")
	_room.modulate = Color("8b91b4") if needs["sleeping"] else Color.WHITE


func _choose_food(food: String) -> void:
	_tool = "food:" + food
	_status.text = tr("Toque no bichinho para oferecer a comida.")


func _care(action: String, food: String = "meal") -> bool:
	var before := Game.data.duplicate(true)
	var result := PetCare.act(_selected, action, food)
	_status.text = tr(result["message"])
	if not result["ok"]:
		return false
	if action == "pet":
		Game.add_stat("pets", 1)
	if not Game.save():
		Game.data = before
		_status.text = tr("Não foi possível salvar o cuidado. Tente novamente.")
		_refresh()
		return false
	if action == "feed":
		_food_flash = food
		_food_timer = 1.0
	for pet in _pets:
		if pet.art.species == _selected:
			pet.happy = 1.8
			pet.hop = 1.0
			var heart := FloatingHeart.new()
			heart.position = pet.art.position + Vector2(0, -70)
			_hearts.add_child(heart)
	Sfx.play("pop", -2.0, 1.15)
	_refresh()
	return true


func _give_treat() -> void:
	_care("feed", "snack")


func _sleep() -> void:
	_care("sleep")
	_build_actions()


func _scrub(amount: float) -> void:
	if PetCare.state(_selected)["sleeping"]:
		_status.text = tr("Acorde o bichinho primeiro. Ele está descansando.")
		return
	_soap = minf(1.0, _soap + amount)
	_status.text = tr("Espuma: %d%% · depois toque em Enxaguar.") % int(_soap * 100)


func _rinse_pet() -> void:
	if _soap < 1.0:
		_status.text = tr("Use o sabão primeiro e faça bastante espuma.")
		return
	if _care("bath"):
		_soap = 0.0
		_tool = ""
		_rinse = 1.5
		_status.text = tr("Limpinho e cheiroso! Banho concluído.")
		Sfx.play("splash", -6.0)


func _play_ball() -> void:
	if not _care("play"):
		return
	_catches += 1
	_status.text = tr("Bola apanhada! Rodadas: %d") % _catches
	_ball.visible = true
	_ball.position = Vector2(size.x * (0.22 if _catches % 2 else 0.7), size.y * 0.42)
	for pet in _pets:
		if pet.art.species == _selected:
			pet.target = clampf(_ball.position.x, 90, size.x - 90)
			pet.wait = 1.5


func _try_on(item: String) -> void:
	_preview = item
	for pet in _pets:
		if pet.art.species == _selected:
			pet.art.accessory = item
	_status.text = tr("Prévia: %s · não foi cobrada nenhuma moeda.") % tr(Game.ITEMS[item]["name"])


func _wear(item: String) -> void:
	if item != "" and not Game.owns(item):
		return
	if item != Game.equipped(_selected) and not Game.equip(_selected, item):
		_status.text = tr("Não foi possível salvar o cuidado. Tente novamente.")
		return
	_preview = ""
	for pet in _pets:
		if pet.art.species == _selected:
			pet.art.accessory = Game.equipped(_selected)
	_status.text = tr("Visual atualizado!")


func _buy_clothing(item: String) -> void:
	if not Game.ITEMS.has(item) or Game.owns(item):
		return
	if not Game.buy_item(item):
		_status.text = tr("Não foi possível comprar a roupa. Confira suas moedas e tente novamente.")
		return
	_wear(item)
	_build_actions()


func _floor_y(depth: float) -> float:
	return size.y * FLOOR_Y + depth * 100.0


func _process(delta: float) -> void:
	if _selected.is_empty() or is_queued_for_deletion() or not PetCare.roster().has(_selected):
		return
	_tick += delta
	_autosave += delta
	_rinse = maxf(0.0, _rinse - delta)
	_food_timer = maxf(0.0, _food_timer - delta)
	if _tick >= 1.0:
		PetCare.tick(_tick)
		_tick = 0.0
		_dirty = true
		_refresh()
	if _autosave >= 15.0:
		_autosave = 0.0
		_flush()
	var reduce: bool = Game.setting("reduce_motion")
	for pet in _pets:
		var needs := PetCare.state(pet.art.species)
		if needs.is_empty():
			continue
		var sleeping: bool = needs["sleeping"]
		pet.happy = maxf(pet.happy - delta, 0.0)
		pet.hop = maxf(pet.hop - delta * 3.0, 0.0)
		var distance := pet.target - pet.x
		if not sleeping and absf(distance) > 4.0:
			pet.x += signf(distance) * minf(absf(distance), 70 * delta)
			pet.art.facing = signf(distance)
		elif not sleeping:
			pet.wait -= delta
			if pet.wait <= 0.0:
				pet.target = clampf(pet.x + randf_range(-150, 150), 90, size.x - 90)
				pet.wait = randf_range(2.0, 4.0)
		var selected := pet.art.species == _selected
		var scale_factor := 1.35 if selected else 0.75 + pet.depth * 0.15
		pet.art.scale = Vector2.ONE * scale_factor
		var bob := 0.0 if reduce or sleeping else -sin(pet.hop * PI) * 25.0
		var half := (32.0 if Store.PETS.has(pet.art.species) else Animal.half_height(pet.art.species)) * scale_factor
		pet.art.position = Vector2(pet.x, _floor_y(pet.depth) - half + bob)
		pet.art.z_index = 12 if selected else int(pet.depth * 10)
		pet.art.mood = "sleeping" if sleeping else ("happy" if pet.happy > 0.0 else "idle")
	_effects.queue_redraw()


func _pet_at(point: Vector2) -> Pet:
	var best: Pet
	var distance := 95.0
	for pet in _pets:
		var d := pet.art.position.distance_to(point)
		if d < distance:
			distance = d
			best = pet
	return best


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _tool == "soap" and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var pet := _pet_at(event.position)
		if pet != null and pet.art.species == _selected:
			_scrub(minf(0.12, event.relative.length() / 300.0))
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var pet := _pet_at(click.position)
	if pet == null:
		return
	if pet.art.species != _selected:
		_select(pet.art.species)
	if _tool.begins_with("food:"):
		if _care("feed", _tool.trim_prefix("food:")):
			_tool = ""
	elif _tool == "soap":
		_scrub(0.25)
	else:
		_care("pet")


class CareEffects:
	extends Node2D
	var home: HomeScreen

	func _draw() -> void:
		for pet in home._pets:
			var needs := PetCare.state(pet.art.species)
			if needs.is_empty():
				continue
			var point := pet.art.position
			if needs["sleeping"]:
				draw_string(UiKit.font(), point + Vector2(-20, -60), "Z z z", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("7977ae"))
			if float(needs["clean"]) < 60:
				for i in 4:
					DrawUtil.oval(self, point + Vector2((i % 2) * 26 - 14, (i / 2) * 14), Vector2(5, 3), Color("946e4e"), Color.TRANSPARENT, 0)
			if pet.art.species != home._selected:
				continue
			draw_arc(point + Vector2(0, 40), 50, 0, PI, 24, Color("f8cf69"), 4, true)
			var food := home._tool.trim_prefix("food:") if home._tool.begins_with("food:") else home._food_flash
			if home._tool.begins_with("food:") or home._food_timer > 0:
				var center := point + Vector2(0, -75)
				if food == "fruit":
					DrawUtil.disc(self, center, 16, Color("f78677"), Palette.OUTLINE, 2)
					DrawUtil.oval(self, center + Vector2(6, -18), Vector2(10, 4), Color("76bf76"), Palette.OUTLINE, 2, -0.4)
				else:
					DrawUtil.oval(self, center, Vector2(25, 12), Color("f4c569"), Palette.OUTLINE, 2)
					for i in 4:
						DrawUtil.disc(self, center + Vector2(-15 + i * 10, -4), 5, Color("a77450"), Palette.OUTLINE, 1)
			for i in int(home._soap * 18):
				var p := point + Vector2(sin(i * 2.4) * 40, cos(i * 1.7) * 28 - 10)
				DrawUtil.disc(self, p, 7 + (i % 3) * 2, Color(0.9, 0.98, 1, 0.85), Color("8ccfe9"), 1)
			if home._rinse > 0:
				for i in 12:
					var phase := 30.0 if bool(Game.setting("reduce_motion")) else fmod(home._rinse * 110 + i * 11, 110)
					var p := point + Vector2(i * 8 - 44, -80 + phase)
					draw_line(p, p + Vector2(-3, 13), Color("70c8ef"), 3, true)


class FloatingHeart:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if not bool(Game.setting("reduce_motion")):
			position.y -= 60.0 * delta
		modulate.a = clampf(1.2 - _t, 0.0, 1.0)
		if _t > 1.2:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 32:
			var t := TAU * i / 32.0
			pts.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * 1.3)
		DrawUtil.shape(self, pts, Color("ff6b8a"), Palette.OUTLINE, 3.0)


## A sala: parede listrada, janela com o céu do último mundo, tapete, sofá e fotos na parede.
class Room:
	extends Control
	var _photos: Array[Texture2D] = []
	var _t := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var album: Array = Game.data["album"]
		for i in range(maxi(album.size() - 3, 0), album.size()):
			var img := Image.load_from_file(str(album[i].get("file", "")))
			if img != null and not img.is_empty():
				_photos.append(ImageTexture.create_from_image(img))

	func _process(delta: float) -> void:
		if not bool(Game.setting("reduce_motion")):
			_t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var o := Palette.OUTLINE
		var floor_y := h * HomeScreen.FLOOR_Y - 40.0
		# parede
		draw_rect(Rect2(0, 0, w, floor_y), Color("ffe9c9"), true)
		for i in int(w / 60.0) + 1:
			draw_rect(Rect2(i * 60.0, 0, 30.0, floor_y), Color("fff3dd"), true)
		draw_rect(Rect2(0, floor_y - 26, w, 26), Color("d79a5b"), true)
		draw_line(Vector2(0, floor_y - 26), Vector2(w, floor_y - 26), o, 4.0, true)
		# chão de madeira
		draw_rect(Rect2(0, floor_y, w, h - floor_y), Color("c98a57"), true)
		for i in 8:
			var y := floor_y + 30.0 + i * 46.0
			draw_line(Vector2(0, y), Vector2(w, y), Color("a86c3a"), 3.0, true)
		DrawUtil.oval(self, Vector2(w * 0.5, floor_y + 150.0), Vector2(w * 0.44, 96.0), Color("ff9ec7"), o, 4.0)
		DrawUtil.oval(self, Vector2(w * 0.5, floor_y + 150.0), Vector2(w * 0.33, 66.0), Color("ffc2dc"), o, 0.0)
		# janela com céu do mundo mais avançado
		var wid := 1
		for i in LevelDB.count():
			if Game.is_unlocked(i):
				wid = int(LevelDB.get_level(i)["world"])
		var pal := Palette.world(wid)
		var win := Rect2(w * 0.08, h * 0.2, w * 0.34, h * 0.2)
		DrawUtil.vgradient(self, win, pal["sky_top"], pal["sky_bottom"])
		DrawUtil.cloud(self, win.position + Vector2(win.size.x * (0.3 + 0.1 * sin(_t * 0.3)), win.size.y * 0.35), 18.0, Color(1, 1, 1, 0.9))
		draw_rect(Rect2(win.position.x, win.end.y - win.size.y * 0.25, win.size.x, win.size.y * 0.25), pal["near"], true)
		draw_rect(win, o, false, 6.0)
		draw_line(Vector2(win.get_center().x, win.position.y), Vector2(win.get_center().x, win.end.y), o, 5.0, true)
		draw_line(Vector2(win.position.x, win.get_center().y), Vector2(win.end.x, win.get_center().y), o, 5.0, true)
		# fotos do álbum na parede (molduras)
		for i in 3:
			var fr := Rect2(w * (0.5 + i * 0.16), h * (0.2 + (i % 2) * 0.05), w * 0.13, w * 0.17)
			draw_rect(fr.grow(6), Color("fffaf2"), true)
			draw_rect(fr.grow(6), o, false, 4.0)
			if i < _photos.size():
				draw_texture_rect(_photos[_photos.size() - 1 - i], fr, false)
			else:
				draw_rect(fr, Color("e8dccb"), true)
				DrawUtil.disc(self, fr.get_center(), fr.size.x * 0.18, Color("f4c77a"), o, 2.0)
		# sofá
		var sofa := Rect2(w * 0.55, floor_y - 120.0, w * 0.4, 100.0)
		DrawUtil.shape(self, PackedVector2Array([sofa.position, Vector2(sofa.end.x, sofa.position.y), sofa.end, Vector2(sofa.position.x, sofa.end.y)]), Color("6fb0e8"), o, 4.0)
		draw_rect(Rect2(sofa.position.x - 14, sofa.position.y + 30, 28, 72), Color("4f8fc8"), true)
		draw_rect(Rect2(sofa.end.x - 14, sofa.position.y + 30, 28, 72), Color("4f8fc8"), true)
		# vaso de planta
		DrawUtil.shape(self, PackedVector2Array([Vector2(w * 0.47, floor_y - 2), Vector2(w * 0.51, floor_y - 2), Vector2(w * 0.505, floor_y - 40), Vector2(w * 0.475, floor_y - 40)]), Color("e07a5f"), o, 3.0)
		for k in 3:
			DrawUtil.oval(self, Vector2(w * 0.49 + (k - 1) * 12.0, floor_y - 58.0), Vector2(8, 20), Palette.GRASS, o, 2.5, (k - 1) * 0.5)
