class_name Dragonfly
extends Insect
## Libélula Relâmpago: patrulha em linha reta lá no alto; as asas BRILHAM (aviso) e ela
## dá uma arrancada em zigue-zague até o bichinho. Não contorna obstáculos: bate e volta.
## Bloqueio justo: qualquer abrigo fechado.

enum State { PATROL, GLOW, DASH, BACK }
const GLOW_TIME := 0.55
const DASH_TIME := 0.7
const DASH_SPEED := 620.0
var state := State.PATROL
var _timer := 1.5
var _dash := Vector2.ZERO
var _patrol_dir := 1.0


func _configure() -> void:
	radius = 12.0
	max_speed = 200.0
	agility = 4.0
	mass = 0.3
	linear_damp = 0.3


func _behave(delta: float) -> void:
	_timer -= delta
	var target := target_point()
	match state:
		State.PATROL:
			art.aiming = false
			var y := target.y - 260.0
			if global_position.x > 640.0:
				_patrol_dir = -1.0
			elif global_position.x < 80.0:
				_patrol_dir = 1.0
			_steer_velocity(Vector2(_patrol_dir * max_speed, (y - global_position.y) * 3.0), agility)
			if _timer <= 0.0:
				state = State.GLOW
				_timer = GLOW_TIME
		State.GLOW:
			_steer_velocity(Vector2.ZERO, 6)
			art.aiming = true
			art.aim_progress = 1.0 - _timer / GLOW_TIME
			_dash = (target - global_position).normalized()
			art.aim_vector = _dash * 160.0
			if _timer <= 0.0:
				state = State.DASH
				_timer = DASH_TIME
				art.aiming = false
				art.aim_vector = Vector2.ZERO
				Sfx.play("wasp_dash", -4.0, 1.5)
		State.DASH:
			var zig := _dash.orthogonal() * sin(_timer * 26.0) * 0.6
			linear_velocity = (_dash + zig).normalized() * DASH_SPEED
			if _timer <= 0.0:
				state = State.BACK
				_timer = 1.4
		State.BACK:
			_steer_velocity(Vector2(0, -max_speed), agility)
			if _timer <= 0.0:
				state = State.PATROL
				_timer = 2.4
