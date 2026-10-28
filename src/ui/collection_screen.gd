class_name CollectionScreen
extends Control
## Coleção: amigos encontrados, guarda-roupa (cosméticos com moedas) e conquistas.

signal go(screen: String, arg: Variant)

var _tab := "friends"
var _content: VBoxContainer
var _coins: Label
var _selected := "capi"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBg.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	var col := UiKit.vbox(16)
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(col)
	var header := UiKit.hbox(12)
	col.add_child(header)
	var back := UiKit.icon_button("back")
	back.pressed.connect(func(): go.emit("title", null))
	header.add_child(back)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(sp)
	var ci := UiIcon.new()
	ci.icon = "coin"
	ci.custom_minimum_size = Vector2(46, 46)
	header.add_child(ci)
	_coins = UiKit.label("", 32, Palette.WHITE, 10, Palette.OUTLINE)
	header.add_child(_coins)
	var tabs := UiKit.hbox(10)
	col.add_child(tabs)
	for t in [["friends", "Amigos"], ["wardrobe", "Roupinhas"], ["trophies", "Conquistas"]]:
		var b := UiKit.button(t[1], Palette.UI_SECONDARY, "", 0, 80)
		b.add_theme_font_size_override("font_size", 26)
		var id: String = t[0]
		b.pressed.connect(func():
			_tab = id
			_refresh())
		tabs.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_content = UiKit.vbox(16)
	_content.alignment = BoxContainer.ALIGNMENT_BEGIN
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)
	if not Game.has_met(_selected) and not Game.data["met"].is_empty():
		_selected = str(Game.data["met"][0])
	_refresh()


func _refresh() -> void:
	_coins.text = str(Game.coins())
	for c in _content.get_children():
		c.queue_free()
	match _tab:
		"friends": _build_friends()
		"wardrobe": _build_wardrobe()
		"trophies": _build_trophies()


func _portrait(species: String, known: bool, accessory: String = "") -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(150, 140)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := AnimalArt.new()
	art.species = species
	art.preview = true
	art.accessory = accessory
	art.position = Vector2(75, 70 + 10)
	art.scale = Vector2(1.1, 1.1)
	if not known:
		art.modulate = Color(0.1, 0.05, 0.15, 0.85)
	holder.add_child(art)
	return holder


func _build_friends() -> void:
	for sp in Cast.ORDER:
		var known := Game.has_met(sp)
		var card := UiKit.panel(Palette.UI_PANEL if known else Color(1, 1, 1, 0.6))
		var row := UiKit.hbox(14)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		card.add_child(row)
		row.add_child(_portrait(sp, known, Game.equipped(sp)))
		var info := UiKit.vbox(6)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var cast: Dictionary = Cast.INFO[sp]
		var name_l := UiKit.label((Animal.SPECIES[sp]["name"] + " · " + cast["species"]) if known else "???", 30)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(name_l)
		var bio := UiKit.label(cast["bio"] if known else "Salve este bichinho numa fase para conhecê-lo!", 21, Palette.UI_TEXT, 0, Palette.WHITE, true)
		bio.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		bio.custom_minimum_size = Vector2(420, 0)
		info.add_child(bio)
		if known:
			var tr := UiKit.label(cast["trait"], 21, Palette.UI_PRIMARY.darkened(0.2), 0, Palette.WHITE, true)
			tr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			tr.custom_minimum_size = Vector2(420, 0)
			info.add_child(tr)
		_content.add_child(card)


func _build_wardrobe() -> void:
	if Game.data["met"].is_empty():
		_content.add_child(UiKit.label("Salve um bichinho primeiro para vesti-lo!", 28, Palette.UI_TEXT, 0, Palette.WHITE, true))
		return
	var who := UiKit.hbox(8)
	_content.add_child(who)
	for sp in Cast.ORDER:
		if not Game.has_met(sp):
			continue
		var b := UiKit.button(Animal.SPECIES[sp]["name"], Palette.UI_GOOD if sp == _selected else Palette.UI_MUTED, "", 0, 70)
		b.add_theme_font_size_override("font_size", 20)
		var s: String = sp
		b.pressed.connect(func():
			_selected = s
			_refresh())
		who.add_child(b)
	var preview := _portrait(_selected, true, Game.equipped(_selected))
	preview.custom_minimum_size = Vector2(0, 170)
	(preview.get_child(0) as Node2D).position = Vector2(330, 95)
	(preview.get_child(0) as Node2D).scale = Vector2(1.5, 1.5)
	_content.add_child(preview)
	for item in Game.ITEMS.keys():
		var cfg: Dictionary = Game.ITEMS[item]
		var card := UiKit.panel()
		var row := UiKit.hbox(12)
		card.add_child(row)
		var name_l := UiKit.label(cfg["name"], 26)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(name_l)
		var it: String = item
		if Game.owns(item):
			var on: bool = Game.equipped(_selected) == it
			var b := UiKit.button("Tirar" if on else "Vestir", Palette.UI_SECONDARY if on else Palette.UI_GOOD, "", 160, 72)
			b.pressed.connect(func():
				Game.equip(_selected, it)
				Sfx.play("pop")
				_refresh())
			row.add_child(b)
		else:
			var price: int = cfg["price"]
			var b := UiKit.button(str(price), Palette.GOLD, "coin", 160, 72)
			b.disabled = Game.coins() < price
			b.pressed.connect(func():
				if Game.buy_item(it):
					Sfx.play("coin")
					Game.equip(_selected, it)
					_refresh())
			row.add_child(b)
		_content.add_child(card)
	_content.add_child(UiKit.label("Ganhe moedas salvando bichinhos e conquistando estrelas.\nAcessórios são só enfeites: não mudam o jogo.", 20, Color(Palette.UI_TEXT, 0.8), 0, Palette.WHITE, true))


func _build_trophies() -> void:
	for k in Game.ACHIEVEMENTS.keys():
		var cfg: Dictionary = Game.ACHIEVEMENTS[k]
		var got: bool = Game.data["achievements"].has(k)
		var card := UiKit.panel(Palette.UI_PANEL if got else Color(1, 1, 1, 0.6))
		var row := UiKit.hbox(12)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		card.add_child(row)
		var ic := UiIcon.new()
		ic.icon = "trophy" if got else "lock"
		ic.custom_minimum_size = Vector2(64, 64)
		row.add_child(ic)
		var info := UiKit.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var n := UiKit.label(cfg["name"], 26)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(n)
		var d := UiKit.label(cfg["desc"], 21, Color(Palette.UI_TEXT, 0.8), 0, Palette.WHITE, true)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.add_child(d)
		_content.add_child(card)
