class_name HomeScreen
extends Control
## Casinha ilustrada: tocar/arrastar objetos reais da sala, com cuidados individuais.
signal go(screen: String, arg: Variant)

class Pet:
	extends RefCounted
	var art: AnimalArt
	var x := 0.0
	var target := 0.0
	var wait := 1.0
	var happy := 0.0
	var hop := 0.0
	var depth := 0.0

var _pets: Array[Pet] = []
var _selected := ""
var _mode := "play"
var _tool := ""
var _soap := 0.0
var _wet := false
var _rinse := 0.0
var _food_flash := ""
var _food_timer := 0.0
var _food_origin := Vector2.ZERO
var _tick := 0.0
var _autosave := 0.0
var _dirty := false
var _catches := 0
var _preview := ""
var _play_timer := 0.0
var _toast_timer := 0.0
var _stage := Rect2()
var _safe := Rect2()
var _objects: Dictionary = {}
var _dock: Dictionary = {}
var _needs: Dictionary = {}
var _chips: Dictionary = {}
var _room: HomeRoom
var _ball: HomeBall
var _effects: Effects
var _hearts: Node2D
var _ui: Control
var _name_label: Label
var _status: Label
var _back: HomeObject
var _album: HomeObject
var _roster_scroll: ScrollContainer
var _roster_row: HBoxContainer
var _wardrobe_scroll: ScrollContainer
var _ghost: HomeObject
var _buy: HomeObject
var _wallet: HomeObject
var _built := false
var _night := false
var _pointer := Vector2.ZERO
var _pointer_down := false
var _drag_kind := ""
var _drag_start := Vector2.ZERO
var _drag_origin := Vector2.ZERO
var _drag_moved := false
var _drag_ball := false
var _drag_velocity := Vector2.ZERO
var _last_pointer_time := 0.0
var _skip_click := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_room = HomeRoom.new()
	_room.home = self
	add_child(_room)
	for species in PetCare.roster():
		var pet := Pet.new()
		pet.art = AnimalArt.new()
		pet.art.species = species
		pet.art.preview = true
		pet.art.accessory = Game.equipped(species)
		pet.art.visible = false
		pet.art.set_process(false)
		add_child(pet.art)
		_pets.append(pet)
		PetCare.state(species)
	_selected = _pets[0].art.species
	_hearts = Node2D.new()
	_hearts.z_index = 18
	add_child(_hearts)
	_ball = HomeBall.new()
	_ball.z_index = 14
	add_child(_ball)
	_effects = Effects.new()
	_effects.home = self
	_effects.z_index = 16
	add_child(_effects)
	_build_ui()
	_built = true
	resized.connect(_layout)
	_layout()
	_ball.place(_clamp_ball(Vector2(_stage.get_center().x + 140, _hero_floor() - 40)))
	_select(_selected)
	Sfx.music("music_menu")


func _exit_tree() -> void:
	_flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_cancel_drag()
		_flush()


func _flush() -> void:
	if _dirty and Game.save():
		_dirty = false


func _object(key: String, kind: String, label: String, parent: Node = null) -> HomeObject:
	var object := HomeObject.new()
	object.key = key
	object.kind = kind
	object.tooltip_text = tr(label)
	object.pressed.connect(_activate_object.bind(key))
	(parent if parent != null else _ui).add_child(object)
	return object


func _build_ui() -> void:
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.z_index = 20
	add_child(_ui)
	_back = _object("back", "back", "Voltar")
	_album = _object("album", "album", "Álbum")
	_name_label = UiKit.label("", 34, HomeArt.INK)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.clip_text = true
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_ui.add_child(_name_label)
	for spec in [["food", "Barriguinha", Color("dcb997")], ["clean", "Higiene", Color("9bc8bf")], ["energy", "Energia", Color("c6b4d6")], ["love", "Carinho", Color("dfafc0")]]:
		var need := HomeNeed.new()
		need.kind = spec[0]
		need.tint = spec[2]
		need.mouse_filter = Control.MOUSE_FILTER_STOP
		need.set_meta("need_name", spec[1])
		_ui.add_child(need)
		_needs[spec[0]] = need
	for spec in [["play", "Sala"], ["food", "Comida"], ["bath", "Banho"], ["sleep", "Soneca"], ["clothes", "Roupas"]]:
		var object := _object("room:" + spec[0], spec[0], spec[1])
		object.dock = true
		_dock[spec[0]] = object
	_roster_scroll = ScrollContainer.new()
	_roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_roster_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_ui.add_child(_roster_scroll)
	_roster_row = UiKit.hbox(10)
	_roster_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_roster_scroll.add_child(_roster_row)
	for pet in _pets:
		var chip := _object("pet:" + pet.art.species, "", PetCare.pet_name(pet.art.species), _roster_row)
		chip.dock = true
		chip.custom_minimum_size = Vector2(88, 82)
		chip.focus_entered.connect(func(): _roster_scroll.ensure_control_visible(chip))
		var art := AnimalArt.new()
		art.species = pet.art.species
		art.preview = true
		art.position = Vector2(44, 46)
		art.scale = Vector2.ONE * (0.55 if pet.art.species == "capi" or pet.art.species == "fofa" else 0.74)
		chip.add_child(art)
		art.set_process(false)
		_chips[pet.art.species] = chip
	_status = UiKit.label("", 22, HomeArt.INK, 0, Color.WHITE, true)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.visible = false
	_ui.add_child(_status)
	_ghost = HomeObject.new()
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.focus_mode = Control.FOCUS_NONE
	_ghost.z_index = 40
	_ghost.visible = false
	_ui.add_child(_ghost)


func _layout() -> void:
	if not _built or size.x <= 0 or size.y <= 0:
		return
	_safe = Rect2(18, 16, size.x - 36, size.y - 32)
	if OS.has_feature("Android"):
		var area := DisplayServer.get_display_safe_area()
		var window_size := Vector2(get_window().size)
		if area.size.x > 0 and area.size.y > 0 and window_size.x > 0 and window_size.y > 0:
			var factor := size / window_size
			var inset := Rect2(Vector2(area.position) * factor, Vector2(area.size) * factor)
			_safe = _safe.intersection(inset.grow(-10))
	var compact := size.y < 900
	var header_h := 136.0 if compact else 176.0
	var dock_h := 74.0 if compact else 88.0
	var roster_h := 72.0 if compact else 88.0
	var width := minf(_safe.size.x, 960)
	var left := _safe.get_center().x - width / 2
	var dock_y := _safe.end.y - dock_h
	var roster_y := dock_y - roster_h - 10
	_stage = Rect2(left, _safe.position.y + header_h, width, maxf(160, roster_y - _safe.position.y - header_h - 18))
	_back.position = Vector2(_safe.position.x, _safe.position.y)
	_back.size = Vector2(72, 64)
	_album.position = Vector2(_safe.end.x - 72, _safe.position.y)
	_album.size = Vector2(72, 64)
	_name_label.position = Vector2(_safe.position.x + 82, _safe.position.y + 8)
	_name_label.size = Vector2(_safe.size.x - 164, 48)
	var need_size := 60.0 if compact else 72.0
	var need_gap := 15.0 if compact else 22.0
	var row_width := need_size * 4 + need_gap * 3
	for i in PetCare.NEEDS.size():
		var key: String = PetCare.NEEDS[i]
		_needs[key].position = Vector2(_safe.get_center().x - row_width / 2 + i * (need_size + need_gap), _safe.position.y + 70)
		_needs[key].size = Vector2.ONE * need_size
	var dock_size := minf((width - 24) / 5.0, dock_h)
	var gap := clampf((width - dock_size * 5) / 6, 6, 28)
	var dock_width := dock_size * 5 + gap * 4
	var i := 0
	for object in _dock.values():
		object.position = Vector2(_safe.get_center().x - dock_width / 2 + i * (dock_size + gap), dock_y)
		object.size = Vector2.ONE * dock_size
		i += 1
	_roster_scroll.position = Vector2(left + 8, roster_y)
	_roster_scroll.size = Vector2(width - 16, roster_h)
	_roster_row.add_theme_constant_override("separation", 10)
	for chip in _chips.values():
		chip.custom_minimum_size = Vector2(88, roster_h - 4)
	_roster_row.custom_minimum_size = Vector2(maxf(0, _pets.size() * 98 - 10), roster_h - 4)
	_status.position = Vector2(_safe.get_center().x - minf(width - 32, 430) / 2, _stage.position.y + 2)
	_status.size = Vector2(minf(width - 32, 430), 64)
	_ball.configure(Rect2(_stage.position + Vector2(16, 10), Vector2(_stage.size.x - 32, minf(_hero_floor() + 88, _stage.end.y - 16) - _stage.position.y - 10)))
	_place_objects()
	_room.queue_redraw()


func _hero_floor() -> float:
	return _stage.position.y + _stage.size.y * 0.63


func _hero() -> Pet:
	for pet in _pets:
		if pet.art.species == _selected:
			return pet
	return null


func _select(species: String) -> void:
	if not PetCare.roster().has(species):
		return
	_cancel_drag()
	_selected = species
	_soap = 0.0
	_wet = false
	_tool = ""
	_preview = ""
	for pet in _pets:
		pet.art.accessory = Game.equipped(pet.art.species)
		pet.art.visible = pet.art.species == species
		pet.art.set_process(pet.art.visible)
		pet.x = 0
		pet.target = 0
		pet.depth = 0
	_name_label.text = PetCare.pet_name(species)
	for key in _chips:
		_chips[key].selected = key == species
		_chips[key].queue_redraw()
	_refresh()
	_build_actions()


func _set_mode(mode: String) -> void:
	if not _dock.has(mode):
		return
	_cancel_drag()
	_mode = mode
	_tool = ""
	_preview = ""
	_play_timer = 0
	_toast_timer = 0
	_status.visible = false
	for pet in _pets:
		pet.art.accessory = Game.equipped(pet.art.species)
		pet.target = 0
		pet.x = 0
	for key in _dock:
		_dock[key].selected = key == mode
		_dock[key].queue_redraw()
	_ball.visible = mode == "play"
	_ball.freeze = mode != "play"
	if mode == "play":
		_ball.place(_clamp_ball(Vector2(_stage.get_center().x + 140, _hero_floor() - 20)))
	_build_actions()
	_room.queue_redraw()


func _build_actions() -> void:
	for object in _objects.values():
		object.queue_free()
	_objects.clear()
	if _wardrobe_scroll != null:
		_wardrobe_scroll.queue_free()
		_wardrobe_scroll = null
	if _buy != null:
		_buy.queue_free()
	if _wallet != null:
		_wallet.queue_free()
		_wallet = null
	_buy = null
	match _mode:
		"food":
			for food in ["meal", "fruit", "snack"]:
				var object := _object(food, food, PetCare.FOODS[food]["name"])
				object.button_down.connect(_begin_drag.bind(food))
				_objects[food] = object
		"bath":
			var soap := _object("soap", "soap", "Sabão")
			soap.button_down.connect(_begin_drag.bind("soap"))
			_objects["soap"] = soap
			_objects["shower"] = _object("shower", "shower", "Enxaguar")
			_objects["towel"] = _object("towel", "towel", "Secar")
		"sleep":
			_objects["bed"] = _object("bed", "", "Dormir ou acordar")
			_objects["lamp"] = _object("lamp", "lamp", "Apagar a luz e dormir")
		"clothes":
			_wardrobe_scroll = ScrollContainer.new()
			_wardrobe_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
			_wardrobe_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			_ui.add_child(_wardrobe_scroll)
			var rail := UiKit.hbox(10)
			rail.alignment = BoxContainer.ALIGNMENT_BEGIN
			_wardrobe_scroll.add_child(rail)
			var empty := _object("wear:none", "none", "Sem acessório", rail)
			empty.custom_minimum_size = Vector2(96, 94)
			for item in Game.ITEMS:
				var hanger := _object("wear:" + item, "accessory", Game.ITEMS[item]["name"], rail)
				hanger.item = item
				hanger.locked = not Game.owns(item)
				hanger.selected = Game.equipped(_selected) == item
				hanger.custom_minimum_size = Vector2(96, 94)
				hanger.focus_entered.connect(func(): _wardrobe_scroll.ensure_control_visible(hanger))
			_buy = _object("buy", "buy", "Comprar acessório")
			_buy.visible = false
			_wallet = HomeObject.new()
			_wallet.kind = "wallet"
			_wallet.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_wallet.cost = Game.coins()
			_ui.add_child(_wallet)
	_place_objects()
	_ball.visible = _mode == "play"
	_ball.freeze = _mode != "play"
	for key in _dock:
		_dock[key].selected = key == _mode
		_dock[key].queue_redraw()
	_refresh()


func _place_objects() -> void:
	var object_size := minf(96.0 if size.y >= 900 else 84.0, (_stage.size.x - 32) / 3.0 - 16)
	var tray_y := _stage.end.y - object_size - 6
	match _mode:
		"food":
			for i in 3:
				var object: HomeObject = _objects[["meal", "fruit", "snack"][i]]
				object.position = Vector2(_stage.get_center().x + (i - 1) * (object_size + 28) - object_size / 2, tray_y)
				object.size = Vector2.ONE * object_size
		"bath":
			_objects["soap"].position = Vector2(_stage.get_center().x - object_size - 40, tray_y)
			_objects["soap"].size = Vector2.ONE * object_size
			_objects["towel"].position = Vector2(_stage.get_center().x + 40, tray_y)
			_objects["towel"].size = Vector2.ONE * object_size
			_objects["shower"].position = Vector2(_stage.get_center().x + minf(180, _stage.size.x * 0.27) - 50, maxf(_stage.position.y + 12, _hero_floor() - minf(220, _stage.size.y * 0.5)))
			_objects["shower"].size = Vector2(100, 148)
		"sleep":
			var width := minf(_stage.size.x * 0.62, 430)
			_objects["bed"].position = Vector2(_stage.get_center().x - width / 2, _hero_floor() - 58)
			_objects["bed"].size = Vector2(width, 125)
			_objects["lamp"].position = Vector2(_stage.get_center().x + minf(210, _stage.size.x * 0.3) - 45, maxf(_stage.position.y + 12, _hero_floor() - 130))
			_objects["lamp"].size = Vector2(90, 110)
		"clothes":
			if _wardrobe_scroll != null:
				_wardrobe_scroll.position = Vector2(_stage.position.x + 8, _stage.end.y - 108)
				_wardrobe_scroll.size = Vector2(_stage.size.x - 16, 104)
			if _buy != null:
				_buy.position = Vector2(_stage.end.x - 154, _stage.position.y + 12)
				_buy.size = Vector2(140, 66)
			if _wallet != null:
				_wallet.position = _stage.position + Vector2(10, 20)
				_wallet.size = Vector2(140, 44)


func _activate_object(key: String) -> void:
	if _skip_click == key:
		_skip_click = ""
		return
	if key.begins_with("room:"):
		_set_mode(key.trim_prefix("room:"))
	elif key.begins_with("pet:"):
		_select(key.trim_prefix("pet:"))
	elif key.begins_with("wear:"):
		var item := key.trim_prefix("wear:")
		if item == "none":
			_wear("")
		elif Game.owns(item):
			_wear(item)
		else:
			_try_on(item)
	elif PetCare.FOODS.has(key):
		_food_origin = _objects[key].get_global_rect().get_center()
		_care("feed", key)
	else:
		match key:
			"back": go.emit("title", null)
			"album": go.emit("album", null)
			"soap": _tool = "soap"
			"shower": _rinse_pet()
			"towel":
				if _wet:
					_wet = false
					_rinse = 0
					_celebrate()
			"bed", "lamp": _sleep()
			"buy": _buy_clothing(_preview)


func _refresh() -> void:
	var needs := PetCare.state(_selected)
	if needs.is_empty():
		return
	for key in _needs:
		var ring: HomeNeed = _needs[key]
		ring.value = float(needs[key])
		ring.tooltip_text = "%s · %d%%" % [tr(ring.get_meta("need_name")), int(needs[key])]
	if _objects.has("soap"):
		_objects["soap"].progress = _soap
		_objects["soap"].queue_redraw()
	if _objects.has("shower"):
		_objects["shower"].selected = _soap >= 1
		_objects["shower"].queue_redraw()
	if _objects.has("towel"):
		_objects["towel"].selected = _wet
		_objects["towel"].queue_redraw()
	if _objects.has("lamp"):
		_objects["lamp"].selected = not bool(needs["sleeping"])
		_objects["lamp"].queue_redraw()
	_room.queue_redraw()


func _toast(message: String) -> void:
	var short: Dictionary = {
		"Barriguinha cheia! Que tal outro cuidado?": "Barriguinha cheia",
		"Acorde o bichinho primeiro. Ele está descansando.": "Acorde primeiro",
		"Uma soneca primeiro vai fazer bem!": "Hora de descansar",
		"Use o sabão primeiro e faça bastante espuma.": "Mais espuma!",
		"Não foi possível salvar o cuidado. Tente novamente.": "Não foi possível salvar",
	}
	_status.text = tr(short.get(message, message))
	_status.visible = true
	_toast_timer = 2.0


func _care(action: String, food: String = "meal") -> bool:
	var before := Game.data.duplicate(true)
	var result := PetCare.act(_selected, action, food)
	if not result["ok"]:
		_toast(result["message"])
		return false
	if action == "pet":
		Game.add_stat("pets", 1)
	if not Game.save():
		Game.data = before
		_toast("Não foi possível salvar o cuidado. Tente novamente.")
		_refresh()
		return false
	if action == "feed":
		_food_flash = food
		_food_timer = 0.7
	_celebrate()
	_refresh()
	return true


func _celebrate() -> void:
	var pet := _hero()
	if pet == null:
		return
	pet.happy = 1.8
	pet.hop = 1.0
	var heart := FloatingHeart.new()
	heart.position = pet.art.position + Vector2(0, -90)
	_hearts.add_child(heart)
	Sfx.play("pop", -5, 1.15)


func _give_treat() -> void:
	_food_origin = Vector2(_stage.get_center().x, _stage.end.y - 50)
	_care("feed", "snack")


func _choose_food(food: String) -> void:
	_tool = "food:" + food


func _sleep() -> void:
	_care("sleep")
	_refresh()


func _scrub(amount: float) -> void:
	if bool(PetCare.state(_selected)["sleeping"]):
		_toast("Acorde o bichinho primeiro. Ele está descansando.")
		return
	_soap = minf(1, _soap + amount)
	_refresh()


func _rinse_pet() -> void:
	if _soap < 1:
		_toast("Use o sabão primeiro e faça bastante espuma.")
		return
	if _care("bath"):
		_soap = 0
		_tool = ""
		_wet = true
		_rinse = 1.4
		_refresh()
		Sfx.play("splash", -8)


func _play_ball() -> bool:
	if not _care("play"):
		return false
	_catches += 1
	_play_timer = 3
	return true


func _try_on(item: String) -> void:
	if not Game.ITEMS.has(item):
		return
	_preview = item
	_hero().art.accessory = item
	if _buy != null:
		_buy.visible = true
		_buy.cost = int(Game.ITEMS[item]["price"])
		_buy.disabled = Game.coins() < _buy.cost
		_buy.tooltip_text = tr("Comprar por %d moedas") % _buy.cost
		_buy.queue_redraw()
	_highlight_clothing(item)


func _wear(item: String) -> void:
	if item != "" and not Game.owns(item):
		return
	if item != Game.equipped(_selected) and not Game.equip(_selected, item):
		_toast("Não foi possível salvar o cuidado. Tente novamente.")
		return
	_preview = ""
	_hero().art.accessory = Game.equipped(_selected)
	if _buy != null:
		_buy.visible = false
	_highlight_clothing(item)
	_celebrate()


func _highlight_clothing(item: String) -> void:
	if _wardrobe_scroll == null:
		return
	for object in _wardrobe_scroll.get_child(0).get_children():
		if object is HomeObject:
			object.selected = object.item == item
			object.queue_redraw()


func _buy_clothing(item: String) -> void:
	if not Game.ITEMS.has(item) or Game.owns(item):
		return
	if not Game.buy_item(item):
		_toast("Não foi possível salvar o cuidado. Tente novamente.")
		return
	_wear(item)
	if _wardrobe_scroll != null:
		for object in _wardrobe_scroll.get_child(0).get_children():
			if object is HomeObject and object.item == item:
				object.locked = false
				object.queue_redraw()
	if _wallet != null:
		_wallet.cost = Game.coins()
		_wallet.queue_redraw()


func _begin_drag(key: String) -> void:
	if not _pointer_down:
		return
	_drag_kind = key
	_drag_start = _pointer
	_drag_origin = _pointer
	_drag_moved = false
	_ghost.kind = key
	_ghost.size = Vector2(90, 90)
	_ghost.position = _pointer - _ghost.size / 2
	_ghost.visible = true


func _cancel_drag() -> void:
	_drag_kind = ""
	_drag_moved = false
	if _ghost != null:
		_ghost.visible = false
	if _drag_ball and is_instance_valid(_ball):
		_ball.freeze = _mode != "play"
	_drag_ball = false


func _input(event: InputEvent) -> void:
	if not _built or is_queued_for_deletion():
		return
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	var local := make_input_local(event)
	_pointer = local.position
	if local is InputEventMouseMotion:
		var now := Time.get_ticks_usec() / 1000000.0
		_drag_velocity = (_pointer - _drag_start) / maxf(0.016, now - _last_pointer_time)
		_last_pointer_time = now
		_drag_start = _pointer
		if not _drag_kind.is_empty():
			_drag_moved = _drag_moved or _pointer.distance_to(_drag_origin) > 6
			_ghost.position = _pointer - _ghost.size / 2
			if _drag_kind == "soap" and _pet_at(_pointer) != null:
				_scrub(minf(0.14, local.relative.length() / 240))
			get_viewport().set_input_as_handled()
		if _drag_ball:
			_drag_moved = _drag_moved or _pointer.distance_to(_drag_origin) > 6
			_ball.place(_clamp_ball(_pointer))
			get_viewport().set_input_as_handled()
	elif local is InputEventMouseButton and local.button_index == MOUSE_BUTTON_LEFT:
		_pointer_down = local.pressed
		if local.pressed:
			return
		if _drag_ball:
			_ball.place(_clamp_ball(_pointer))
			var velocity := _drag_velocity if _drag_moved else Vector2(-160, -450)
			_ball.launch(velocity)
			_play_ball()
			_drag_ball = false
			get_viewport().set_input_as_handled()
		if not _drag_kind.is_empty():
			var kind := _drag_kind
			_skip_click = kind
			set_deferred("_skip_click", "")
			if PetCare.FOODS.has(kind) and (_pet_at(_pointer) != null or not _drag_moved):
				_food_origin = _pointer
				_care("feed", kind)
			elif kind == "soap":
				_tool = "soap"
			_cancel_drag()


func _clamp_ball(point: Vector2) -> Vector2:
	var bounds := _ball.bounds.grow(-HomeBall.RADIUS)
	return Vector2(clampf(point.x, bounds.position.x, bounds.end.x), clampf(point.y, bounds.position.y, bounds.end.y))


func _pet_at(point: Vector2) -> Pet:
	var pet := _hero()
	if pet == null:
		return null
	var half := Vector2(36, 40)
	if Animal.SPECIES.has(_selected):
		var config: Dictionary = Animal.SPECIES[_selected]
		half = Vector2(float(config["r"]), Animal.half_height(_selected))
		if config["shape"] == "hcapsule":
			half.x = float(config["h"]) / 2
	var radius := half * pet.art.scale + Vector2(28, 28)
	if absf(point.x - pet.art.position.x) < radius.x and absf(point.y - pet.art.position.y) < radius.y:
		return pet
	return null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _tool == "soap" and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if _pet_at(event.position) != null:
			_scrub(minf(0.14, event.relative.length() / 240))
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if _mode == "play" and _ball.position.distance_to(click.position) <= HomeBall.RADIUS + 16:
		_drag_ball = true
		_drag_moved = false
		_drag_velocity = Vector2.ZERO
		_drag_start = click.position
		_drag_origin = click.position
		_last_pointer_time = Time.get_ticks_usec() / 1000000.0
		_ball.freeze = true
		accept_event()
		return
	if _pet_at(click.position) == null:
		return
	if _tool.begins_with("food:"):
		_food_origin = click.position
		if _care("feed", _tool.trim_prefix("food:")):
			_tool = ""
	elif _tool == "soap":
		_scrub(0.25)
	else:
		_care("pet")


func _process(delta: float) -> void:
	if not _built or is_queued_for_deletion() or not PetCare.roster().has(_selected):
		return
	_tick += delta
	_autosave += delta
	_rinse = maxf(0, _rinse - delta)
	_food_timer = maxf(0, _food_timer - delta)
	_play_timer = maxf(0, _play_timer - delta)
	_toast_timer = maxf(0, _toast_timer - delta)
	_status.visible = _toast_timer > 0
	if _tick >= 1:
		PetCare.tick(_tick)
		_tick = 0
		_dirty = true
		_refresh()
	if _autosave >= 15:
		_autosave = 0
		_flush()
	var pet := _hero()
	var needs := PetCare.state(_selected)
	var sleeping: bool = needs["sleeping"]
	var night := _mode == "sleep" and sleeping
	if night != _night:
		_night = night
		_name_label.label_settings.font_color = Color("fff7ed") if night else HomeArt.INK
		_back.light = night
		_back.queue_redraw()
	pet.happy = maxf(0, pet.happy - delta)
	pet.hop = maxf(0, pet.hop - delta * 2.8)
	var moving := _mode == "play" or _mode == "food"
	if moving and not sleeping:
		if _play_timer > 0:
			pet.target = clampf(_ball.position.x - _stage.get_center().x, -_stage.size.x * 0.22, _stage.size.x * 0.22)
		elif pet.wait <= 0:
			pet.target = randf_range(-_stage.size.x * 0.10, _stage.size.x * 0.10)
			pet.wait = randf_range(2, 5)
		pet.wait -= delta
		var distance := pet.target - pet.x
		pet.x += signf(distance) * minf(absf(distance), delta * (125 if _play_timer > 0 else 35))
		if absf(distance) > 4:
			pet.art.facing = signf(distance)
	else:
		pet.x = move_toward(pet.x, 0, delta * 100)
		pet.art.facing = 1
	pet.depth = move_toward(pet.depth, 1.0 if _play_timer > 0 else 0.0, delta)
	var scale_factor := minf(clampf(_stage.size.y / 320, 1.25, 2.15), _stage.size.x / 170.0)
	pet.art.scale = Vector2.ONE * scale_factor
	var half := (32.0 if Store.PETS.has(_selected) else Animal.half_height(_selected)) * scale_factor
	var bob := 0.0 if bool(Game.setting("reduce_motion")) or sleeping else -sin(pet.hop * PI) * 17
	pet.art.position = Vector2(_stage.get_center().x + pet.x, _hero_floor() - half + bob + pet.depth * 55)
	pet.art.z_index = 10
	pet.art.mood = "sleeping" if sleeping else ("happy" if pet.happy > 0 else "idle")
	pet.art.rotation = -0.045 if sleeping else 0
	_effects.queue_redraw()


class FloatingHeart:
	extends Node2D
	var clock := 0.0
	func _process(delta: float) -> void:
		clock += delta
		if not bool(Game.setting("reduce_motion")):
			position.y -= delta * 35
		modulate.a = maxf(0, 1 - clock)
		if clock > 1:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		HomeArt.heart(self, Vector2.ZERO, 1, Color("e5a1b8"))


class Effects:
	extends Node2D
	var home: HomeScreen
	func _draw() -> void:
		var pet := home._hero()
		if pet == null or not pet.art.visible:
			return
		var point := pet.art.position
		var floor_y := home._hero_floor() + pet.depth * 55
		if home._mode == "play" and home._ball.visible:
			var height := maxf(0, home._ball.bounds.end.y - home._ball.position.y)
			HomeArt.shadow(self, Vector2(home._ball.position.x, home._ball.bounds.end.y + 4), 43 - minf(20, height * 0.06), 0.12 - minf(0.07, height * 0.0002))
		HomeArt.shadow(self, Vector2(point.x, floor_y + 4), pet.art.scale.x * 45, 0.07)
		var needs := PetCare.state(home._selected)
		if needs.get("sleeping", false):
			draw_string(UiKit.font(), point + Vector2(40, -70), "z z", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("a599b9"))
		if float(needs.get("clean", 100)) < 55:
			for i in 4:
				HomeArt.oval(self, point + Vector2((i % 2) * 27 - 14, (i / 2) * 13), Vector2(5, 3), Color("ac8a6b"))
		for i in int(home._soap * 24) if home._mode == "bath" else 0:
			var center := point + Vector2(sin(i * 2.4) * 65, cos(i * 1.7) * 42)
			DrawUtil.disc(self, center, 8 + i % 3 * 3, Color("f1fcfae0"), Color("bddfdc"), 1)
		if home._food_timer > 0:
			var anchor: Dictionary = AnimalArt.ANCHORS[home._selected]
			var mouth: Vector2 = point + (anchor["eyes"] + Vector2(0, 10)) * pet.art.scale * Vector2(pet.art.facing, 1)
			var progress := clampf((0.7 - home._food_timer) / 0.5, 0, 1)
			var center := home._food_origin.lerp(mouth, progress)
			var radius := 30.0 * minf(1, home._food_timer / 0.2)
			HomeArt.object(self, home._food_flash, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2))
		if home._mode == "bath":
			var width := minf(home._stage.size.x * 0.6, 430)
			HomeArt.box(self, Rect2(home._stage.get_center().x - width / 2, home._hero_floor() - 13, width, 63), Color("fffdf4"), 32)
			HomeArt.box(self, Rect2(home._stage.get_center().x - width / 2 + 22, home._hero_floor() - 6, width - 44, 12), Color("eff7ed"), 6)
		if home._mode == "sleep":
			var width := minf(home._stage.size.x * 0.62, 430)
			HomeArt.box(self, Rect2(home._stage.get_center().x - 30, home._hero_floor() - 9, width / 2 + 15, 64), Color("c4b6d8"), 20)
			for i in 3:
				HomeArt.star(self, Vector2(home._stage.get_center().x + i * 50, home._hero_floor() + 18), 7, Color("eee1ba"))
		if home._rinse > 0 and home._mode == "bath":
			for i in 14:
				var phase := 30.0 if bool(Game.setting("reduce_motion")) else fmod(home._rinse * 155 + i * 19, 170)
				var p := point + Vector2(i * 10 - 65, -130 + phase)
				draw_line(p, p + Vector2(-3, 13), Color("84c8db"), 3, true)
