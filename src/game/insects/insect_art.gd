class_name InsectArt
extends Node2D
## Arte procedural dos insetos: silhuetas bem diferentes entre si (forma + padrão),
## para que sejam reconhecíveis sem depender só de cor.

var kind := "bee"
var radius := 10.0
var facing := 1.0
var dazed := false
var calmed := false
var aiming := false
var excited := false
var squash := 0.0

var _t := 0.0
var _hc := false


func _ready() -> void:
	_t = randf() * 10.0
	_hc = Game.setting("high_contrast")


func _process(delta: float) -> void:
	_t += delta
	squash = maxf(squash - delta * 4.0, 0.0)
	queue_redraw()


func _draw() -> void:
	if _hc and not calmed:
		draw_circle(Vector2.ZERO, radius * 1.9, Palette.DANGER_SOFT, true, -1.0, true)
		draw_arc(Vector2.ZERO, radius * 1.9, 0.0, TAU, 24, Palette.DANGER, 3.0, true)
	var sq := Vector2(1.0 + squash * 0.25, 1.0 - squash * 0.25)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sq.x * facing, sq.y))
	match kind:
		"bee": _draw_bee(Color("ffd23f"), 1.0)
		"wasp": _draw_bee(Color("ff6a3d"), 0.8)
		"mosquito": _draw_mosquito()
		"moth": _draw_moth()
		"ant": _draw_ant()
		"beetle": _draw_beetle()
	draw_set_transform(Vector2.ZERO)
	_draw_status()


func _wing_flap() -> float:
	return 0.55 + 0.45 * absf(sin(_t * 38.0))


func _eye_pair(c: Vector2, r: float) -> void:
	var o := Palette.OUTLINE
	if calmed:
		DrawUtil.arc(self, c + Vector2(0, r * 0.4), r * 0.8, PI * 1.15, PI * 1.85, o, 2.2)
		return
	if dazed:
		draw_line(c + Vector2(-r, -r), c + Vector2(r, r), o, 2.2, true)
		draw_line(c + Vector2(-r, r), c + Vector2(r, -r), o, 2.2, true)
		return
	DrawUtil.disc(self, c, r, Palette.WHITE, o, 2.0)
	draw_circle(c + Vector2(r * 0.3, 0), r * 0.55, o, true, -1.0, true)
	# sobrancelha marota (travessa, não malvada)
	draw_line(c + Vector2(-r * 1.1, -r * 1.3), c + Vector2(r * 1.1, -r * 0.8), o, 2.2, true)


func _draw_bee(body_col: Color, slim: float) -> void:
	var r := radius
	var o := Palette.OUTLINE
	var rx := r * 1.2
	var ry := r * 0.9 * slim
	var flap := _wing_flap()
	DrawUtil.oval(self, Vector2(-r * 0.25, -ry - r * 0.35 * flap), Vector2(r * 0.55, r * 0.75 * flap), Color(1, 1, 1, 0.75), o, 2.0, -0.4)
	DrawUtil.tri(self, Vector2(-rx + 2, -2), Vector2(-rx - r * 0.55, 0), Vector2(-rx + 2, 2), o, o, 2.0)
	DrawUtil.oval(self, Vector2.ZERO, Vector2(rx, ry), body_col, o, 2.5)
	for sx in [-0.35, 0.2]:
		var x: float = sx * rx
		var h := ry * sqrt(maxf(1.0 - (x / rx) * (x / rx), 0.0))
		draw_line(Vector2(x, -h + 1.5), Vector2(x, h - 1.5), o, r * 0.32, true)
	DrawUtil.oval(self, Vector2(r * 0.35, -ry - r * 0.25 * flap), Vector2(r * 0.5, r * 0.7 * flap), Color(1, 1, 1, 0.85), o, 2.0, 0.3)
	_eye_pair(Vector2(rx * 0.62, -r * 0.15), r * 0.33)
	# antenas
	draw_line(Vector2(rx * 0.6, -ry * 0.8), Vector2(rx * 0.95, -ry * 1.5), o, 1.8, true)
	draw_circle(Vector2(rx * 0.95, -ry * 1.5), 2.0, o, true, -1.0, true)


func _draw_mosquito() -> void:
	var r := radius
	var o := Palette.OUTLINE
	var flap := _wing_flap()
	for i in 3:
		var lx := -r * 0.6 + r * 0.6 * i
		var k := sin(_t * 10.0 + i) * 2.0
		draw_line(Vector2(lx, r * 0.4), Vector2(lx - r * 0.5 + k, r * 2.0), o, 1.5, true)
	DrawUtil.oval(self, Vector2(-r * 0.2, -r * 0.9 * flap), Vector2(r * 0.9, r * 0.45 * flap), Color(0.85, 0.95, 1.0, 0.7), o, 1.5, -0.3)
	DrawUtil.oval(self, Vector2(-r * 0.5, 0), Vector2(r * 1.3, r * 0.5), Color("a7a2b8"), o, 2.0)
	for i in 3:
		draw_line(Vector2(-r * 1.2 + i * r * 0.5, -r * 0.4), Vector2(-r * 1.2 + i * r * 0.5, r * 0.4), Color("6b6480"), 1.5, true)
	DrawUtil.disc(self, Vector2(r * 0.9, -r * 0.1), r * 0.55, Color("ff8a5a"), o, 2.0)
	draw_line(Vector2(r * 1.3, r * 0.1), Vector2(r * 2.3, r * 0.5), o, 1.6, true)
	if not calmed and not dazed:
		draw_circle(Vector2(r * 1.05, -r * 0.25), r * 0.22, o, true, -1.0, true)


func _draw_moth() -> void:
	var r := radius
	var o := Palette.OUTLINE
	var flap := 0.6 + 0.4 * absf(sin(_t * (14.0 if excited else 8.0)))
	var wing := Color("d9c8ef")
	DrawUtil.oval(self, Vector2(-r * 0.3, -r * 0.8 * flap), Vector2(r * 1.1, r * 0.95 * flap), wing, o, 2.0, -0.5)
	DrawUtil.oval(self, Vector2(-r * 0.3, r * 0.6 * flap), Vector2(r * 0.8, r * 0.6 * flap), Color("c4b0e0"), o, 2.0, 0.4)
	draw_circle(Vector2(-r * 0.4, -r * 0.9 * flap), r * 0.3, Color("8f6fc4"), true, -1.0, true)
	DrawUtil.oval(self, Vector2.ZERO, Vector2(r * 0.8, r * 0.45), Color("fff1d6"), o, 2.0)
	_eye_pair(Vector2(r * 0.6, -r * 0.05), r * 0.28)
	for s in [-1.0, 1.0]:
		var tip := Vector2(r * 1.3, -r * 0.9 + s * r * 0.25)
		draw_line(Vector2(r * 0.7, -r * 0.3), tip, o, 1.6, true)
		draw_circle(tip, 2.2, Color("ffe08a"), true, -1.0, true)


func _draw_ant() -> void:
	var r := radius
	var o := Palette.OUTLINE
	var col := Color("c2462f")
	var step := sin(_t * 18.0)
	for i in 3:
		var lx := -r * 0.4 + r * 0.45 * i
		var ph := step * (1.0 if i % 2 == 0 else -1.0)
		draw_line(Vector2(lx, 0), Vector2(lx + ph * 3.0, r * 1.0), o, 2.0, true)
	DrawUtil.disc(self, Vector2(-r * 0.95, -r * 0.05), r * 0.62, col, o, 2.0)
	DrawUtil.disc(self, Vector2(-r * 0.05, -r * 0.15), r * 0.42, col, o, 2.0)
	DrawUtil.disc(self, Vector2(r * 0.75, -r * 0.3), r * 0.55, col, o, 2.0)
	_eye_pair(Vector2(r * 0.9, -r * 0.45), r * 0.25)
	draw_line(Vector2(r * 0.9, -r * 0.75), Vector2(r * 1.45, -r * 1.4 + step), o, 1.6, true)


func _draw_beetle() -> void:
	var r := radius
	var o := Palette.OUTLINE
	var step := sin(_t * 9.0)
	for i in 3:
		var lx := -r * 0.5 + r * 0.5 * i
		var ph := step * (1.0 if i % 2 == 0 else -1.0)
		draw_line(Vector2(lx, r * 0.3), Vector2(lx + ph * 4.0, r * 0.95), o, 3.0, true)
	DrawUtil.disc(self, Vector2(r * 0.75, r * 0.05), r * 0.45, Color("2b2f55"), o, 2.5)
	DrawUtil.tri(self, Vector2(r * 0.95, -r * 0.2), Vector2(r * 1.5, -r * 0.7), Vector2(r * 1.15, r * 0.05), Color("2b2f55"), o, 2.0)
	var shell := PackedVector2Array()
	for i in 15:
		var a := PI + PI * float(i) / 14.0
		shell.append(Vector2(-r * 0.15, r * 0.45) + Vector2(cos(a) * r * 0.95, sin(a) * r * 1.05))
	DrawUtil.shape(self, shell, Color("3b4a9a"), o, 2.5)
	draw_line(Vector2(-r * 0.15, -r * 0.55), Vector2(-r * 0.15, r * 0.45), o, 2.0, true)
	DrawUtil.oval(self, Vector2(-r * 0.5, -r * 0.2), Vector2(r * 0.18, r * 0.3), Color(1, 1, 1, 0.55), o, 0.0, -0.4)
	_eye_pair(Vector2(r * 0.88, -r * 0.05), r * 0.2)


func _draw_status() -> void:
	var top := Vector2(0, -radius * 2.2)
	if aiming and not calmed:
		var blink := absf(sin(_t * 16.0)) > 0.3
		if blink:
			DrawUtil.disc(self, top + Vector2(0, -4), 10.0, Palette.GOLD, Palette.OUTLINE, 2.5)
			draw_line(top + Vector2(0, -10), top + Vector2(0, -2), Palette.OUTLINE, 3.0, true)
			draw_circle(top + Vector2(0, 1), 1.8, Palette.OUTLINE, true, -1.0, true)
	elif dazed and not calmed:
		for i in 2:
			var a := _t * 6.0 + PI * i
			var p := top + Vector2(cos(a) * 10.0, sin(a) * 3.0)
			DrawUtil.shape(self, DrawUtil.star_points(p, 5.0, 2.2), Palette.GOLD, Palette.OUTLINE, 1.5)
	elif calmed and kind in ["ant", "beetle"]:
		var z := fmod(_t, 1.5) / 1.5
		var font := ThemeDB.fallback_font
		draw_string(font, top + Vector2(4, -z * 14.0), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(Palette.OUTLINE, 1.0 - z))
