class_name Boss
extends Node2D
## Chefões sem violência dos mundos 6–8. Todos avisam antes de agir (1 s de "!" visível):
##  owl       — Coruja Nevasca: bate as asas e derruba bolas de neve nos X marcados no chão.
##  crab_king — Caranguejo Rei: mira (arco pontilhado) e arremessa conchas no bichinho mais perto.
##  octopus   — Polvo Gigante: incha e SUGA linhas, caixas e insetos para perto dele, depois
##              solta uma nuvem de tinta (só visual). Se um bichinho chegar até ele: abraço apertado!
## Bloqueio justo: abrigo firme com teto (neve), parede do lado do rei (conchas),
## abrigo travado embaixo das pedras (sucção).

const WARN_TIME := 1.0

var level: Level
var kind := "owl"
var home := Vector2(360, 300)
var sway := 120.0
var every := 3.0
var running := false
var _t := 0.0
var _cycle_t := 0.0
var _phase := "idle"   # idle | warn | act
var _phase_t := 0.0
var _cycles := 0
var _marks: Array[Vector2] = []     # owl: onde a neve vai cair (global)
var _ground_y: Array[float] = []
var _aim := Vector2.ZERO           # crab_king: alvo (global)
var _launch_v := Vector2.ZERO
var _ink := 0.0                    # octopus: nuvem de tinta
var _ink_pos := Vector2.ZERO
var _flap := 0.0

const SUCK_TIME := 1.4
const SUCK_ACCEL := 1500.0
const HUG_RADIUS := 115.0


func setup(p_level: Level, cfg: Dictionary) -> void:
	level = p_level
	kind = str(cfg.get("kind", "owl"))
	home = Vector2(cfg.get("pos", [360, 300])[0], cfg.get("pos", [360, 300])[1])
	sway = float(cfg.get("sway", 120.0 if kind != "crab_king" else 40.0))
	every = float(cfg.get("every", 3.0 if kind != "octopus" else 4.2))
	_cycle_t = float(cfg.get("delay", 1.2))
	position = home
	z_index = 20


func begin() -> void:
	running = true


func display_name() -> String:
	return {"owl": "Coruja Nevasca", "crab_king": "Caranguejo Rei", "octopus": "Polvo Gigante"}.get(kind, "Chefão")


func _physics_process(delta: float) -> void:
	if not running or level == null:
		return
	_t += delta
	_flap = maxf(_flap - delta * 2.0, 0.0)
	_ink = maxf(_ink - delta * 0.35, 0.0)
	match kind:
		"owl":
			position = home + Vector2(sin(_t * 0.6) * sway * 0.3, sin(_t * 1.7) * 6.0)
		"crab_king":
			position = home + Vector2(sin(_t * 0.9) * sway, 0)
		"octopus":
			position = home + Vector2(sin(_t * 0.5) * sway, sin(_t * 1.1) * 18.0)
	if level.state != Level.State.RUNNING:
		_phase = "idle"
		return
	if kind == "octopus":
		_check_hug()
	_phase_t += delta
	match _phase:
		"idle":
			_cycle_t -= delta
			if _cycle_t <= 0.0:
				_phase = "warn"
				_phase_t = 0.0
				_prepare()
		"warn":
			if kind == "crab_king":
				_aim_at_target()
			if _phase_t >= WARN_TIME:
				_phase = "act"
				_phase_t = 0.0
				_act()
		"act":
			if kind == "octopus":
				_suck(delta)
				if _phase_t >= SUCK_TIME:
					_ink = 1.0
					_ink_pos = global_position
					Sfx.play("bloop", -2.0, 0.5)
					_end_cycle()
			else:
				_end_cycle()


func _end_cycle() -> void:
	_phase = "idle"
	_cycle_t = every - WARN_TIME
	_cycles += 1


func _target() -> Animal:
	var best: Animal = null
	var bd := INF
	for a in level.animals:
		if is_instance_valid(a):
			var d := a.global_position.distance_to(global_position)
			if d < bd:
				bd = d
				best = a
	return best


func _prepare() -> void:
	Sfx.play("wasp_charge", -6.0, 0.6 if kind != "owl" else 0.8)
	match kind:
		"owl":
			_marks.clear()
			_ground_y.clear()
			var a := _target()
			var ax := a.global_position.x if a != null else 360.0
			var offs: Array = [-50.0, 50.0] if _cycles % 2 == 0 else [0.0]
			for o in offs:
				var x := clampf(ax + float(o), 40.0, 680.0)
				_marks.append(Vector2(x, 90.0))
				var q := PhysicsRayQueryParameters2D.create(Vector2(x, 100), Vector2(x, 1500), Layers.TERRAIN)
				var hit := get_world_2d().direct_space_state.intersect_ray(q)
				_ground_y.append(hit["position"].y if not hit.is_empty() else 1000.0)
		"crab_king":
			_aim_at_target()


func _launch_point() -> Vector2:
	return global_position + Vector2(-46, -70)


func _aim_at_target() -> void:
	var a := _target()
	if a == null:
		return
	_aim = a.global_position + Vector2(0, -12)
	var g := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	var T := 1.15
	var d := _aim - _launch_point()
	_launch_v = Vector2(d.x / T, (d.y - 0.5 * g * T * T) / T)


func _act() -> void:
	_flap = 1.0
	match kind:
		"owl":
			Sfx.play("moth_flutter", 0.0, 0.5)
			level.shake(4.0)
			for m in _marks:
				var s := Projectile.new()
				s.setup(level, "snow")
				s.position = m
				s.linear_velocity = Vector2(0, 120)
				level.add_projectile(s)
		"crab_king":
			Sfx.play("pop", 0.0, 0.7)
			var s := Projectile.new()
			s.setup(level, "shell")
			s.position = _launch_point()
			s.linear_velocity = _launch_v
			s.angular_velocity = -8.0
			level.add_projectile(s)
		"octopus":
			Sfx.play("wasp_dash", -2.0, 0.45)


func _suck(delta: float) -> void:
	var bodies: Array = []
	bodies.append_array(level.lines)
	bodies.append_array(level.props)
	for b in bodies:
		var body := b as RigidBody2D
		if body == null or not is_instance_valid(body) or body.freeze:
			continue
		var to := global_position - body.global_position
		body.apply_central_force(to.normalized() * SUCK_ACCEL * body.mass)
	for a in level.animals:
		if is_instance_valid(a) and not a.freeze:
			var to := global_position - a.global_position
			a.apply_central_force(to.normalized() * SUCK_ACCEL * 0.25 * a.mass)
	for i in level.insects:
		if is_instance_valid(i):
			var to := global_position - i.global_position
			i.apply_central_force(to.normalized() * SUCK_ACCEL * 0.15 * i.mass)


func _check_hug() -> void:
	for a in level.animals:
		if is_instance_valid(a) and a.global_position.distance_to(global_position) < HUG_RADIUS:
			level.on_animal_hugged(a)
			return


func _process(_delta: float) -> void:
	queue_redraw()


# ------------------------------------------------------------------ arte
func _draw() -> void:
	match kind:
		"owl": _draw_owl()
		"crab_king": _draw_crab_king()
		"octopus": _draw_octopus()
	if _phase == "warn":
		var blink := int(_phase_t * 8.0) % 2 == 0
		if blink:
			DrawUtil.disc(self, Vector2(0, -110), 15.0, Palette.GOLD, Palette.OUTLINE, 3.0)
			draw_line(Vector2(0, -120), Vector2(0, -106), Palette.OUTLINE, 4.0, true)
			draw_circle(Vector2(0, -100), 2.2, Palette.OUTLINE, true, -1.0, true)


func _draw_warn_marks() -> void:
	if kind == "owl" and _phase == "warn":
		for i in _marks.size():
			var m := _marks[i] - global_position
			var gy := _ground_y[i] - global_position.y
			var y := m.y + 20.0
			while y < gy - 10.0:
				draw_circle(Vector2(m.x, y), 2.5, Color(Palette.DANGER, 0.45), true, -1.0, true)
				y += 20.0
			draw_line(Vector2(m.x - 12, gy - 12), Vector2(m.x + 12, gy), Color(Palette.DANGER, 0.8), 4.0, true)
			draw_line(Vector2(m.x - 12, gy), Vector2(m.x + 12, gy - 12), Color(Palette.DANGER, 0.8), 4.0, true)
	elif kind == "crab_king" and _phase == "warn":
		var g := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
		var p0 := _launch_point() - global_position
		for k in 14:
			var t := 1.15 * (k + 1) / 15.0
			var p := p0 + _launch_v * t + Vector2(0, 0.5 * g * t * t)
			draw_circle(p, 3.0, Color(Palette.DANGER, 0.55), true, -1.0, true)


func _draw_owl() -> void:
	var o := Palette.OUTLINE
	_draw_warn_marks()
	# galho
	draw_line(Vector2(-90, 58), Vector2(90, 52), Color("8a5a39"), 12.0, true)
	draw_line(Vector2(-90, 58), Vector2(90, 52), o, 3.0, true)
	var up := (1.0 if _phase == "warn" else _flap) * 0.9
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([Vector2(side * 34, -10), Vector2(side * (62 + 18 * up), -20 - 50 * up),
			Vector2(side * (70 + 10 * up), 10 - 30 * up), Vector2(side * 40, 36)])
		DrawUtil.shape(self, wing, Color("9aa6c2"), o, 3.5)
	DrawUtil.oval(self, Vector2(0, 0), Vector2(46, 56), Color("c9d2e6"), o, 4.5)
	DrawUtil.oval(self, Vector2(0, 16), Vector2(28, 34), Color("f4f8ff"), o, 0.0)
	for k in 3:
		DrawUtil.arc(self, Vector2(-10 + k * 10, 10 + (k % 2) * 10), 5.0, 0.2, PI - 0.2, Color("9aa6c2"), 2.0)
	# tufos e olhos grandes
	DrawUtil.tri(self, Vector2(-38, -36), Vector2(-20, -50), Vector2(-40, -66), Color("9aa6c2"), o, 3.0)
	DrawUtil.tri(self, Vector2(38, -36), Vector2(20, -50), Vector2(40, -66), Color("9aa6c2"), o, 3.0)
	for side in [-1.0, 1.0]:
		DrawUtil.disc(self, Vector2(side * 17, -24), 15.0, Palette.WHITE, o, 3.0)
		var glow := Color("ffd23f") if _phase == "warn" else Color("ffb340")
		draw_circle(Vector2(side * 17, -23), 9.0, glow, true, -1.0, true)
		draw_circle(Vector2(side * 17, -22), 5.0, o, true, -1.0, true)
		draw_circle(Vector2(side * 15, -26), 2.0, Color.WHITE, true, -1.0, true)
	DrawUtil.tri(self, Vector2(-6, -12), Vector2(6, -12), Vector2(0, -2), Color("ffa62b"), o, 2.5)
	# gorro de neve
	DrawUtil.oval(self, Vector2(0, -54), Vector2(26, 9), Color("f6fbff"), o, 2.5)
	if _flap > 0.0:
		for k in 5:
			var p := Vector2(-80 + k * 40, 70 + (1.0 - _flap) * 60.0 + (k % 2) * 14.0)
			for j in 3:
				var d := Vector2.from_angle(PI * j / 3.0) * 5.0
				draw_line(p - d, p + d, Color(1, 1, 1, _flap), 2.0, true)


func _draw_crab_king() -> void:
	var o := Palette.OUTLINE
	_draw_warn_marks()
	var red := Color("ff6b57")
	var lift := 1.0 if _phase == "warn" else _flap
	for side in [-1.0, 1.0]:
		for k in 3:
			var x: float = side * (30 + k * 16)
			draw_line(Vector2(x, 10), Vector2(x + side * 18, 40), o, 7.0, true)
			draw_line(Vector2(x, 10), Vector2(x + side * 18, 40), red, 4.0, true)
	# garras (a esquerda sobe para arremessar)
	var claw_l := Vector2(-70, -40 - 40 * lift)
	draw_line(Vector2(-44, -10), claw_l, o, 12.0, true)
	draw_line(Vector2(-44, -10), claw_l, red, 8.0, true)
	DrawUtil.oval(self, claw_l, Vector2(22, 16), red, o, 3.5, -0.5)
	draw_line(claw_l + Vector2(-6, -4), claw_l + Vector2(-24, -14), o, 3.0, true)
	DrawUtil.oval(self, Vector2(70, -30), Vector2(22, 16), red, o, 3.5, 0.5)
	draw_line(Vector2(44, -10), Vector2(66, -24), o, 4.0, true)
	DrawUtil.oval(self, Vector2(0, 0), Vector2(62, 36), red, o, 4.5)
	DrawUtil.oval(self, Vector2(0, 12), Vector2(36, 14), Color("ff9a86"), o, 0.0)
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 14, -30), Vector2(side * 18, -52), o, 4.0, true)
		DrawUtil.disc(self, Vector2(side * 18, -56), 10.0, Palette.WHITE, o, 3.0)
		draw_circle(Vector2(side * 18 - 2, -55), 4.5, o, true, -1.0, true)
	DrawUtil.arc(self, Vector2(0, -2), 10.0, 0.3, PI - 0.3, o, 3.0)
	# coroa
	DrawUtil.shape(self, PackedVector2Array([Vector2(-16, -34), Vector2(-16, -50), Vector2(-7, -42), Vector2(0, -56), Vector2(7, -42), Vector2(16, -50), Vector2(16, -34)]), Palette.GOLD, o, 3.0)
	draw_circle(Vector2(0, -44), 3.5, Color("4ff3ff"), true, -1.0, true)


func _draw_octopus() -> void:
	var o := Palette.OUTLINE
	if _ink > 0.0:
		var ip := _ink_pos - global_position
		for k in 6:
			var r := (60.0 + k * 40.0) * (1.6 - _ink * 0.6)
			draw_circle(ip + Vector2(sin(k * 1.7) * 30.0, 40.0 + k * 10.0), r, Color(0.2, 0.1, 0.32, 0.12 * _ink), true, -1.0, true)
	var swell := 0.0
	if _phase == "warn":
		swell = _phase_t / WARN_TIME
	elif _phase == "act":
		swell = 1.0
	var purple := Color("a678e8")
	for k in 8:
		var a := PI * 0.12 + PI * 0.76 * k / 7.0
		var base := Vector2(cos(a) * 46.0, 20.0 + sin(a) * 18.0)
		var pts := PackedVector2Array()
		for j in 9:
			var t := j / 8.0
			var wav := sin(_t * 3.0 + k + t * 4.0) * 10.0 * t
			pts.append(base + Vector2(cos(a) * 60.0 * t + wav, 70.0 * t + 20.0 * t * t))
		draw_polyline(pts, o, 16.0, true)
		draw_polyline(pts, purple, 11.0, true)
	var r := 62.0 + swell * 14.0
	DrawUtil.oval(self, Vector2(0, -16), Vector2(r, r * 0.9), purple, o, 4.5)
	DrawUtil.oval(self, Vector2(-22, -44), Vector2(14, 9), Color("c9a6ff"), o, 0.0, -0.4)
	for side in [-1.0, 1.0]:
		DrawUtil.disc(self, Vector2(side * 22, -8), 13.0, Palette.WHITE, o, 3.0)
		draw_circle(Vector2(side * 22, -6), 6.0, o, true, -1.0, true)
		draw_circle(Vector2(side * 20, -9), 2.2, Color.WHITE, true, -1.0, true)
		draw_circle(Vector2(side * 38, 10), 7.0, Color(1.0, 0.56, 0.68, 0.8), true, -1.0, true)
	if _phase == "act":
		DrawUtil.oval(self, Vector2(0, 20), Vector2(12, 14), Color("5a2e6a"), o, 3.0)
		for k in 5:
			var a := TAU * k / 5.0 + _t * 3.0
			var p := Vector2.from_angle(a) * (150.0 - fmod(_phase_t * 200.0, 120.0))
			draw_arc(p, 10.0, a + 1.2, a + 2.6, 6, Color(1, 1, 1, 0.6), 3.0, true)
	else:
		DrawUtil.arc(self, Vector2(0, 16), 10.0, 0.3, PI - 0.3, o, 3.0)
	# chapéu de capitão
	DrawUtil.oval(self, Vector2(0, -72), Vector2(34, 10), Color("2f3e6e"), o, 3.0)
	DrawUtil.shape(self, PackedVector2Array([Vector2(-24, -74), Vector2(-18, -98), Vector2(18, -98), Vector2(24, -74)]), Color("2f3e6e"), o, 3.0)
	DrawUtil.disc(self, Vector2(0, -86), 6.0, Palette.GOLD, o, 2.0)
