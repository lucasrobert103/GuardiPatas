class_name Cicada
extends Insect
## Cigarra Cantora: fica rondando a uns 220 px do bichinho, CARREGA o canto (anéis + "!")
## e solta uma onda de som que EMPURRA linhas e caixas soltas para longe dela; depois
## mergulha. Bloqueio justo: Tinta Firme ou abrigo travado no cenário (pedras, paredes).

enum State { HOVER, CHARGE, DIVE }
const HOVER_DIST := 220.0
const CHARGE_TIME := 1.0
const DIVE_TIME := 1.3
const WAVE_RADIUS := 300.0
const WAVE_IMPULSE := 950.0

var state := State.HOVER
var _timer := 1.6
var wave := 0.0


func _configure() -> void:
	radius = 14.0
	max_speed = 170.0
	agility = 3.0
	mass = 0.5
	linear_damp = 0.4


func _behave(delta: float) -> void:
	_timer -= delta
	wave = maxf(0.0, wave - delta * 2.5)
	art.wave = wave
	var target := target_point()
	match state:
		State.HOVER:
			art.aiming = false
			var to := global_position - target
			var hover := target + to.normalized() * HOVER_DIST if to.length() > 1.0 else target + Vector2(0, -HOVER_DIST)
			hover.y = minf(hover.y, target.y - 120.0)
			_fly_toward(hover, 30.0, 0.8)
			if _timer <= 0.0 and global_position.distance_to(target) < HOVER_DIST * 1.5:
				state = State.CHARGE
				_timer = CHARGE_TIME
		State.CHARGE:
			_steer_velocity(Vector2.ZERO, 6)
			art.aiming = true
			art.aim_progress = 1.0 - maxf(0.0, _timer) / CHARGE_TIME
			if _timer <= 0.0:
				_scream()
				state = State.DIVE
				_timer = DIVE_TIME
		State.DIVE:
			art.aiming = false
			_fly_toward(target, 40.0, 1.0)
			if _timer <= 0.0:
				state = State.HOVER
				_timer = 2.4


func _scream() -> void:
	wave = 1.0
	art.squash = 1.0
	Sfx.play("wasp_dash", -2.0, 0.5, 0.1)
	level.shake(3.0)
	var bodies: Array = []
	bodies.append_array(level.lines)
	bodies.append_array(level.props)
	for b in bodies:
		if not is_instance_valid(b) or (b as RigidBody2D).freeze:
			continue
		var p := _closest_point(b)
		var d := p.distance_to(global_position)
		if d > WAVE_RADIUS:
			continue
		# a onda varre para o lado e levanta um pouco (não adianta empurrar contra o chão)
		var side := signf(p.x - global_position.x)
		if side == 0.0:
			side = 1.0
		var dir := Vector2(side, -0.3).normalized()
		var k := 1.0 - d / WAVE_RADIUS
		(b as RigidBody2D).apply_impulse(dir * WAVE_IMPULSE * (0.35 + 0.65 * k), p - (b as Node2D).global_position)


func _closest_point(b: Node2D) -> Vector2:
	if b is DrawnLine:
		var best := b.global_position
		var bd := INF
		for q in (b as DrawnLine).points_local:
			var g := b.to_global(q)
			var d := g.distance_squared_to(global_position)
			if d < bd:
				bd = d
				best = g
		return best
	return b.global_position
