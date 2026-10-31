class_name Mantis
extends Insect
## Louva-a-deus Garra: encosta na tinta (ou numa caixa), avisa com "!" e LEVANTA a barreira
## com as garras, SEGURANDO-a no alto um instante enquanto passa por baixo.
## Pedra no caminho? Ela agacha (aviso) e dá um pulo por cima.
## Bloqueio justo: Tinta Firme, pedras segurando as pontas ou paredes de pedra altas.

const GRAB_TIME := 0.75
const HOLD_TIME := 0.9
## Aceleração para cima aplicada na barreira enquanto segura (vence a gravidade).
const HOLD_ACCEL := 1500.0
const RECOVER := 1.6
const HOP_WAIT := 0.35
const HOP_VY := 650.0
const HOP_VX := 230.0

var _grab := 0.0
var _hold := 0.0
var _cooldown := 0.0
var _held: RigidBody2D
var _side := 1.0
var _blocked := 0.0


func _configure() -> void:
	radius = 15.0
	max_speed = 80.0
	agility = 5.0
	mass = 2.5
	flying = false


func _behave(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _hold > 0.0 and is_instance_valid(_held):
		_hold -= delta
		art.aiming = false
		art.squash = 0.4
		var grip := global_position + Vector2(-_side * radius, -radius)
		_held.apply_force(Vector2(_side * 0.25, -1.0) * _held.mass * HOLD_ACCEL, grip - _held.global_position)
		_walk_toward(target_point(), 16.0, 900.0)
		if _hold <= 0.0:
			_held = null
			_cooldown = RECOVER
		return
	var barrier: RigidBody2D
	for body in get_colliding_bodies():
		if (body is DrawnLine or body is Crate) and not (body as RigidBody2D).freeze:
			barrier = body
			break
	if barrier == null or _cooldown > 0.0:
		_grab = 0.0
		art.aiming = false
		art.aim_progress = 0.0
		var target := target_point()
		_walk_toward(target, 16.0, 700.0)
		# pedra ou degrau alto à frente (ou parado longe do alvo): pulo anunciado
		var dir := signf(target.x - global_position.x)
		var stuck := absf(linear_velocity.x) < 12.0 and absf(target.x - global_position.x) > radius * 2.0
		if barrier == null and (stuck or _terrain_ahead(dir)) and _on_ground():
			_blocked += delta
			art.aiming = true
			art.aim_progress = clampf(_blocked / HOP_WAIT, 0.0, 1.0)
			art.jump_velocity = Vector2(dir * HOP_VX, -HOP_VY)
			_steer_velocity(Vector2(0, linear_velocity.y), 8)
			if _blocked >= HOP_WAIT:
				_blocked = 0.0
				linear_velocity = Vector2(dir * HOP_VX, -HOP_VY)
				art.aiming = false
				art.jump_velocity = Vector2.ZERO
				art.squash = 1.0
		else:
			_blocked = 0.0
			art.jump_velocity = Vector2.ZERO
		return
	_grab += delta
	art.aiming = true
	art.aim_progress = minf(1.0, _grab / GRAB_TIME)
	_steer_velocity(Vector2(0, linear_velocity.y), 8)
	if _grab >= GRAB_TIME:
		_side = signf(global_position.x - target_point().x)
		_held = barrier
		_hold = HOLD_TIME
		_grab = 0.0
		art.aiming = false
		art.squash = 1.0
		Sfx.play("bonk", -6.0, 0.8, 0.1)
		Fx.popup_text(level.fx_layer, global_position + Vector2(0, -34), "Upa!", Palette.DANGER, 0.7)


## Terreno (pedra, paredão) logo à frente, na altura do corpo.
func _terrain_ahead(dir: float) -> bool:
	if dir == 0.0:
		return false
	var space := get_world_2d().direct_space_state
	for dy in [-radius * 0.4, -radius * 1.0]:
		var from := global_position + Vector2(0, dy)
		var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(dir * (radius + 70.0), 0), Layers.TERRAIN, [get_rid()])
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and hit["collider"] is Terrain:
			return true
	return false
