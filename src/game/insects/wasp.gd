class_name Wasp
extends Insect
## Vespa Faísca: chega perto, mira (pisca um "!"), e dá uma investida rápida em linha reta.
## Depois da investida fica tonta um instante. Bloqueio justo: barreira apoiada no chão ou
## pesada o bastante para aguentar o tranco — e o aviso "!" dá tempo de prever o ângulo.

enum State { APPROACH, AIM, DASH, RECOVER }

const AIM_TIME := 0.7
const DASH_TIME := 0.35
const DASH_SPEED := 1050.0
const RECOVER_TIME := 0.65
const ATTACK_RANGE := 260.0

var state := State.APPROACH
var _timer := 0.0
var _dash_dir := Vector2.ZERO


func _configure() -> void:
	lured_by_honey = true
	radius = 13.0
	max_speed = 270.0
	agility = 3.0
	mass = 0.72
	linear_damp = 0.3
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE


func _behave(delta: float) -> void:
	_timer -= delta
	var target := predicted_target(0.18)
	match state:
		State.APPROACH:
			art.aiming = false
			art.aim_vector = Vector2.ZERO
			var to := target - global_position
			if to.length() < ATTACK_RANGE:
				state = State.AIM
				_timer = AIM_TIME
				_dash_dir = (target - global_position).normalized()
				Sfx.play("wasp_charge", -6.0, 1.0, 0.1)
			else:
				_fly_toward(target, 40.0, 0.8)
		State.AIM:
			art.aiming = true
			_steer_velocity(Vector2.ZERO, 6.0)
			# Nos últimos 0,25 s a direção fica travada e o aviso não muda.
			if _timer > 0.25:
				_dash_dir = (target - global_position).normalized()
			art.aim_progress = clampf(1 - _timer / AIM_TIME, 0, 1)
			art.aim_vector = _dash_dir * DASH_SPEED * DASH_TIME
			if _timer <= 0.0:
				state = State.DASH
				_timer = DASH_TIME
				art.aiming = false
				linear_velocity = _dash_dir * DASH_SPEED
				Sfx.play("wasp_dash", -4.0, 1.0, 0.1)
		State.DASH:
			_steer_velocity(_dash_dir * DASH_SPEED, 2.0)
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = RECOVER_TIME
		State.RECOVER:
			art.aiming = false
			art.aim_vector = Vector2.ZERO
			art.dazed = true
			_steer_velocity(Vector2.ZERO, 2.0)
			if _timer <= 0.0:
				art.dazed = false
				state = State.APPROACH
				# Obriga um novo desvio após o impacto, sem insistir na rota velha.
				navigator.waypoint = Vector2.INF


func _on_body_entered(body: Node) -> void:
	super(body)
	if state == State.DASH and (body is DrawnLine or body is StaticBody2D):
		state = State.RECOVER
		_timer = RECOVER_TIME
		level.shake(5.0)
