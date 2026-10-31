class_name SafeBurrow
extends Node2D
## Toca segura: um bichinho que entra aqui se esconde e os insetos não o acham mais.
## Os medrosos fogem para longe dos insetos — guie a fuga até a toca com rampas e paredes.

var rect := Rect2()
var _t := 0.0
var _filled := 0


func setup(r: Rect2) -> void:
	rect = r
	position = r.position


func add_guest() -> void:
	_filled += 1


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	var w := rect.size.x
	var h := rect.size.y
	var base := Vector2(w * 0.5, h)
	# montinho de terra com porta redonda e uma plaquinha de coração
	var mound := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		mound.append(base + Vector2(cos(a) * w * 0.62, sin(a) * h * 0.95))
	DrawUtil.shape(self, mound, Color("b98a5e"), o, 3.5)
	var door := PackedVector2Array()
	for i in 13:
		var a := PI + PI * float(i) / 12.0
		door.append(base + Vector2(cos(a) * w * 0.3, sin(a) * h * 0.62))
	DrawUtil.shape(self, door, Color("3a2b3c"), o, 2.5)
	var glow := 0.25 + 0.15 * sin(_t * 3.0)
	draw_colored_polygon(door, Color(1.0, 0.85, 0.4, glow if _filled > 0 else 0.08))
	var sign_p := base + Vector2(w * 0.5, -h * 0.85)
	draw_line(sign_p, sign_p + Vector2(0, h * 0.6), Palette.WOOD_DARK, 4.0, true)
	DrawUtil.disc(self, sign_p, 14.0, Palette.WHITE, o, 2.5)
	var heart := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		heart.append(sign_p + Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * 0.5)
	draw_colored_polygon(heart, Color("ff6b8a"))
