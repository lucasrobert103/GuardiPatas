class_name LevelSelect
extends Control
## Mapa de fases por mundo. Fases liberam em sequência; nada de barreiras pagas.

signal go(screen: String, arg: Variant)

var world_id := 1
var _bg: MenuBg
var _grid: GridContainer
var _title: Label
var _stars: Label
var _prev: Button
var _next: Button
var _info: PanelContainer


func setup(p_world: int) -> void:
	world_id = p_world


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if world_id < 1:
		world_id = _current_world()
	_bg = MenuBg.new()
	add_child(_bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var col := UiKit.vbox(22)
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(col)
	var header := UiKit.hbox(12)
	col.add_child(header)
	var back := UiKit.icon_button("back")
	back.pressed.connect(func(): go.emit("title", null))
	header.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var star_ic := UiIcon.new()
	star_ic.icon = "star"
	star_ic.custom_minimum_size = Vector2(52, 52)
	header.add_child(star_ic)
	_stars = UiKit.label("", 32, Palette.WHITE, 10, Palette.OUTLINE)
	header.add_child(_stars)

	var nav := UiKit.hbox(12)
	col.add_child(nav)
	_prev = UiKit.icon_button("back", Palette.UI_SECONDARY, 84)
	_prev.pressed.connect(func(): _switch(-1))
	nav.add_child(_prev)
	_title = UiKit.title("", 42)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size = Vector2(380, 110)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(_title)
	_next = UiKit.icon_button("next", Palette.UI_SECONDARY, 84)
	_next.pressed.connect(func(): _switch(1))
	nav.add_child(_next)

	var panel := UiKit.panel(Color(1, 1, 1, 0.82))
	col.add_child(panel)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 22)
	panel.add_child(_grid)
	_info = UiKit.panel(Color(1, 1, 1, 0.82))
	col.add_child(_info)
	_refresh()
	Sfx.music("music_menu")


func _worlds() -> Array:
	var ids: Array = []
	for i in LevelDB.count():
		var w := int(LevelDB.get_level(i)["world"])
		if not ids.has(w):
			ids.append(w)
	return ids


func _current_world() -> int:
	var w := 1
	for i in LevelDB.count():
		if Game.is_unlocked(i):
			w = int(LevelDB.get_level(i)["world"])
	return w


func _switch(dir: int) -> void:
	var ids := _worlds()
	var i := ids.find(world_id)
	var ni := clampi(i + dir, 0, ids.size() - 1)
	if ni == i:
		return
	world_id = ids[ni]
	_refresh()
	UiKit.pop_in(_grid)


func _refresh() -> void:
	_bg.world_id = world_id
	var info := LevelDB.world_info(world_id)
	_title.text = str(info.get("name", "Mundo %d" % world_id))
	_stars.text = "%d / %d" % [Game.total_stars(), LevelDB.count() * 3]
	var ids := _worlds()
	_prev.disabled = ids.find(world_id) <= 0
	_next.disabled = ids.find(world_id) >= ids.size() - 1
	for c in _grid.get_children():
		c.queue_free()
	var n := 0
	var kinds: Array = []
	for i in LevelDB.levels_in_world(world_id):
		n += 1
		_grid.add_child(_level_button(i, n))
		for nest in LevelDB.get_level(i).get("nests", []):
			if not kinds.has(nest["insect"]):
				kinds.append(nest["insect"])
	_build_info(kinds)


func _build_info(kinds: Array) -> void:
	for c in _info.get_children():
		c.queue_free()
	var box := UiKit.vbox(8)
	_info.add_child(box)
	box.add_child(UiKit.label("Insetos deste mundo", 28))
	var row := UiKit.hbox(6)
	box.add_child(row)
	for k in kinds:
		var cell := UiKit.vbox(0)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(96, 64)
		var art := InsectArt.new()
		art.kind = k
		art.radius = 16.0
		art.position = Vector2(48, 36)
		holder.add_child(art)
		cell.add_child(holder)
		var nm: String = Cast.INSECTS[k]["name"].split(" ")[0]
		cell.add_child(UiKit.label(nm, 18))
		row.add_child(cell)


func _level_button(index: int, n: int) -> Control:
	var lv := LevelDB.get_level(index)
	var unlocked := Game.is_unlocked(index)
	var stars := Game.stars_of(str(lv["id"]))
	var b := UiKit.button("" if not unlocked else str(n), Palette.UI_PRIMARY if unlocked else Palette.UI_MUTED, "lock" if not unlocked else "", 180, 150)
	b.add_theme_font_size_override("font_size", 48)
	if unlocked:
		var row := UiKit.hbox(0)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		row.position += Vector2(-54, -44)
		for k in 3:
			var ic := UiIcon.new()
			ic.icon = "star" if k < stars else "star_empty"
			ic.custom_minimum_size = Vector2(36, 36)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(ic)
		b.add_child(row)
		# medalhas extras no topo do botão (apagadas até serem ganhas)
		var medals := UiKit.hbox(2)
		medals.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medals.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		medals.position += Vector2(-42, 6)
		for m in Game.MEDALS:
			var mi := UiIcon.new()
			mi.icon = Game.MEDAL_INFO[m]["icon"]
			mi.custom_minimum_size = Vector2(26, 26)
			mi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mi.modulate = Color.WHITE if Game.has_medal(str(lv["id"]), m) else Color(1, 1, 1, 0.22)
			medals.add_child(mi)
		b.add_child(medals)
		if not (lv.get("bosses", []) as Array).is_empty():
			var crown := UiIcon.new()
			crown.icon = "trophy"
			crown.custom_minimum_size = Vector2(34, 34)
			crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
			crown.position = Vector2(140, 4)
			b.add_child(crown)
		b.pressed.connect(func(): go.emit("level", index))
	else:
		b.pressed.connect(func(): Sfx.play("ui_locked"))
	return b
