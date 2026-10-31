class_name Terrain
extends StaticBody2D
## Terreno estático a partir de um polígono do levels.json.
## Estilos: "ground" (terra com grama), "stone", "wood", "glass" (aquário da Lulu).

var poly := PackedVector2Array()
var style := "ground"
var world_id := 1
var _grass_edges: Array = []
var _decor: Array = []


func setup(p_poly: PackedVector2Array, p_style: String, p_world: int) -> void:
	poly = p_poly
	style = p_style
	world_id = p_world
	collision_layer = Layers.TERRAIN
	collision_mask = 0
	var mat := PhysicsMaterial.new()
	mat.friction = 0.95
	if style == "glass":
		mat.friction = 0.4
	elif style == "ice":
		mat.friction = 0.04
	physics_material_override = mat
	var cp := CollisionPolygon2D.new()
	cp.polygon = poly
	add_child(cp)
	_find_top_edges()


static func make_circle(center: Vector2, r: float) -> PackedVector2Array:
	return DrawUtil.ellipse(center, Vector2(r, r), 0.0, 20)


func _find_top_edges() -> void:
	_grass_edges.clear()
	_decor.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(poly)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var e := b - a
		if e.length() < 4.0:
			continue
		var n := e.orthogonal().normalized()
		var mid := (a + b) * 0.5
		if Geometry2D.is_point_in_polygon(mid + n * 3.0, poly):
			n = -n
		if n.y < -0.55:
			_grass_edges.append([a, b])
			if style == "ground":
				var count := int(e.length() / 70.0)
				for k in count:
					var p := a.lerp(b, rng.randf_range(0.05, 0.95))
					if absf(p.x - 360.0) < 520.0:
						_decor.append([p, rng.randi_range(0, 3), rng.randf_range(0.8, 1.2)])


func _draw() -> void:
	var pal := Palette.world(world_id)
	match style:
		"ice":
			DrawUtil.shape(self, poly, Palette.ICE)
			var ri := _bounds()
			for k in 3:
				var x0 := ri.position.x + ri.size.x * (0.2 + 0.25 * k)
				draw_line(Vector2(x0, ri.position.y + 10), Vector2(x0 + 24, ri.position.y + 4), Color(1, 1, 1, 0.9), 4.0, true)
		"stone":
			DrawUtil.shape(self, poly, Palette.STONE)
			var rb := _bounds()
			draw_line(rb.position + Vector2(rb.size.x * 0.25, rb.size.y * 0.22), rb.position + Vector2(rb.size.x * 0.5, rb.size.y * 0.14), Color(1, 1, 1, 0.6), 4.0, true)
		"wood":
			DrawUtil.shape(self, poly, Palette.WOOD)
			var r := _bounds()
			var y := r.position.y + 12.0
			while y < r.end.y - 6.0:
				draw_line(Vector2(r.position.x + 6, y), Vector2(r.end.x - 6, y), Palette.WOOD_DARK, 2.0, true)
				y += 14.0
		"glass":
			draw_colored_polygon(poly, Color(0.85, 0.95, 1.0, 0.35))
			draw_polyline(DrawUtil.closed(poly), Color("6fb4d8"), 5.0, true)
		_:
			DrawUtil.shape(self, poly, pal["dirt"])
			# pedrinhas na terra
			var r := _bounds()
			var rng := RandomNumberGenerator.new()
			rng.seed = 77 + hash(poly)
			for k in int(r.size.x * minf(r.size.y, 500.0) / 9000.0):
				var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y + 30.0, minf(r.end.y, r.position.y + 500.0)))
				if Geometry2D.is_point_in_polygon(p, poly):
					draw_circle(p, rng.randf_range(3.0, 7.0), Color(pal["dirt"]).darkened(0.12), true, -1.0, true)
			for e in _grass_edges:
				# faixa de grama desenhada para DENTRO do terreno: a superfície visual
				# coincide com a superfície de colisão
				draw_line(e[0] + Vector2(0, 8), e[1] + Vector2(0, 8), Palette.OUTLINE, 22.0 + Palette.OUTLINE_W, true)
			for e in _grass_edges:
				draw_line(e[0] + Vector2(0, 9), e[1] + Vector2(0, 9), pal["ground"], 20.0, true)
				draw_circle(e[0] + Vector2(0, 9), 10.0, pal["ground"], true, -1.0, true)
				draw_circle(e[1] + Vector2(0, 9), 10.0, pal["ground"], true, -1.0, true)
			for d in _decor:
				_draw_decor(d[0], d[1], d[2], pal)


func _draw_decor(p: Vector2, kind: int, s: float, pal: Dictionary) -> void:
	var o := Palette.OUTLINE
	if world_id in Palette.SNOW_WORLDS:
		_draw_snow_decor(p, kind, s)
		return
	if world_id in Palette.SAND_WORLDS:
		_draw_sand_decor(p, kind, s)
		return
	match kind:
		0:
			# tufo de grama
			for k in 3:
				var dx := (k - 1) * 6.0 * s
				DrawUtil.tri(self, p + Vector2(dx - 4, -8), p + Vector2(dx + 4, -8), p + Vector2(dx + (k - 1) * 3.0, -22 * s), Color(pal["ground"]).darkened(0.1), o, 2.0)
		1, 2:
			# florzinha
			var c := p + Vector2(0, -20 * s)
			draw_line(p + Vector2(0, -8), c, Palette.GRASS_DARK, 3.0, true)
			var col: Color = pal["accent"] if kind == 1 else Palette.WHITE
			for k in 5:
				DrawUtil.disc(self, c + Vector2.from_angle(TAU * k / 5.0) * 5.0 * s, 4.0 * s, col, o, 1.5)
			DrawUtil.disc(self, c, 3.5 * s, Palette.GOLD, o, 1.5)
		3:
			# pedrinha
			DrawUtil.oval(self, p + Vector2(0, -10), Vector2(9, 6) * s, Palette.STONE, o, 2.5)


func _draw_snow_decor(p: Vector2, kind: int, s: float) -> void:
	var o := Palette.OUTLINE
	match kind:
		0, 1:
			# montinho de neve
			DrawUtil.oval(self, p + Vector2(0, -6), Vector2(16, 9) * s, Color.WHITE, Color("c9d6ea"), 2.5)
		2:
			# cristal de gelo
			var c := p + Vector2(0, -16 * s)
			for k in 3:
				var d := Vector2.from_angle(PI * k / 3.0) * 9.0 * s
				draw_line(c - d, c + d, Color("8fd3ff"), 3.0, true)
		3:
			DrawUtil.oval(self, p + Vector2(0, -10), Vector2(9, 6) * s, Palette.STONE, o, 2.5)


func _draw_sand_decor(p: Vector2, kind: int, s: float) -> void:
	var o := Palette.OUTLINE
	match kind:
		0:
			if world_id == 8:
				# alga balançando
				var pts := PackedVector2Array()
				for k in 5:
					pts.append(p + Vector2(sin(k * 1.3) * 5.0, -8.0 - k * 9.0 * s))
				draw_polyline(pts, Color("3fae78"), 6.0, true)
			else:
				for k in 3:
					var dx := (k - 1) * 6.0 * s
					draw_line(p + Vector2(dx, -8), p + Vector2(dx + (k - 1) * 4.0, -24 * s), Color("9ab35a"), 3.0, true)
		1:
			# concha
			var c := p + Vector2(0, -12)
			var pts := PackedVector2Array()
			for k in 9:
				var a := PI + PI * k / 8.0
				pts.append(c + Vector2(cos(a) * 10.0, sin(a) * 9.0) * s)
			pts.append(c + Vector2(0, 4) * s)
			DrawUtil.shape(self, pts, Color("ffc4b8"), o, 2.0)
			for k in 3:
				draw_line(c + Vector2(0, 3) * s, c + Vector2(-6 + k * 6, -7) * s, Color("e89a8c"), 1.5, true)
		2:
			# estrela-do-mar
			DrawUtil.shape(self, DrawUtil.star_points(p + Vector2(0, -12), 10.0 * s, 5.0 * s), Color("ff8a65"), o, 2.0)
		3:
			DrawUtil.oval(self, p + Vector2(0, -10), Vector2(9, 6) * s, Palette.STONE, o, 2.5)


func _bounds() -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		r = r.expand(p)
	return r
