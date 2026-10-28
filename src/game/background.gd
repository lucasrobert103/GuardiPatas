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
	if world_id == 8:
		_draw_sea(pal, rng)
		return
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
	if world_id == 6:
		_mountains(pal)
	elif world_id == 7:
		_beach(pal, rng)
		return
	else:
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


func _mountains(pal: Dictionary) -> void:
	# picos nevados em duas camadas
	var peaks := [[Vector2(-120, 860), 330.0, 260.0], [Vector2(260, 860), 420.0, 330.0], [Vector2(640, 860), 380.0, 280.0], [Vector2(980, 860), 300.0, 240.0]]
	for pk in peaks:
		var base: Vector2 = pk[0]
		var h: float = pk[2]
		var w: float = pk[1]
		var tip := base + Vector2(0, -h)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.6, 0), tip, base + Vector2(w * 0.6, 0)]), pal["far"])
		var cap := PackedVector2Array([tip, tip + Vector2(w * 0.17, h * 0.28), tip + Vector2(w * 0.06, h * 0.22), tip + Vector2(-w * 0.04, h * 0.3), tip + Vector2(-w * 0.17, h * 0.28)])
		draw_colored_polygon(cap, Color.WHITE)
	_hills(pal["near"], 900.0, 70.0, 0.009, 2.0)
	# pinheirinhos com neve
	var rng := RandomNumberGenerator.new()
	rng.seed = 606
	for i in 7:
		var b := Vector2(-150 + i * 170 + rng.randf_range(-30, 30), 905 + rng.randf_range(-10, 10))
		_tree(b, rng.randf_range(0.6, 0.9), Color("5f8f88"))
		draw_colored_polygon(PackedVector2Array([b + Vector2(-20, -126), b + Vector2(0, -150), b + Vector2(20, -126)]), Color.WHITE)


func _beach(pal: Dictionary, rng: RandomNumberGenerator) -> void:
	# mar no horizonte com ondinhas, barquinho e coqueiros
	draw_rect(Rect2(-700, 760, 2120, 260), pal["far"], true)
	draw_rect(Rect2(-700, 760, 2120, 6), Color(1, 1, 1, 0.6), true)
	for i in 14:
		var x := rng.randf_range(-300, 1000)
		var y := rng.randf_range(790, 900)
		draw_arc(Vector2(x, y), 12.0, PI * 1.1, PI * 1.9, 8, Color(1, 1, 1, 0.55), 3.0, true)
	var boat := Vector2(170, 780)
	DrawUtil.shape(self, PackedVector2Array([boat + Vector2(-40, 0), boat + Vector2(40, 0), boat + Vector2(28, 16), boat + Vector2(-28, 16)]), Color("e07a5f"), Palette.OUTLINE, 3.0)
	DrawUtil.tri(self, boat + Vector2(-2, -4), boat + Vector2(-2, -54), boat + Vector2(26, -8), Color.WHITE, Palette.OUTLINE, 3.0)
	_hills(pal["ground"].darkened(0.06), 930.0, 30.0, 0.008, 1.0)
	_palm(Vector2(30, 960), 1.0)
	_palm(Vector2(690, 950), 0.85)


func _palm(base: Vector2, s: float) -> void:
	var trunk := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		trunk.append(base + Vector2(sin(t * 1.6) * 30.0 * s, -t * 230.0 * s))
	draw_polyline(trunk, Palette.OUTLINE, 22.0 * s, true)
	draw_polyline(trunk, Color("b57a45"), 16.0 * s, true)
	var top := trunk[trunk.size() - 1]
	for a in [-2.6, -2.0, -1.2, -0.5, 0.2]:
		var d := Vector2.from_angle(a)
		DrawUtil.oval(self, top + d * 55.0 * s, Vector2(60, 14) * s, Color("4fae5a"), Palette.OUTLINE, 3.0, a)


func _draw_sea(pal: Dictionary, rng: RandomNumberGenerator) -> void:
	# fundo do mar: raios de luz, bolhas, algas e corais ao longe
	for i in 6:
		var x := -200.0 + i * 220.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, -800), Vector2(x + 90, -800), Vector2(x + 260, 1100), Vector2(x + 140, 1100)]), Color(1, 1, 1, 0.06))
	for i in 40:
		var p := Vector2(rng.randf_range(-300, 1020), rng.randf_range(-200, 900))
		draw_arc(p, rng.randf_range(3.0, 8.0), 0.0, TAU, 12, Color(1, 1, 1, 0.35), 2.0, true)
	_hills(pal["far"], 860.0, 110.0, 0.007, 0.8)
	for i in 10:
		var b := Vector2(-200 + i * 130 + rng.randf_range(-30, 30), 930)
		var pts := PackedVector2Array()
		for k in 8:
			pts.append(b + Vector2(sin(k * 0.9 + i) * 10.0, -k * 22.0))
		draw_polyline(pts, Color("2f9e6e"), 10.0, true)
	_hills(pal["near"], 940.0, 50.0, 0.012, 2.4)
	for i in 5:
		var c := Vector2(-100 + i * 220 + rng.randf_range(-40, 40), 950)
		for k in 3:
			DrawUtil.disc(self, c + Vector2(-14 + k * 14, -10 - (k % 2) * 12), 12.0, Color("ff8a8a").lerp(Color("ffb3c7"), k * 0.3), Color(0, 0, 0, 0), 0.0)


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
