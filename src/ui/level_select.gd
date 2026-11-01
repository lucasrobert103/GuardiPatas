class_name LevelSelect
extends Control
## Mapa de fases por mundo. Fases liberam em sequência; nada de barreiras pagas.

signal go(screen: String, arg: Variant)

var world_id := 1
var _diff_btn: Button
var _bg: MenuBg
var _grid: GridContainer
var _title: Label
var _stars: Label
var _done: Label
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
	UiKit.keep_safe(margin, 24, 28, 24, 40)
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
	# dificuldade: toque para trocar (Normal → Difícil → Extremo)
	var diff := UiKit.button(Difficulty.NAMES[Difficulty.current()], [Palette.UI_GOOD, Palette.GOLD, Palette.DANGER][Difficulty.current()], "flame", 0, 72)
	diff.add_theme_font_size_override("font_size", UiKit.fs(22))
	diff.pressed.connect(func():
		var n := (Difficulty.current() + 1) % Difficulty.NAMES.size()
		Game.set_setting("difficulty", n)
		diff.text = "     " + tr(Difficulty.NAMES[n])
		var tint: Color = [Palette.UI_GOOD, Palette.GOLD, Palette.DANGER][n]
		diff.add_theme_stylebox_override("normal", UiKit.btn_style(tint, false))
		diff.add_theme_stylebox_override("hover", UiKit.btn_style(tint.lightened(0.06), false))
		Sfx.play("pop", -2.0, 0.8 + n * 0.2))
	header.add_child(diff)
	_diff_btn = diff
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

	_done = UiKit.label("", 22, Palette.WHITE, 8, Palette.OUTLINE, true)
	col.add_child(_done)
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
	var levels := LevelDB.levels_in_world(world_id)
	var span := ""
	if not levels.is_empty():
		span = tr("Fases %d a %d") % [int(levels[0]) + 1, int(levels[-1]) + 1] + "  ·  "
	_title.text = tr(str(info.get("name", ""))) if info.has("name") else tr("Mundo %d") % world_id
	_stars.text = "%d / %d" % [Game.total_stars(), LevelDB.count() * 3]
	_done.text = span + tr("%d de %d fases vencidas") % [Game.completed_count(), LevelDB.count()] + "  ·  " + tr("Missões %d/%d") % [Missions.total_done(), Missions.total_possible()]
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
	# quebra em linhas: mundos com muitos tipos de inseto não podem alargar a tela
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	for k in kinds:
		var cell := UiKit.vbox(0)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(84, 48)
		var art := InsectArt.new()
		art.kind = k
		art.radius = 14.0
		art.position = Vector2(42, 28)
		holder.add_child(art)
		cell.add_child(holder)
		var nl := UiKit.label(tr(str(Cast.INSECTS[k]["name"])), 14, Palette.UI_TEXT, 0, Palette.WHITE, true)
		nl.custom_minimum_size = Vector2(84, 0)
		cell.add_child(nl)
		row.add_child(cell)


func _level_button(index: int, n: int) -> Control:
	var lv := LevelDB.get_level(index)
	var unlocked := Game.is_unlocked(index)
	var stars := Game.stars_of(str(lv["id"]))
	# número contínuo da campanha (Fase 1, 2, 3... até a última)
	var b := UiKit.button("" if not unlocked else str(index + 1), Palette.UI_PRIMARY if unlocked else Palette.UI_MUTED, "lock" if not unlocked else "", 180, 150)
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
		# missões cumpridas (0 a 3) no canto
		var mc := Missions.done_count(str(lv["id"]))
		var ml := UiKit.label("%d/3" % mc, 16, Palette.UI_GOOD.darkened(0.3) if mc == 3 else Color(Palette.OUTLINE, 0.6))
		ml.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ml.position = Vector2(132, 6)
		ml.size = Vector2(44, 22)
		b.add_child(ml)
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
