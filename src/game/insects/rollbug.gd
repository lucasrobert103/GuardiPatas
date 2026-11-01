class_name Rollbug
extends Insect
## Besouro-tatu: anda devagar; perto do alvo ENCOLHE (aviso) e sai rolando bem rápido.
## Batendo forte na tinta, abre um buraco nela e passa. Pedra e terreno ele não quebra.
## Bloqueio justo: paredes de pedra, rampas que o desviam ou camadas extras.

enum State { WALK, CURL, ROLL, DIZZY }
const CURL_TIME := 0.55
const ROLL_TIME := 1.6
const ROLL_SPEED := 380.0
const BREAK_SPEED := 200.0

var state := State.WALK
var _timer := 0.8
var _dir := 1.0


func _configure() -> void:
	radius = 13.0
	max_speed = 60.0
	agility = 5.0
	mass = 1.4
	flying = false


func _behave(delta: float) -> void:
	_timer -= delta
	var target := target_point()
	match state:
		State.WALK:
			art.excited = false
			_walk_toward(target, 10.0, 260.0)
			if _timer <= 0.0 and absf(target.x - global_position.x) < 420.0 and _on_ground():
				state = State.CURL
				_timer = CURL_TIME
				_dir = signf(target.x - global_position.x)
		State.CURL:
			art.aiming = true
			art.aim_progress = 1.0 - _timer / CURL_TIME
			art.aim_vector = Vector2(_dir * 140.0, 0)
			_steer_velocity(Vector2(0, linear_velocity.y), 10)
			if _timer <= 0.0:
				state = State.ROLL
				_timer = ROLL_TIME
				art.aiming = false
				art.aim_vector = Vector2.ZERO
				art.excited = true
				Sfx.play("beetle_step", -2.0, 1.6)
		State.ROLL:
			linear_velocity.x = move_toward(linear_velocity.x, _dir * ROLL_SPEED, 1400.0 * delta)
			art.spin += _dir * delta * 14.0
			for b in get_colliding_bodies():
				if b is DrawnLine and absf(linear_velocity.x) > BREAK_SPEED * 0.6:
					add_collision_exception_with(b)
					(b as DrawnLine).add_hole(global_position)
					level.shake(4.0)
					Sfx.play("bonk", -2.0, 0.6)
					Fx.popup_text(level.fx_layer, global_position + Vector2(0, -26), "Crack!", Palette.WOOD_DARK, 0.8)
					_timer = minf(_timer, 0.3)
			if _timer <= 0.0:
				state = State.DIZZY
				_timer = 1.2
				daze(1.0)
		State.DIZZY:
			art.excited = false
			if _timer <= 0.0:
				state = State.WALK
				_timer = 1.6
