class_name MenuBg
extends Control
## Fundo dos menus: céu, sol, colinas e flores — no mesmo estilo das fases.

var world_id := 1
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var pal := Palette.world(world_id)
	var w := size.x
	var h := size.y
	DrawUtil.vgradient(self, Rect2(Vector2.ZERO, size), pal["sky_top"], pal["sky_bottom"])
	if world_id == 5:
		DrawUtil.disc(self, Vector2(w * 0.8, h * 0.14), 44.0, Color("fff6cf"), Color(0, 0, 0, 0), 0.0)
	else:
		draw_circle(Vector2(w * 0.8, h * 0.14), 86.0, Color(1, 0.95, 0.6, 0.25), true, -1.0, true)
		DrawUtil.disc(self, Vector2(w * 0.8, h * 0.14), 50.0, Color("ffe066"), Color("f5b83d"), 4.0)
	for i in 3:
		var x := fmod(_t * (10.0 + i * 4.0) + i * 300.0, w + 300.0) - 150.0
		DrawUtil.cloud(self, Vector2(x, h * (0.1 + i * 0.07)), 40.0 + i * 8.0, Color(1, 1, 1, 0.85))
	_hill(pal["far"], h * 0.72, 120.0, 0.006, 1.1)
	_hill(pal["near"], h * 0.82, 70.0, 0.012, 0.3)
	var ground := Rect2(0, h * 0.9, w, h * 0.1 + 4)
	draw_rect(ground, pal["dirt"], true)
	draw_line(Vector2(0, h * 0.9), Vector2(w, h * 0.9), Palette.OUTLINE, 26.0, true)
	draw_line(Vector2(0, h * 0.9), Vector2(w, h * 0.9), pal["ground"], 22.0, true)


func _hill(color: Color, base_y: float, amp: float, freq: float, phase: float) -> void:
	var pts := PackedVector2Array()
	var x := -20.0
	while x <= size.x + 40.0:
		pts.append(Vector2(x, base_y - amp * (0.5 + 0.5 * sin(x * freq + phase))))
		x += 30.0
	var top := pts.duplicate()
	pts.append(Vector2(size.x + 40.0, size.y))
	pts.append(Vector2(-20.0, size.y))
	draw_colored_polygon(pts, color)
	draw_polyline(top, Color(color).darkened(0.18), 4.0, true)
