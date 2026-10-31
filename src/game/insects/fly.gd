class_name Fly
extends Insect
## Mosca Gêmea: na primeira vez que bate na tinta, se DIVIDE em duas mosquinhas menores
## e mais rápidas (cabem em frestas de ~14 px). Bloqueio justo: abrigo sem frestas.

const MINI_RADIUS := 6.5
var mini := false
var _split := false


func _configure() -> void:
	radius = MINI_RADIUS if mini else 10.0
	max_speed = 360.0 if mini else 310.0
	agility = 5.5
	mass = 0.08 if mini else 0.14
	linear_damp = 0.5
	_split = mini


func _behave(_delta: float) -> void:
	_fly_toward(target_point(), 65.0, 1.2)


func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)
	if body is DrawnLine and not _split and not calmed:
		_split = true
		call_deferred("_divide")


func _divide() -> void:
	if not is_instance_valid(level) or is_queued_for_deletion():
		return
	mini = true
	radius = MINI_RADIUS
	max_speed = 360.0 * level.insect_speed
	shape.radius = MINI_RADIUS
	art.radius = MINI_RADIUS
	mass = 0.08
	var twin := Fly.new()
	twin.mini = true
	twin.setup(level, "fly")
	var side := linear_velocity.orthogonal().normalized() if linear_velocity.length() > 1.0 else Vector2.RIGHT
	twin.position = position + side * 14.0
	twin.linear_velocity = side * 160.0
	linear_velocity -= side * 120.0
	level.add_insect(twin)
	Sfx.play("pop", -6.0, 1.6, 0.1)
	Fx.popup_text(level.fx_layer, global_position + Vector2(0, -22), "Dividiu!", Palette.DANGER, 0.7)
