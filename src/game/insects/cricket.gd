class_name Cricket
extends Insect
## Grilo Saltitante: anda pelo chão e, a cada 1,5 s, dá um PULO de até ~160 px.
## Paredes e tendas não seguram; só um abrigo com teto (ou um vão largo).

const JUMP_EVERY := 1.5
const JUMP_VY := 560.0
const JUMP_VX := 170.0

var _jump_cd := 0.8


func _configure() -> void:
	radius = 9.0
	max_speed = 70.0
	agility = 6.0
	mass = 0.2
	flying = false


func _behave(delta: float) -> void:
	_jump_cd -= delta
	var target := target_point()
	_walk_toward(target, 18.0, 140.0)
	if _jump_cd <= 0.0 and _on_ground():
		_jump_cd = JUMP_EVERY
		var dir := signf(target.x - global_position.x)
		linear_velocity = Vector2(dir * JUMP_VX, -JUMP_VY)
		art.squash = 1.0
		Sfx.play("pop", -14.0, 1.6, 0.2, 0.1)
