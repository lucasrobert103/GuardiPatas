class_name Bombardier
extends Insect
## Besouro Pum-Pum: anda pelo chão e, de longe, MIRA (arco pontilhado + "!") e lança uma
## bolinha de fumaça em arco. Bater rápido no bichinho = "Bonk!".
## Bloqueio justo: telhado (o arco vem de cima) — a mira mostra exatamente onde cai.

enum State { WALK, AIM, RECOVER }
const RANGE := 380.0
const AIM_TIME := 0.9
const RECOVER_TIME := 2.2
const FLIGHT := 0.85

var state := State.WALK
var _timer := 1.0
var _launch := Vector2.ZERO


func _configure() -> void:
	radius = 14.0
	max_speed = 70.0
	agility = 5.0
	mass = 1.2
	flying = false


func _behave(delta: float) -> void:
	_timer -= delta
	var target := target_point()
	match state:
		State.WALK:
			art.aiming = false
			art.jump_velocity = Vector2.ZERO
			if _timer <= 0.0 and absf(target.x - global_position.x) < RANGE and _on_ground():
				state = State.AIM
				_timer = AIM_TIME
				_launch = _aim(target)
			else:
				_walk_toward(target, 14.0, 300.0)
		State.AIM:
			_steer_velocity(Vector2(0, linear_velocity.y), 10)
			_launch = _aim(target)
			art.aiming = true
			art.aim_progress = 1.0 - maxf(0.0, _timer) / AIM_TIME
			art.jump_velocity = _launch
			if _timer <= 0.0:
				_fire()
				state = State.RECOVER
				_timer = RECOVER_TIME
		State.RECOVER:
			art.aiming = false
			art.jump_velocity = Vector2.ZERO
			_walk_toward(target, 14.0, 300.0)
			if _timer <= 0.0:
				state = State.WALK


func _muzzle() -> Vector2:
	return global_position + Vector2(0, -radius - 6.0)


## Velocidade de lançamento que cai no alvo depois de FLIGHT segundos (gravidade padrão).
func _aim(target: Vector2) -> Vector2:
	var g := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	var d := target + Vector2(0, -8) - _muzzle()
	return Vector2(d.x / FLIGHT, (d.y - 0.5 * g * FLIGHT * FLIGHT) / FLIGHT)


func _fire() -> void:
	var p := Projectile.new()
	p.setup(level, "puff")
	p.position = _muzzle()
	p.linear_velocity = _launch
	level.add_projectile(p)
	apply_central_impulse(Vector2(-signf(_launch.x) * 60.0, 0))
	art.squash = 1.0
	art.aiming = false
	Sfx.play("pop", -2.0, 0.55, 0.1)
	Fx.dust(level.fx_layer, _muzzle())
