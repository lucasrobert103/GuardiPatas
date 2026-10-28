class_name DrawUtil
## Primitivas de desenho vetorial no estilo do jogo: formas arredondadas com contorno.
## Todo o visual (bichos, insetos, cenário) é desenhado com estas funções em _draw(),
## o que mantém o APK pequeno e permite animação procedural barata.


static func ellipse(center: Vector2, radii: Vector2, rot: float = 0.0, segments: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(segments)
	var c := cos(rot)
	var s := sin(rot)
	for i in segments:
		var a := TAU * float(i) / float(segments)
		var p := Vector2(cos(a) * radii.x, sin(a) * radii.y)
		pts[i] = center + Vector2(p.x * c - p.y * s, p.x * s + p.y * c)
	return pts


static func closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	if pts.size() > 0:
		out.append(pts[0])
	return out


## Polígono preenchido com contorno arredondado.
static func shape(ci: CanvasItem, pts: PackedVector2Array, fill: Color, outline: Color = Palette.OUTLINE, width: float = Palette.OUTLINE_W) -> void:
	if pts.size() < 3:
		return
	ci.draw_colored_polygon(pts, fill)
	if width > 0.0:
		ci.draw_polyline(closed(pts), outline, width, true)


static func oval(ci: CanvasItem, center: Vector2, radii: Vector2, fill: Color, outline: Color = Palette.OUTLINE, width: float = Palette.OUTLINE_W, rot: float = 0.0) -> void:
	shape(ci, ellipse(center, radii, rot), fill, outline, width)


static func disc(ci: CanvasItem, center: Vector2, radius: float, fill: Color, outline: Color = Palette.OUTLINE, width: float = Palette.OUTLINE_W) -> void:
	if width > 0.0:
		ci.draw_circle(center, radius + width * 0.5, outline, true, -1.0, true)
	ci.draw_circle(center, maxf(radius - width * 0.5, 0.5), fill, true, -1.0, true)


## Triângulo de pontas arredondadas (orelhas, espinhos).
static func tri(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, fill: Color, outline: Color = Palette.OUTLINE, width: float = Palette.OUTLINE_W) -> void:
	shape(ci, PackedVector2Array([a, b, c]), fill, outline, width)


## Arco aberto (bocas, sobrancelhas, olhos felizes).
static func arc(ci: CanvasItem, center: Vector2, radius: float, from_angle: float, to_angle: float, color: Color = Palette.OUTLINE, width: float = 3.0) -> void:
	ci.draw_arc(center, radius, from_angle, to_angle, 12, color, width, true)


## Gradiente vertical num retângulo (céu).
static func vgradient(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	ci.draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


## Estrela de 5 pontas (UI e efeitos).
static func star_points(center: Vector2, outer: float, inner: float, rot: float = -PI / 2.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var r := outer if i % 2 == 0 else inner
		var a := rot + PI * float(i) / 5.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


## Nuvem fofa feita de discos.
static func cloud(ci: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var puffs := [Vector2(-0.9, 0.15), Vector2(-0.35, -0.3), Vector2(0.3, -0.4), Vector2(0.9, 0.1), Vector2(0.0, 0.2)]
	var radii := [0.45, 0.6, 0.7, 0.5, 0.6]
	for i in puffs.size():
		ci.draw_circle(center + puffs[i] * size, radii[i] * size, color, true, -1.0, true)
