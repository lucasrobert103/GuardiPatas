class_name HomeObject
extends Button
## Área de toque acessível cuja aparência é o objeto, não um botão com legenda.
var key := ""
var kind := ""
var item := ""
var selected := false
var dock := false
var locked := false
var cost := 0
var progress := 0.0
var light := false


func _ready() -> void:
	text = ""
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE if mouse_filter == Control.MOUSE_FILTER_IGNORE else Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	set_meta("home_action", key)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if dock:
		HomeArt.box(self, rect.grow(-3), Color("fffaf3") if selected else Color("ffffff70"), minf(size.x, size.y) * 0.38)
		if selected:
			HomeArt.oval(self, Vector2(size.x / 2, size.y - 6), Vector2(12, 3), Color("c8a2b8"))
	if is_hovered() or has_focus():
		HomeArt.box(self, rect.grow(-1), Color("ffffff20"), 26, Color("d9b2be"), 2)
	var offset := Vector2(0, 2) if is_pressed() else Vector2.ZERO
	var inset := rect.grow(-9)
	inset.position += offset
	if selected and (kind == "shower" or kind == "towel"):
		HomeArt.oval(self, size / 2, Vector2.ONE * minf(size.x, size.y) * 0.43, Color("fffdf390"))
		HomeArt.star(self, Vector2(size.x - 16, 17), 7, Color("e6c77f"))
	if kind == "accessory":
		HomeArt.box(self, rect.grow(-4), Color("fffaf3"), 24, Color("dfb7c5") if selected else Color.TRANSPARENT, 2 if selected else 0)
		HomeArt.accessory(self, item, inset.grow(-6))
		if locked:
			HomeArt.box(self, Rect2(size.x - 24, size.y - 25, 13, 13), Color("b6a6b5"), 4)
			draw_arc(Vector2(size.x - 17.5, size.y - 24), 5, PI, TAU, 12, Color("b6a6b5"), 2, true)
		elif selected:
			HomeArt.object(self, "check", Rect2(size.x - 28, size.y - 28, 25, 25))
	elif kind == "wallet":
		HomeArt.object(self, "buy", Rect2(0, 0, 44, 44))
		draw_string(UiKit.font(), Vector2(45, 30), str(cost), HORIZONTAL_ALIGNMENT_LEFT, size.x - 45, 22, HomeArt.INK)
	elif kind == "buy":
		HomeArt.box(self, rect, Color("fff4d8") if not disabled else Color("e7e1da"), 28)
		HomeArt.object(self, "buy", Rect2(3, 4, 76, size.y - 8))
		draw_string(UiKit.font(), Vector2(70, size.y / 2 + 9), str(cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, HomeArt.INK)
	else:
		HomeArt.object(self, kind, inset, selected, Color("fff7ed") if light else HomeArt.INK)
	if progress > 0:
		draw_arc(size / 2, minf(size.x, size.y) / 2 - 3, -PI / 2, -PI / 2 + TAU * progress, 32, Color("91c5bb"), 3, true)
