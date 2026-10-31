class_name AttemptReview
extends Control
## Revisão visual: nunca restaura nem avança a simulação que decidiu o resultado.
signal closed
signal retry
var model: AttemptReplay
var info: Dictionary
var playing := false
var cursor := 0.0
var _was_paused := false
var _restored := false
var _canvas: ReviewCanvas
var _play: Button
var _timeline: HSlider
var _time: Label
var _title: Label
var _explanation: Label
var _legend: Label
var _buttons: Array[Button] = []
var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_was_paused = get_tree().paused
	get_tree().paused = true
	var background := ColorRect.new()
	background.color = Color("f6f0e8")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_box = UiKit.vbox(10)
	_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box.offset_left = 18
	_box.offset_right = -18
	_box.offset_top = 18
	_box.offset_bottom = -18
	add_child(_box)
	_title = UiKit.label("Onde falhou", 30, HomeArt.INK)
	_box.add_child(_title)
	_explanation = UiKit.label(str(info.get("analysis", "")), 22, HomeArt.INK, 0, Color.WHITE, true)
	_explanation.custom_minimum_size.y = 64
	_box.add_child(_explanation)
	_canvas = ReviewCanvas.new()
	_canvas.model = model
	_canvas.point = info.get("failure_point", Vector2.INF)
	_canvas.custom_minimum_size.y = 120
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(_canvas)
	_legend = UiKit.label("Marca vermelha: local da derrota", 18, HomeArt.INK)
	_box.add_child(_legend)
	var playback := UiKit.hbox(14)
	_box.add_child(playback)
	_play = _button("Rever ½×")
	_play.pressed.connect(func():
		if cursor >= model.duration() - 0.001: cursor = 0
		playing = not playing
		_refresh())
	playback.add_child(_play)
	_time = UiKit.label("", 20, HomeArt.INK)
	_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playback.add_child(_time)
	_timeline = HSlider.new()
	_timeline.min_value = 0
	_timeline.max_value = maxf(0.01, model.duration())
	_timeline.step = 0.01
	_timeline.custom_minimum_size.y = 40
	_timeline.tooltip_text = tr("Arraste para rever")
	_timeline.drag_started.connect(func(): playing = false)
	_timeline.value_changed.connect(func(value: float):
		playing = false
		cursor = value
		_refresh())
	_box.add_child(_timeline)
	var actions := UiKit.hbox(12)
	_box.add_child(actions)
	var back := _button("Resultado")
	back.pressed.connect(close)
	actions.add_child(back)
	var again := _button("Recomeçar")
	again.pressed.connect(func():
		_restore()
		retry.emit())
	actions.add_child(again)
	resized.connect(_layout)
	_layout()
	cursor = model.duration()
	_refresh()
	_play.grab_focus()


func _button(label: String) -> Button:
	var button := Button.new()
	button.text = tr(label)
	button.tooltip_text = tr(label)
	button.clip_text = true
	_buttons.append(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 54
	button.add_theme_font_override("font", UiKit.font())
	button.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("dcebe3") if state != "pressed" else Color("c5ded2")
		style.set_corner_radius_all(16)
		if state == "focus":
			style.set_border_width_all(2)
			style.border_color = Color("9986ad")
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, HomeArt.INK)
	return button


func _layout() -> void:
	if _box == null: return
	var width := minf(size.x - 36, 1000)
	var compact := size.y < 800 or size.x < 500
	_box.add_theme_constant_override("separation", 6 if compact else 10)
	_title.label_settings.font_size = UiKit.fs(24 if compact else 30)
	_explanation.label_settings.font_size = UiKit.fs(18 if compact else 22)
	_explanation.custom_minimum_size.y = 48 if compact else 64
	_legend.label_settings.font_size = UiKit.fs(16 if compact else 18)
	for button in _buttons:
		button.custom_minimum_size.y = 44 if compact else 54
		button.add_theme_font_size_override("font_size", UiKit.fs(18 if compact else 20))
	_box.offset_left = (size.x - width) / 2
	_box.offset_right = -(size.x - width) / 2


func _process(delta: float) -> void:
	if playing:
		cursor = minf(model.duration(), cursor + minf(delta, 0.2) * 0.5)
		if cursor >= model.duration(): playing = false
		_refresh()


func _refresh() -> void:
	_play.text = tr("Pausar" if playing else "Rever ½×")
	_time.text = "%.1f / %.1f s" % [cursor, model.duration()]
	_timeline.set_value_no_signal(cursor)
	_canvas.show_frame(model.at(cursor))


func _restore() -> void:
	if _restored: return
	_restored = true
	if get_tree() != null: get_tree().paused = _was_paused


func _exit_tree() -> void:
	_restore()


func close() -> void:
	_restore()
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


class ReviewCanvas:
	extends Control
	var model: AttemptReplay
	var point := Vector2.INF
	var frame: Dictionary = {}
	var _actors: Dictionary = {}
	var _stage: Node2D
	var _base := Transform2D.IDENTITY
	var _marker: Marker
	var bounds := Rect2(0, 140, 720, 1120)

	func _ready() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage = Node2D.new()
		add_child(_stage)
		_marker = Marker.new()
		_marker.z_index = 20
		add_child(_marker)
		resized.connect(func(): show_frame(frame))

	func show_frame(value: Dictionary) -> void:
		frame = value
		if _stage == null: return
		if point.is_finite(): bounds = Rect2(0, clampf(point.y - 420, 140, 600), 720, 600)
		var scale_factor := minf(size.x / bounds.size.x, size.y / bounds.size.y)
		var origin := (size - bounds.size * scale_factor) / 2 - bounds.position * scale_factor
		_base = Transform2D(0, Vector2.ONE * scale_factor, 0, origin)
		_stage.transform = _base
		_marker.visible = point.is_finite()
		if point.is_finite():
			var screen_point := _base * point
			_marker.position = Vector2(clampf(screen_point.x, 16, size.x-16), clampf(screen_point.y, 16, size.y-16))
		for actor in _actors.values(): actor.visible = false
		for data in frame.get("bosses", []):
			var id: int = data["id"]
			if not _actors.has(id):
				var art: Node2D = QueenBee.new() if data["kind"] == "queen" else Boss.new()
				art.process_mode = Node.PROCESS_MODE_DISABLED
				_stage.add_child(art)
				_actors[id] = art
			var boss: Node2D = _actors[id]
			boss.visible = true
			boss.position = data["position"]
			boss._t = data["clock"]
			if boss is QueenBee:
				boss._puff = data["puff"]
				boss._blow = data["blow"]
			else:
				boss.kind = data["kind"]
				boss._phase = data["phase"]
				boss._phase_t = data["phase_time"]
				boss._marks = data["marks"]
				boss._ground_y = data["ground"]
				boss._aim = data["aim"]
				boss._launch_v = data["launch"]
				boss._ink = data["ink"]
				boss._ink_pos = data["ink_position"]
				boss._flap = data["flap"]
			boss.queue_redraw()
		for data in frame.get("actors", []):
			var id: int = data["id"]
			if not _actors.has(id):
				var art: Node2D
				if data["animal"]:
					art = AnimalArt.new()
					art.species = data["kind"]
					art.preview = true
				else:
					art = InsectArt.new()
					art.kind = data["kind"]
				_stage.add_child(art)
				art.set_process(false)
				_actors[id] = art
			var actor: Node2D = _actors[id]
			actor.visible = true
			actor.position = data["position"]
			actor.rotation = data["rotation"]
			actor.facing = data["facing"]
			actor._t = data["clock"]
			if data["animal"]:
				actor.mood = data["mood"]
				actor.accessory = data["accessory"]
			else:
				actor.radius = data["radius"]
				actor.aiming = data["aiming"]
				actor.dazed = data["dazed"]
				actor.excited = data["excited"]
				actor.thread = data["thread"]
				actor.work_progress = data["work"]
				actor.aim_vector = data["aim_vector"]
				actor.aim_progress = data["aim_progress"]
				actor.jump_velocity = data["jump_velocity"]
				actor.squash = data["squash"]
			actor.queue_redraw()
		queue_redraw()

	func _draw() -> void:
		HomeArt.box(self, Rect2(Vector2.ZERO, size), Color("e5eee8"), 20)
		if model == null or frame.is_empty(): return
		for terrain in model.terrain:
			draw_set_transform_matrix(_base * terrain["transform"])
			DrawUtil.shape(self, terrain["points"], Palette.STONE if terrain["style"] != "ground" else Color("c3d3b0"), Color("a7b6a0"), 2)
		draw_set_transform_matrix(_base)
		for water in model.waters: draw_rect(water, Color("8fc9dd"))
		if model.goal.size.x > 0:
			HomeArt.box(self, model.goal, Color("ddc4a6"), 20)
		for wind in frame.get("winds", []):
			var center: Vector2 = wind["rect"].get_center()
			for offset in [-90,0,90]:
				var origin := center + Vector2(offset,0)
				var direction: Vector2 = wind["dir"] * 55
				draw_line(origin, origin+direction, Color("709aab"), 4, true)
				draw_line(origin+direction, origin+direction*0.7+direction.orthogonal()*0.2, Color("709aab"), 4, true)
		for nest in frame["nests"]:
			var center: Vector2 = nest["position"]
			DrawUtil.disc(self, center, 20, Color("a88c72"), Palette.OUTLINE, 2)
			DrawUtil.disc(self, center, 9, Color("68535c"), Color.TRANSPARENT, 0)
			if nest["remaining"] > 0: draw_string(UiKit.font(), center + Vector2(16,-22), "×%d" % nest["remaining"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Palette.OUTLINE)
			if nest["hole"]:
				for index in 2:
					var side := Vector2(-Nest.MOUTH_HALF_WIDTH if index == 0 else Nest.MOUTH_HALF_WIDTH, -8)
					var covered := bool(int(nest.get("coverage", 0)) & (1 << index))
					DrawUtil.disc(self, center + side, 3.5, Palette.UI_GOOD if covered else Palette.GOLD, Palette.OUTLINE, 1)
					if covered: draw_line(center + side - Vector2(2, 0), center + side + Vector2(2, 0), Palette.WHITE, 1.5, true)
			if nest["plugged"]: HomeArt.object(self, "check", Rect2(center - Vector2(14, 32), Vector2(28, 28)))
		for lamp in frame["lamps"]:
			DrawUtil.disc(self, lamp["position"], 20, Palette.GOLD if lamp["lit"] else Color("b2adb6"), Palette.OUTLINE, 2)
		for block in frame["blocks"]:
			draw_set_transform_matrix(_base * block["transform"])
			draw_rect(Rect2(-block["size"] / 2, block["size"]), Palette.WOOD if block["wood"] else Palette.STONE)
		for line in frame["lines"]:
			draw_set_transform_matrix(_base * line["transform"])
			var points: PackedVector2Array = model.geometry[line["id"]]
			if points.size() > 1:
				draw_polyline(points, Palette.OUTLINE, 20, true)
				draw_polyline(points, Palette.INK_STATIC if line["static"] else Palette.INK, 14, true)
			for hole in line["holes"]: draw_circle(hole, 8, Palette.OUTLINE, true, -1, true)
		draw_set_transform_matrix(_base)
		for shot in frame["shots"]:
			DrawUtil.disc(self, shot["position"], shot["radius"], Color.WHITE if shot["kind"] == "snow" else Color("a47d5e") if shot["kind"] == "coconut" else Color("ebba9c"), Palette.OUTLINE, 2)
		draw_set_transform_matrix(Transform2D.IDENTITY)

class Marker:
	extends Node2D
	func _draw() -> void:
		draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color.WHITE, 6, true)
		draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Palette.DANGER, 3, true)
		draw_line(Vector2(-6,0), Vector2(6,0), Palette.DANGER, 2, true)
		draw_line(Vector2(0,-6), Vector2(0,6), Palette.DANGER, 2, true)
