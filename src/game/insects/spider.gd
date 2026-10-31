class_name Spider
extends Insect
## Desce por um fio; se o teto bloquear, recolhe, muda de ponto e tenta outra entrada.
## O deslocamento inteiro respeita colisões e há aviso antes de cada descida.
enum State { TRACK, WARN, DROP, REEL, SHIFT }
var state := State.TRACK
var anchor_y := 0.0
var _anchored := false
var _timer := 0.0
var _blocked := 0.0
var _attempt := 0
var _drop_x := 0.0
var _pass_y := 0.0


func _configure() -> void:
	radius = 11
	max_speed = 165
	agility = 4
	mass = 0.30


func _behave(delta: float) -> void:
	if not _anchored:
		anchor_y = global_position.y
		_anchored = true
	var target := target_point()
	art.aiming = false
	art.aim_vector = Vector2.ZERO
	match state:
		State.TRACK:
			_move_at_anchor(target.x)
			if absf(target.x - global_position.x) < 12: _warn()
		State.WARN:
			_timer -= delta
			_steer_velocity(Vector2.ZERO, 8)
			art.aiming = true
			art.aim_progress = 1 - maxf(0, _timer) / 0.35
			art.aim_vector = Vector2(0, 95)
			if _timer <= 0:
				state = State.DROP
				_blocked = 0
		State.DROP:
			var aim_x := _drop_x if _attempt > 0 and global_position.y < _pass_y else target.x
			_steer_velocity(Vector2(clampf((aim_x - global_position.x) * 2, -45, 45), max_speed), agility)
			if not get_colliding_bodies().is_empty() and linear_velocity.y < 20:
				_blocked += delta
			else:
				_blocked = maxf(0, _blocked - delta)
			if _blocked > 0.35:
				_attempt += 1
				_pass_y = global_position.y + radius * 3
				var side := 1 if (_attempt + tactic_id) % 2 == 0 else -1
				_drop_x = clampf(target.x + side * minf(160, 70 + _attempt * 24), 35, 685)
				state = State.REEL
		State.REEL:
			_steer_velocity(Vector2(0, -max_speed), agility * 1.5)
			if global_position.y < anchor_y + 12: state = State.SHIFT
		State.SHIFT:
			_move_at_anchor(_drop_x)
			if absf(_drop_x - global_position.x) < 12: _warn()
	art.thread = maxf(0, global_position.y - anchor_y)


func _warn() -> void:
	state = State.WARN
	_timer = 0.35


func _move_at_anchor(x: float) -> void:
	_steer_velocity(Vector2(clampf((x - global_position.x) * 4, -max_speed, max_speed), clampf((anchor_y - global_position.y) * 5, -max_speed, max_speed)), agility)
