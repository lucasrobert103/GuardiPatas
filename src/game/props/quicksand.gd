class_name Quicksand
extends Node2D
## Areia movediça: PUXA para baixo, devagar, a linha e as caixas que encostam nela
## (redemoinho visível). Pedras e terreno não afundam.
## cfg: {"type": "quicksand", "rect": [x, y, w, h], "pull": 260}

var rect := Rect2()
var pull := 260.0
var _t := 0.0


func setup(cfg: Dictionary) -> void:
	var r: Array = cfg["rect"]
	rect = Rect2(r[0], r[1], r[2], r[3])
	pull = float(cfg.get("pull", 260.0))
	z_index = 2


## Aplica o puxão nos corpos que têm algum ponto dentro da areia.
func sink(body: RigidBody2D, delta: float) -> void:
	var touch := Vector2.INF
	if body is DrawnLine:
		for q in (body as DrawnLine).points_local:
			var g := body.to_global(q)
			if rect.grow(6.0).has_point(g):
				touch = g
				break
	elif rect.grow(10.0).has_point(body.global_position):
		touch = body.global_position
	if touch == Vector2.INF:
		return
	body.apply_force(Vector2(0, pull * body.mass), touch - body.global_position)
	body.linear_velocity.x = move_toward(body.linear_velocity.x, 0.0, 300.0 * delta)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(rect, Color("d9a95c"), true)
	draw_rect(rect, Palette.OUTLINE, false, 3.0)
	var c := rect.get_center()
	for k in 4:
		var r := 10.0 + k * 12.0
		draw_arc(c, r, _t * (2.0 - k * 0.3) + k, _t * (2.0 - k * 0.3) + k + PI * 1.2, 16, Color("a87a3a"), 3.0, true)
