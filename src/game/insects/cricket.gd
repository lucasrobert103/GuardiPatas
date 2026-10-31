class_name Cricket
extends Insect
## Escolhe pular perto de parede, beirada ou alvo elevado, com preparação visível.
## Teto e vãos maiores que o alcance físico continuam sendo defesas.
const JUMP_EVERY := 1.1
const JUMP_VY := 560.0
const JUMP_VX := 210.0
const WINDUP := 0.3
var _jump_cd := 0.6
var _windup := 0.0
var _jump_direction := 1.0


func _configure() -> void:
	radius = 9
	max_speed = 100
	agility = 6
	mass = 0.32
	flying = false


func _behave(delta: float) -> void:
	_jump_cd -= delta
	var target := target_point()
	art.aiming = false
	art.jump_velocity = Vector2.ZERO
	if _windup > 0:
		_windup -= delta
		art.aiming = true
		art.aim_progress = 1 - maxf(0, _windup) / WINDUP
		art.jump_velocity = Vector2(_jump_direction * JUMP_VX, -JUMP_VY)
		_steer_velocity(Vector2(0, linear_velocity.y), 12)
		if not _on_ground():
			_windup = 0
			return
		if _windup <= 0:
			linear_velocity = art.jump_velocity
			_jump_cd = JUMP_EVERY
			art.aiming = false
			art.squash = 1
			Sfx.play("pop", -14, 1.6, 0.2, 0.1)
		return
	_walk_toward(target, 18, 160)
	if _jump_cd <= 0 and _on_ground() and _needs_jump(target):
		_windup = WINDUP
		_jump_direction = signf(target.x - global_position.x)
		if _jump_direction == 0: _jump_direction = 1


func _needs_jump(target: Vector2) -> bool:
	var direction := signf(target.x - global_position.x)
	var space := get_world_2d().direct_space_state
	var ahead := global_position + Vector2(direction * 54, 0)
	var wall := PhysicsRayQueryParameters2D.create(global_position, ahead, InsectNavigator.MASK, [get_rid()])
	var floor_query := PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0, radius + 35), InsectNavigator.MASK, [get_rid()])
	return not space.intersect_ray(wall).is_empty() or space.intersect_ray(floor_query).is_empty() or target.y < global_position.y - 35
