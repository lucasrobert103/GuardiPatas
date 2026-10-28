class_name Background
extends Node2D
## Cenário de fundo em camadas (céu, sol/lua, colinas, elementos do mundo, nuvens).
## Desenhado uma vez; só as nuvens se movem (nós filhos), então o custo por quadro é baixo.

const AREA := Rect2(-700, -800, 2120, 2900)

var world_id := 1


func setup(p_world: int) -> void:
	world_id = p_world
	z_index = -100
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + world_id
	var cloud_count := 4 if world_id != 5 else 0
	for i in cloud_count:
		var c := CloudPuff.new()
		c.position = Vector2(rng.randf_range(-200, 900), rng.randf_range(120, 520))
		c.size = rng.randf_range(36, 60)
		c.speed = rng.randf_range(6, 16)
		add_child(c)


func _draw() -> void:
	var pal := Palette.world(world_id)
	DrawUtil.vgradient(self, AREA, pal["sky_top"], pal["sky_bottom"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 42 + world_id
	if world_id == 5:
		for i in 60:
			var p := Vector2(rng.randf_range(-300, 1020), rng.randf_range(-300, 700))
			draw_circle(p, rng.randf_range(1.0, 2.6), Color(1, 1, 0.9, rng.randf_range(0.4, 0.9)), true, -1.0, true)
		draw_circle(Vector2(560, 230), 80.0, Color(1, 1, 0.85, 0.12), true, -1.0, true)
		DrawUtil.disc(self, Vector2(560, 230), 46.0, Color("fff6cf"), Color(1, 1, 1, 0.0), 0.0)
		# crescente: a "sombra" usa a cor do céu naquela altura
		var k := (220.0 - AREA.position.y) / AREA.size.y
		DrawUtil.disc(self, Vector2(582, 218), 40.0, Color(pal["sky_top"]).lerp(pal["sky_bottom"], k), Color(1, 1, 1, 0.0), 0.0)
	else:
		draw_circle(Vector2(590, 230), 90.0, Color(1, 0.95, 0.6, 0.25), true, -1.0, true)
		DrawUtil.disc(self, Vector2(590, 230), 52.0, Color("ffe066"), Color("f5b83d"), 4.0)
	_hills(pal["far"], 760.0, 140.0, 0.006, 1.3)
	match world_id:
		2:
			for i in 9:
				_tree(Vector2(-200 + i * 140 + rng.randf_range(-30, 30), 800 + rng.randf_range(-20, 30)), rng.randf_range(0.8, 1.3), Color(pal["near"]).darkened(0.1))
		3:
			for i in 4:
				_mesa(Vector2(-150 + i * 330 + rng.randf_range(-40, 40), 830), rng.randf_range(0.8, 1.2), Color(pal["near"]).lightened(0.05))
		4:
			draw_rect(Rect2(-700, 800, 2120, 120), Color(0.55, 0.78, 0.95, 0.6), true)
			for i in 10:
				var x := rng.randf_range(-300, 1000)
				draw_line(Vector2(x, 830 + i * 8), Vector2(x + 60, 830 + i * 8), Color(1, 1, 1, 0.5), 3.0, true)
	_hills(pal["near"], 880.0, 90.0, 0.011, 0.4)
	if world_id == 5:
		_tent(Vector2(110, 930), Color("e07a5f"))
		_tent(Vector2(640, 940), Color("81b29a"))


func _hills(color: Color, base_y: float, amp: float, freq: float, phase: float) -> void:
	var pts := PackedVector2Array()
	var x := AREA.position.x
	while x <= AREA.end.x:
		pts.append(Vector2(x, base_y - amp * (0.5 + 0.5 * sin(x * freq + phase)) - amp * 0.3 * sin(x * freq * 2.3)))
		x += 40.0
	pts.append(Vector2(AREA.end.x, AREA.end.y))
	pts.append(Vector2(AREA.position.x, AREA.end.y))
	draw_colored_polygon(pts, color)
	var top := pts.slice(0, pts.size() - 2)
	draw_polyline(top, Color(color).darkened(0.18), 4.0, true)


func _tree(base: Vector2, s: float, color: Color) -> void:
	draw_rect(Rect2(base + Vector2(-8, -60) * s, Vector2(16, 70) * s), Color("8a5a39").darkened(0.2), true)
	for k in 3:
		var y := -60.0 - k * 34.0
		var w := 60.0 - k * 14.0
		draw_colored_polygon(PackedVector2Array([base + Vector2(-w, y + 20) * s, base + Vector2(w, y + 20) * s, base + Vector2(0, y - 46) * s]), color.lightened(k * 0.05))


func _mesa(base: Vector2, s: float, color: Color) -> void:
	var pts := PackedVector2Array([base + Vector2(-120, 60) * s, base + Vector2(-90, -120) * s, base + Vector2(80, -130) * s, base + Vector2(130, 60) * s])
	draw_colored_polygon(pts, color)
	draw_line(base + Vector2(-90, -120) * s, base + Vector2(80, -130) * s, Color(color).lightened(0.2), 6.0, true)


func _tent(base: Vector2, color: Color) -> void:
	var o := Palette.OUTLINE
	DrawUtil.tri(self, base + Vector2(-80, 40), base + Vector2(80, 40), base + Vector2(0, -80), color, o, 4.0)
	DrawUtil.tri(self, base + Vector2(-20, 40), base + Vector2(20, 40), base + Vector2(0, -30), Color(color).darkened(0.35), o, 3.0)


class CloudPuff:
	extends Node2D
	var size := 40.0
	var speed := 10.0

	func _process(delta: float) -> void:
		position.x += speed * delta
		if position.x > 1100.0:
			position.x = -380.0

	func _draw() -> void:
		DrawUtil.cloud(self, Vector2.ZERO, size, Color(1, 1, 1, 0.85))
