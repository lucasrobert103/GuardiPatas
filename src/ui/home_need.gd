class_name HomeNeed
extends Control
var kind := "food"
var value := 70.0
var shown := 70.0
var tint := Color("a3cabc")


func _process(delta: float) -> void:
	if not is_equal_approx(shown, value):
		shown = move_toward(shown, value, delta * 90)
		queue_redraw()


func _draw() -> void:
	var radius := minf(size.x, size.y) / 2 - 4
	var center := size / 2
	HomeArt.oval(self, center, Vector2.ONE * (radius - 3), Color("fffaf2"))
	draw_arc(center, radius, 0, TAU, 48, Color("e5ded9"), 4, true)
	if shown > 0:
		draw_arc(center, radius, -PI / 2, -PI / 2 + TAU * shown / 100.0, 48, tint if shown >= 25 else Color("dfac8d"), 5, true)
	HomeArt.object(self, kind, Rect2(center - Vector2.ONE * radius * 0.62, Vector2.ONE * radius * 1.24))
