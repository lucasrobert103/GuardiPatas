class_name HomeArt
extends RefCounted
## Ilustrações vetoriais da Casinha: formas suaves, sombras e objetos reconhecíveis.
const INK := Color("766978")
static var _styles: Dictionary = {}


static func box(ci: CanvasItem, rect: Rect2, color: Color, radius: float = 20, border: Color = Color.TRANSPARENT, width: int = 0) -> void:
	var key := "%s/%s/%s/%s" % [color.to_html(), radius, border.to_html(), width]
	if not _styles.has(key):
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(int(radius))
		style.border_color = border
		style.set_border_width_all(width)
		_styles[key] = style
	ci.draw_style_box(_styles[key], rect)


static func oval(ci: CanvasItem, center: Vector2, radius: Vector2, color: Color, border: Color = Color.TRANSPARENT, width: float = 0) -> void:
	DrawUtil.oval(ci, center, radius, color, border, width)


static func shadow(ci: CanvasItem, center: Vector2, width: float, alpha: float = 0.10) -> void:
	oval(ci, center, Vector2(width, width * 0.16), Color(0.36, 0.29, 0.34, alpha))


static func heart(ci: CanvasItem, center: Vector2, scale_factor: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		points.append(center + Vector2(16 * pow(sin(a), 3), -(13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a))) * scale_factor)
	DrawUtil.shape(ci, points, color, color.darkened(0.12), 1.5)


static func star(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	DrawUtil.shape(ci, DrawUtil.star_points(center, radius, radius * 0.48), color, color.darkened(0.1), 1)


static func ball(ci: CanvasItem, center: Vector2, radius: float) -> void:
	DrawUtil.disc(ci, center, radius, Color("fff4d5"), Color("a9bcaf"), 2.5)
	for i in 3:
		var points := PackedVector2Array([center])
		for j in 15:
			var a := i * TAU / 3.0 + j * TAU / 42.0
			points.append(center + Vector2.from_angle(a) * (radius - 2))
		DrawUtil.shape(ci, points, [Color("e99bac"), Color("9ecfc8"), Color("edc571")][i], Color.TRANSPARENT, 0)
	oval(ci, center + Vector2(-radius * 0.26, -radius * 0.35), Vector2(radius * 0.28, radius * 0.13), Color(1, 1, 1, 0.55))
	DrawUtil.disc(ci, center, radius * 0.12, Color("fff9ef"), Color.TRANSPARENT, 0)


static func object(ci: CanvasItem, kind: String, rect: Rect2, active: bool = false, ink: Color = INK) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y) / 100.0
	# Objetos partilham um espaço local de 100 x 100, sem caixas de botão pintadas.
	match kind:
		"back":
			ci.draw_polyline(PackedVector2Array([c + Vector2(9, -17) * s, c + Vector2(-10, 0) * s, c + Vector2(9, 17) * s]), ink, 4 * s, true)
		"album":
			box(ci, Rect2(c + Vector2(-30, -28) * s, Vector2(60, 60) * s), Color("e5b7b1"), 9 * s)
			box(ci, Rect2(c + Vector2(-22, -25) * s, Vector2(50, 51) * s), Color("fffaf0"), 5 * s)
			box(ci, Rect2(c + Vector2(-17, -20) * s, Vector2(40, 31) * s), Color("b7ddd7"), 4 * s)
			heart(ci, c + Vector2(3, -3) * s, 0.67 * s, Color("e697a7"))
		"meal", "food":
			oval(ci, c + Vector2(0, 25) * s, Vector2(38, 9) * s, Color("897e7730"))
			box(ci, Rect2(c + Vector2(-34, -5) * s, Vector2(68, 34) * s), Color("e5a19f"), 14 * s)
			oval(ci, c + Vector2(0, -5) * s, Vector2(34, 13) * s, Color("f4d8b3"), Color("d18b8b"), 2 * s)
			for i in 8:
				var point := c + Vector2(sin(i * 2.4) * 23, cos(i * 1.9) * 7 - 8) * s
				DrawUtil.disc(ci, point, 5 * s, Color("ae8157"), Color.TRANSPARENT, 0)
			heart(ci, c + Vector2(0, 16) * s, 0.37 * s, Color("fff5e2"))
		"fruit":
			oval(ci, c + Vector2(0, 32) * s, Vector2(28, 6) * s, Color("897e7720"))
			oval(ci, c + Vector2(-10, 4) * s, Vector2(22, 28) * s, Color("eaa28e"))
			oval(ci, c + Vector2(11, 4) * s, Vector2(22, 28) * s, Color("e8918c"))
			ci.draw_line(c + Vector2(0, -18) * s, c + Vector2(3, -36) * s, Color("957459"), 5 * s, true)
			oval(ci, c + Vector2(14, -29) * s, Vector2(15, 6) * s, Color("91bb87"))
			oval(ci, c + Vector2(-17, -3) * s, Vector2(5, 11) * s, Color(1, 1, 1, 0.45))
		"snack":
			DrawUtil.disc(ci, c, 32 * s, Color("edc58b"), Color("cba675"), 2 * s)
			for i in 7:
				DrawUtil.disc(ci, c + Vector2(sin(i * 2.1) * 21, cos(i * 1.7) * 21) * s, 3.5 * s, Color("b68c68"), Color.TRANSPARENT, 0)
			heart(ci, c, s, Color("f6dbc0"))
		"soap", "clean":
			box(ci, Rect2(c + Vector2(-32, -18) * s, Vector2(64, 43) * s), Color("b0dad2"), 15 * s)
			box(ci, Rect2(c + Vector2(-29, -22) * s, Vector2(58, 35) * s), Color("d2ede4"), 14 * s)
			heart(ci, c + Vector2(0, -4) * s, 0.7 * s, Color("93beb8"))
			for i in 4:
				DrawUtil.disc(ci, c + Vector2(-18 + i * 15, -25 - (i % 2) * 12) * s, (6 + i % 2 * 3) * s, Color("f8fffa"), Color("c5e5de"), 1)
		"bath":
			box(ci, Rect2(c + Vector2(-35, -5) * s, Vector2(70, 36) * s), Color("fefbf4"), 16 * s, Color("b8cdd2"), 2)
			oval(ci, c + Vector2(0, -5) * s, Vector2(36, 12) * s, Color("bfe6ea"))
			for x in [-23, 23]:
				box(ci, Rect2(c + Vector2(x - 3, 26) * s, Vector2(6, 9) * s), Color("c3aa91"), 2)
			for i in 3:
				DrawUtil.disc(ci, c + Vector2(-18 + i * 17, -17 - (i % 2) * 11) * s, 8 * s, Color("fffdf8"), Color("daeeee"), 1)
		"shower":
			ci.draw_polyline(PackedVector2Array([c + Vector2(26, 36) * s, c + Vector2(26, -26) * s, c + Vector2(-8, -26) * s]), Color("9bafb5"), 9 * s, true)
			oval(ci, c + Vector2(-10, -20) * s, Vector2(23, 8) * s, Color("b3c9ca"))
			for i in 3:
				ci.draw_line(c + Vector2(-24 + i * 14, -6) * s, c + Vector2(-28 + i * 14, 10) * s, Color("94d5e1"), 3 * s, true)
		"towel":
			box(ci, Rect2(c + Vector2(-30, -29) * s, Vector2(60, 58) * s), Color("e6b7c6"), 9 * s)
			box(ci, Rect2(c + Vector2(-30, 9) * s, Vector2(60, 20) * s), Color("f3ced8"), 7 * s)
			for x in [-18, -6, 6, 18]:
				ci.draw_line(c + Vector2(x, 25) * s, c + Vector2(x, 34) * s, Color("d49cae"), 2 * s, true)
		"sleep", "bed":
			box(ci, Rect2(c + Vector2(-36, -25) * s, Vector2(72, 52) * s), Color("c6aa96"), 14 * s)
			box(ci, Rect2(c + Vector2(-31, -21) * s, Vector2(62, 42) * s), Color("fdf6e9"), 12 * s)
			box(ci, Rect2(c + Vector2(-26, -17) * s, Vector2(21, 25) * s), Color("fffdf8"), 7 * s)
			box(ci, Rect2(c + Vector2(-1, -21) * s, Vector2(32, 42) * s), Color("c5bbdf"), 10 * s)
			star(ci, c + Vector2(14, 1) * s, 8 * s, Color("f7e8b8"))
		"lamp", "energy":
			if kind == "energy":
				DrawUtil.disc(ci, c, 25 * s, Color("e7d59a"), Color.TRANSPARENT, 0)
				DrawUtil.disc(ci, c + Vector2(12, -9) * s, 23 * s, Color("fffaf0"), Color.TRANSPARENT, 0)
			else:
				oval(ci, c + Vector2(0, 31) * s, Vector2(26, 7) * s, Color("b69e90"))
				ci.draw_line(c + Vector2(0, -2) * s, c + Vector2(0, 29) * s, Color("c9ad93"), 6 * s, true)
				DrawUtil.shape(ci, PackedVector2Array([c + Vector2(-30, 0) * s, c + Vector2(-18, -35) * s, c + Vector2(18, -35) * s, c + Vector2(30, 0) * s]), Color("f4d69e") if active else Color("d9c4e0"), Color.TRANSPARENT, 0)
		"clothes", "wardrobe":
			box(ci, Rect2(c + Vector2(-32, -35) * s, Vector2(64, 70) * s), Color("c4b9da"), 15 * s)
			box(ci, Rect2(c + Vector2(-27, -30) * s, Vector2(54, 60) * s), Color("dfd5e9"), 12 * s)
			ci.draw_line(c + Vector2(0, -27) * s, c + Vector2(0, 28) * s, Color("bbaacb"), 2 * s, true)
			for x in [-7, 7]:
				DrawUtil.disc(ci, c + Vector2(x, 2) * s, 3 * s, Color("f0cf96"), Color.TRANSPARENT, 0)
		"play", "ball":
			ball(ci, c, 33 * s)
		"love": heart(ci, c, 1.9 * s, Color("e69bac"))
		"none":
			ci.draw_polyline(PackedVector2Array([c + Vector2(0, -24) * s, c + Vector2(0, -8) * s, c + Vector2(-31, 12) * s, c + Vector2(31, 12) * s, c + Vector2(0, -8) * s]), Color("b0a3b8"), 4 * s, true)
		"buy":
			DrawUtil.disc(ci, c + Vector2(-21, 0) * s, 23 * s, Color("f1ce85"), Color("d7b26f"), 2 * s)
			star(ci, c + Vector2(-21, 0) * s, 11 * s, Color("fff1c7"))
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-20, 0) * s, c + Vector2(-4, 15) * s, c + Vector2(23, -17) * s]), Color("83b8a5"), 6 * s, true)


static func accessory(ci: CanvasItem, item: String, rect: Rect2) -> void:
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y) / 80.0
	var outline := Color("927d8f")
	match item:
		"bone", "palha", "touca", "cartola", "pirata":
			var color: Color = {"bone": Color("a1cce8"), "palha": Color("e9ce97"), "touca": Color("dfacb9"), "cartola": Color("b8a8ce"), "pirata": Color("8b91a9")}[item]
			if item == "cartola":
				box(ci, Rect2(c + Vector2(-20, -29) * s, Vector2(40, 43) * s), color, 7 * s)
			elif item == "pirata":
				DrawUtil.shape(ci, PackedVector2Array([c + Vector2(-34, 16) * s, c + Vector2(0, -25) * s, c + Vector2(34, 16) * s]), color, outline, 1.5)
			else:
				oval(ci, c, Vector2(26, 22) * s, color)
			oval(ci, c + Vector2(0, 16) * s, Vector2(35, 7) * s, color.darkened(0.07))
			if item == "touca":
				DrawUtil.disc(ci, c + Vector2(0, -23) * s, 9 * s, Color("fff7ed"), Color.TRANSPARENT, 0)
			else:
				ci.draw_line(c + Vector2(-20, 7) * s, c + Vector2(20, 7) * s, Color("f4e5c9"), 5 * s, true)
		"laco", "gravata":
			var color := Color("e6a2b8") if item == "laco" else Color("91c9bb")
			for side in [-1, 1]:
				DrawUtil.shape(ci, PackedVector2Array([c, c + Vector2(side * 28, -17) * s, c + Vector2(side * 28, 17) * s]), color, outline, 1)
			DrawUtil.disc(ci, c, 7 * s, color.lightened(0.2), Color.TRANSPARENT, 0)
		"oculos":
			for side in [-1, 1]:
				oval(ci, c + Vector2(side * 18, 0) * s, Vector2(17, 13) * s, Color("85829f"), outline, 2)
			ci.draw_line(c + Vector2(-2, -3) * s, c + Vector2(2, -3) * s, outline, 3 * s, true)
		"coroa":
			DrawUtil.shape(ci, PackedVector2Array([c + Vector2(-30, 18) * s, c + Vector2(-30, -20) * s, c + Vector2(-13, -7) * s, c + Vector2(0, -30) * s, c + Vector2(13, -7) * s, c + Vector2(30, -20) * s, c + Vector2(30, 18) * s]), Color("edcf91"), Color("d3af72"), 2)
			DrawUtil.disc(ci, c, 5 * s, Color("e9a8b6"), Color.TRANSPARENT, 0)
		"flores":
			for i in 5:
				var p := c + Vector2(-28 + i * 14, absf(i - 2) * 6) * s
				for k in 5:
					DrawUtil.disc(ci, p + Vector2.from_angle(k * TAU / 5) * 6 * s, 5 * s, Color("edbacb") if i % 2 else Color("e9d59e"), Color.TRANSPARENT, 0)
				DrawUtil.disc(ci, p, 3 * s, Color("fff6df"), Color.TRANSPARENT, 0)
		"cachecol":
			box(ci, Rect2(c + Vector2(-29, -17) * s, Vector2(58, 22) * s), Color("a3c7b5"), 8 * s)
			box(ci, Rect2(c + Vector2(3, -1) * s, Vector2(19, 35) * s), Color("8bbca9"), 6 * s)
		"estrela": star(ci, c, 30 * s, Color("eeb497"))
		"tiara_lua", "halo":
			ci.draw_arc(c + Vector2(0, 10) * s, 29 * s, PI, TAU, 24, Color("bdacd4") if item == "tiara_lua" else Color("e6cf8e"), 5 * s, true)
			star(ci, c + Vector2(0, -21) * s, 13 * s, Color("ecd99d"))
		"fones":
			ci.draw_arc(c, 28 * s, PI, TAU, 24, Color("a3cbd6"), 7 * s, true)
			for side in [-1, 1]:
				oval(ci, c + Vector2(side * 27, 5) * s, Vector2(8, 17) * s, Color("e3b2c8"))
		_: object(ci, "none", rect)
