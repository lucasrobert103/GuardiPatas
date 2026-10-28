class_name Fx
extends Node2D
## Pequeno sistema de partículas desenhadas (poeira, respingos, confete, brilhos, textos).
## Um nó por explosão; ele se apaga sozinho. Barato e sem texturas.

var particles: Array = []
var gravity := 600.0
var text := ""
var text_color := Palette.OUTLINE
var _text_t := 0.0
var _text_life := 0.0


static func _new_burst(parent: Node, pos: Vector2) -> Fx:
	var fx := Fx.new()
	fx.position = pos
	fx.z_index = 50
	if parent != null:
		parent.add_child(fx)
	return fx


static func _density() -> float:
	return 0.4 if Game.setting("reduce_motion") else 1.0


static func dust(parent: Node, pos: Vector2) -> void:
	var fx := _new_burst(parent, pos)
	fx.gravity = -40.0
	for i in int(8 * _density()) + 2:
		var a := randf_range(PI * 1.05, PI * 1.95)
		fx._add(Vector2.ZERO, Vector2.from_angle(a) * randf_range(40, 120), randf_range(0.35, 0.6), randf_range(6, 11), Color(1, 1, 1, 0.8), 0)


static func splash(parent: Node, pos: Vector2) -> void:
	var fx := _new_burst(parent, pos)
	for i in int(12 * _density()) + 3:
		var a := randf_range(PI * 1.15, PI * 1.85)
		fx._add(Vector2.ZERO, Vector2.from_angle(a) * randf_range(120, 300), randf_range(0.4, 0.8), randf_range(3, 6), Palette.WATER_HI, 0)


static func confetti(parent: Node, pos: Vector2, amount: int = 40) -> void:
	var fx := _new_burst(parent, pos)
	fx.gravity = 380.0
	var cols := [Palette.GOLD, Palette.INK, Color("ff9ec7"), Color("5cc46a"), Color("ff8a3d"), Color("b18cff")]
	for i in int(amount * _density()) + 4:
		var a := randf_range(PI * 1.1, PI * 1.9)
		fx._add(Vector2.ZERO, Vector2.from_angle(a) * randf_range(250, 620), randf_range(1.2, 2.0), randf_range(5, 9), cols[i % cols.size()], 1)


static func sparkle(parent: Node, pos: Vector2, color: Color = Palette.GOLD) -> void:
	var fx := _new_burst(parent, pos)
	fx.gravity = 0.0
	for i in int(7 * _density()) + 3:
		var a := TAU * i / 8.0
		fx._add(Vector2.ZERO, Vector2.from_angle(a) * randf_range(60, 140), randf_range(0.4, 0.7), randf_range(5, 8), color, 2)


static func popup_text(parent: Node, pos: Vector2, msg: String, color: Color = Palette.OUTLINE, life: float = 1.2) -> void:
	var fx := _new_burst(parent, pos)
	fx.text = String(TranslationServer.translate(msg))
	fx.text_color = color
	fx._text_life = life


func _add(p: Vector2, v: Vector2, life: float, size: float, color: Color, shape: int) -> void:
	particles.append({"p": p, "v": v, "life": life, "max": life, "size": size, "color": color, "shape": shape, "rot": randf() * TAU, "spin": randf_range(-8, 8)})


func _process(delta: float) -> void:
	for pt in particles:
		pt["v"] += Vector2(0, gravity * delta)
		pt["v"] *= 0.985 if pt["shape"] == 1 else 1.0
		pt["p"] += pt["v"] * delta
		pt["life"] -= delta
		pt["rot"] += pt["spin"] * delta
	particles = particles.filter(func(pt): return pt["life"] > 0.0)
	if text != "":
		_text_t += delta
	if particles.is_empty() and (text == "" or _text_t >= _text_life):
		queue_free()
	queue_redraw()


func _draw() -> void:
	for pt in particles:
		var k: float = pt["life"] / pt["max"]
		var c: Color = pt["color"]
		c.a *= clampf(k * 1.5, 0.0, 1.0)
		var s: float = pt["size"] * (0.6 + 0.4 * k)
		match int(pt["shape"]):
			0:
				draw_circle(pt["p"], s, c, true, -1.0, true)
			1:
				draw_set_transform(pt["p"], pt["rot"], Vector2(1.0, absf(sin(pt["rot"] * 1.7)) + 0.2))
				draw_rect(Rect2(-s * 0.5, -s * 0.35, s, s * 0.7), c, true)
				draw_set_transform(Vector2.ZERO)
			2:
				DrawUtil.shape(self, DrawUtil.star_points(pt["p"], s, s * 0.45, pt["rot"]), c, Color(Palette.OUTLINE, c.a), 1.5)
	if text != "":
		var k := clampf(_text_t / _text_life, 0.0, 1.0)
		var font := ThemeDB.fallback_font
		var y := -40.0 * k
		var col := Color(text_color, 1.0 - k * k)
		var outline := Color(Palette.WHITE, 1.0 - k * k)
		draw_string_outline(font, Vector2(-150, y), text, HORIZONTAL_ALIGNMENT_CENTER, 300, 30, 8, outline)
		draw_string(font, Vector2(-150, y), text, HORIZONTAL_ALIGNMENT_CENTER, 300, 30, col)
