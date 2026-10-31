class_name Level
extends Node2D
## Uma fase: monta o cenário a partir dos dados, controla o ciclo
## DESENHAR → SIMULAR → VENCER/PERDER e conversa com HUD, áudio e progresso.

signal navigate(action: String)
signal state_changed(state: int)
signal result_ready(won: bool, info: Dictionary)
signal simulation_speed_changed(speed: int)

enum State { DRAWING, RUNNING, WON, LOST }

const CENTER := Vector2(360, 640)
const FALL_Y := 1360.0
const MAX_INSECTS := 45

var index := 0
var data: Dictionary = {}
var world_id := 1
var state := State.DRAWING
var simulation_speed := 1
var _normal_physics_ticks := 60
var _normal_time_scale := 1.0
var survive := 8.0
var time_left := 8.0
var strokes_total := 1
var strokes_left := 1
var lose_reason := ""
var with_hud := true
var hint_shown := false
var last_result: Dictionary = {}
var replay: AttemptReplay

var animals: Array[Animal] = []
var insects: Array[Insect] = []
var _insect_serial := 0
var nests: Array[Nest] = []
var lamps: Array[Lamp] = []
var platforms: Array[MovingPlatform] = []
var props: Array[Crate] = []
var lines: Array[DrawnLine] = []
var queens: Array[QueenBee] = []
var bosses: Array[Boss] = []
var projectiles: Array[Projectile] = []
var honeys: Array[HoneyPot] = []
var coconuts: Array[Coconut] = []
var winds: Array[WindZone] = []
var goal: GoalZone

## "static": as linhas não caem (Tinta Firme). "normal": linhas com peso.
var ink_mode := "normal"
## Fundo do mar: todos os bichinhos estão na água e ninguém "molha".
var underwater := false
## Modo Livre: tinta infinita e vários traços; não vale estrelas nem moedas.
var free_mode := false
var _goal_t := 0.0
## "campaign" | "daily" | "custom" (fase criada no editor)
var mode := "campaign"
var insect_speed := 1.0
## Medalhas extras (ver Game.MEDALS)
const QUICK_TIME := 6.0
var paw: GoldenPaw
var paw_got := false
var first_try := true
var quick := false
var _draw_clock := 0.0

var world: Node2D
var fx_layer: Node2D
var drawer: LineDrawer
var camera: Camera2D
var hud: Hud

var _shake := 0.0
var _last_tick := -1
var _sim_time := 0.0


func setup(p_index: int, p_data: Dictionary, p_with_hud: bool = true) -> void:
	index = p_index
	data = p_data
	with_hud = p_with_hud
	world_id = int(data.get("world", 1))
	survive = float(data.get("survive", 8.0))
	time_left = survive
	strokes_total = int(data.get("strokes", 1))
	ink_mode = str(data.get("ink_mode", "normal"))
	underwater = bool(data.get("underwater", false))
	mode = str(data.get("mode", "campaign"))
	insect_speed = float(data.get("insect_speed", 1.0))
	free_mode = mode == "campaign" and Game.free_mode and Game.is_completed(str(data.get("id", "")))
	first_try = Game.never_failed(str(data.get("id", "")))
	if free_mode:
		strokes_total = 20
	strokes_left = strokes_total


func _ready() -> void:
	_build()
	if with_hud:
		hud = Hud.new()
		add_child(hud)
		hud.bind(self)
		replay = AttemptReplay.new()
		hud.action.connect(_on_hud_action)
	state_changed.emit(state)


## Acelera o relógio mantendo o mesmo passo de física (1/60 s no projeto).
func set_simulation_speed(speed: int) -> bool:
	if speed not in [1, 2]:
		return false
	if speed == 2 and (state != State.RUNNING or not is_inside_tree() or get_tree().paused or is_queued_for_deletion()):
		return false
	if speed == simulation_speed:
		return true
	if speed == 2:
		_normal_physics_ticks = Engine.physics_ticks_per_second
		_normal_time_scale = Engine.time_scale
		Engine.physics_ticks_per_second = _normal_physics_ticks * speed
		Engine.time_scale = _normal_time_scale * speed
	else:
		Engine.time_scale = _normal_time_scale
		Engine.physics_ticks_per_second = _normal_physics_ticks
	simulation_speed = speed
	simulation_speed_changed.emit(speed)
	return true


func _exit_tree() -> void:
	set_simulation_speed(1)


# ------------------------------------------------------------------ construção
func _build() -> void:
	var bg := Background.new()
	bg.setup(world_id)
	add_child(bg)
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	fx_layer = Node2D.new()
	fx_layer.name = "Fx"
	fx_layer.z_index = 40
	add_child(fx_layer)
	camera = Camera2D.new()
	camera.position = CENTER
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)
	camera.make_current()

	for t in data.get("terrain", []):
		var poly := _to_poly(t.get("poly", []))
		if poly.size() >= 3:
			var tr := Terrain.new()
			tr.setup(poly, str(t.get("style", "ground")), world_id)
			world.add_child(tr)
	for r in data.get("rocks", []):
		var rock := Terrain.new()
		rock.setup(Terrain.make_circle(_v(r["pos"]), float(r.get("r", 30))), "stone", world_id)
		world.add_child(rock)
	for p in data.get("props", []):
		_build_prop(p)
	for n in data.get("nests", []):
		var nest := Nest.new()
		nest.position = _v(n["pos"])
		nest.setup(self, n)
		if n.has("platform") and int(n["platform"]) >= 0 and int(n["platform"]) < data.get("props", []).size() and str(data["props"][int(n["platform"])].get("type", "")) == "platform":
			var platform_index := 0
			for prop_index in int(n["platform"]):
				if str(data["props"][prop_index].get("type", "")) == "platform": platform_index += 1
			if platform_index < platforms.size():
				nest.mount = platforms[platform_index]
				nest.mount_offset = _v(n.get("platform_offset", [0, 0]))
		world.add_child(nest)
		nests.append(nest)
	for b in data.get("bosses", []):
		if str(b.get("kind", "queen")) != "queen":
			var boss := Boss.new()
			boss.setup(self, b)
			world.add_child(boss)
			bosses.append(boss)
			continue
		var q := QueenBee.new()
		q.level = self
		q.home = _v(b.get("pos", [360, 300]))
		q.sway = float(b.get("sway", 200))
		q.position = q.home
		q.z_index = 20
		world.add_child(q)
		queens.append(q)
	for a in data.get("animals", []):
		var animal := Animal.new()
		animal.position = _v(a["pos"])
		animal.setup(str(a.get("type", "capi")), self, bool(a.get("flip", false)))
		animal.stung.connect(_on_animal_stung)
		world.add_child(animal)
		animals.append(animal)

	drawer = LineDrawer.new()
	drawer.z_index = 30
	var nodraw: Array[Rect2] = []
	for r in data.get("nodraw", []):
		nodraw.append(Rect2(r[0], r[1], r[2], r[3]))
	if data.has("goal"):
		var gr: Array = data["goal"]["rect"]
		goal = GoalZone.new()
		goal.setup(Rect2(gr[0], gr[1], gr[2], gr[3]))
		world.add_child(goal)
	for wcfg in data.get("winds", []):
		var wz := WindZone.new()
		wz.setup(wcfg, underwater)
		add_child(wz)
		winds.append(wz)
	drawer.static_ink = ink_mode == "static"
	drawer.infinite = free_mode
	drawer.setup(1000000.0 if free_mode else float(data.get("ink", 800)), nodraw)
	drawer.stroke_finished.connect(_on_stroke_finished)
	add_child(drawer)
	if mode == "campaign" and not free_mode:
		var pp := paw_point()
		if pp != Vector2.INF:
			paw = GoldenPaw.new()
			paw.position = pp
			paw.z_index = 25
			world.add_child(paw)


func _build_prop(p: Dictionary) -> void:
	match str(p.get("type", "")):
		"crate", "plank":
			var c := Crate.new()
			c.position = _v(p["pos"])
			c.setup(_v(p.get("size", [60, 60])), p["type"] == "plank", deg_to_rad(float(p.get("rot", 0))))
			world.add_child(c)
			props.append(c)
		"lamp":
			var l := Lamp.new()
			l.position = _v(p["pos"])
			l.setup(float(p.get("duration", -1)))
			world.add_child(l)
			lamps.append(l)
		"water":
			var w := Water.new()
			var r: Array = p["rect"]
			w.setup(Rect2(r[0], r[1], r[2], r[3]), self)
			world.add_child(w)
		"honey":
			var h := HoneyPot.new()
			h.position = _v(p["pos"])
			h.setup(float(p.get("amount", 6.0)))
			world.add_child(h)
			honeys.append(h)
		"coconut":
			var cn := Coconut.new()
			cn.position = _v(p["pos"])
			cn.setup(self, float(p.get("drop", 3.0)))
			world.add_child(cn)
			coconuts.append(cn)
		"platform":
			var m := MovingPlatform.new()
			var r: Array = p["rect"]
			m.setup(Rect2(r[0], r[1], r[2], r[3]), _v(p.get("travel", [0, 0])), float(p.get("period", 3.0)))
			world.add_child(m)
			platforms.append(m)


static func _v(a: Variant) -> Vector2:
	if a is Array and a.size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO


static func _to_poly(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in arr:
		out.append(_v(p))
	return out


static func _to_poly_list(arr: Array) -> Array:
	var out: Array = []
	for s in arr:
		out.append(_to_poly(s))
	return out


## Onde fica a pegada dourada: num ombro do primeiro traço da solução, um pouquinho para fora
## (o traço registrado passa a menos de GoldenPaw.RADIUS dela). "paw": [x, y] no JSON força o lugar.
func paw_point() -> Vector2:
	if data.has("paw"):
		return _v(data["paw"])
	var strokes := solution_strokes()
	if strokes.is_empty() or (strokes[0] as PackedVector2Array).size() < 2:
		return Vector2.INF
	var s: PackedVector2Array = strokes[0]
	var total := 0.0
	for i in range(1, s.size()):
		total += s[i - 1].distance_to(s[i])
	var goal_len := total * 0.32
	var acc := 0.0
	var centroid := Vector2.ZERO
	for p in s:
		centroid += p
	centroid /= s.size()
	for i in range(1, s.size()):
		var seg := s[i - 1].distance_to(s[i])
		if acc + seg >= goal_len and seg > 0.0:
			var p := s[i - 1].lerp(s[i], (goal_len - acc) / seg)
			var n := (s[i] - s[i - 1]).normalized().orthogonal()
			if n.dot(p - centroid) < 0.0:
				n = -n
			return p + n * 14.0
		acc += seg
	return Vector2.INF


func _check_paw(points: PackedVector2Array) -> void:
	if paw == null or paw_got:
		return
	for i in range(1, points.size()):
		var q := Geometry2D.get_closest_point_to_segment(paw.position, points[i - 1], points[i])
		if q.distance_to(paw.position) <= GoldenPaw.RADIUS:
			paw_got = true
			paw.collect()
			Fx.popup_text(fx_layer, paw.position + Vector2(0, -30), "Pegada!", Palette.GOLD_DARK)
			return


func solution_strokes() -> Array:
	var out: Array = []
	for s in data.get("solution", []):
		out.append(_to_poly(s))
	return out


# ------------------------------------------------------------------ entrada
func _unhandled_input(event: InputEvent) -> void:
	if state != State.DRAWING:
		return
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		var local := make_input_local(mb) as InputEventMouseButton
		if mb.pressed:
			drawer.press(local.position)
			if hud != null:
				hud.hide_tip()
		else:
			drawer.release()
		get_viewport().set_input_as_handled()
		return
	var mm := event as InputEventMouseMotion
	if mm != null and drawer.drawing:
		var local := make_input_local(mm) as InputEventMouseMotion
		drawer.move(local.position)
		get_viewport().set_input_as_handled()


func _on_stroke_finished(points: PackedVector2Array) -> void:
	if state != State.DRAWING:
		return
	_check_paw(points)
	var line := DrawnLine.new()
	line.build(points, Palette.INK, ink_mode == "static")
	if not line.static_ink:
		line.freeze = strokes_left > 1
	world.add_child(line)
	lines.append(line)
	Game.data["stats"]["lines"] = int(Game.data["stats"]["lines"]) + 1
	strokes_left -= 1
	if strokes_left <= 0:
		start_simulation()
	elif hud != null:
		hud.refresh()


func _on_hud_action(action: String) -> void:
	match action:
		"hint":
			show_hint()
		"play":
			if state == State.DRAWING and not lines.is_empty():
				start_simulation()
		_:
			set_simulation_speed(1)
			navigate.emit(action)


func show_hint() -> bool:
	if hint_shown:
		return true
	hint_shown = true
	drawer.hint_strokes = solution_strokes()
	Sfx.play("hint")
	return true


# ------------------------------------------------------------------ simulação
func is_running() -> bool:
	return state == State.RUNNING


func start_simulation() -> void:
	if state != State.DRAWING:
		return
	state = State.RUNNING
	quick = _draw_clock <= QUICK_TIME
	if paw != null and not paw_got:
		paw.visible = false
	drawer.enabled = false
	drawer.hint_strokes = []
	drawer.queue_redraw()
	for a in animals:
		a.freeze = false
	for c in props:
		c.freeze = false
	for l in lines:
		if not l.static_ink:
			l.freeze = false
	for w in winds:
		w.begin()
	for n in nests:
		n.begin()
	for p in platforms:
		p.begin()
	for q in queens:
		q.begin()
	for b in bosses:
		b.begin()
	if replay != null: replay.begin(self)
	state_changed.emit(state)


func add_projectile(p: Projectile) -> void:
	world.add_child(p)
	projectiles.append(p)


## Tipo do chefão da fase ("" se não houver) — usado nas conquistas.
func boss_kind() -> String:
	if not queens.is_empty():
		return "queen"
	return bosses[0].kind if not bosses.is_empty() else ""


func add_insect(bug: Insect) -> void:
	if insects.size() >= MAX_INSECTS:
		bug.queue_free()
		return
	bug.set_tactic_id(_insect_serial)
	_insect_serial += 1
	bug.max_speed *= insect_speed
	world.add_child(bug)
	insects.append(bug)


func _physics_process(delta: float) -> void:
	_prune()
	if state == State.DRAWING and not get_tree().paused:
		_draw_clock += delta
	if state == State.RUNNING:
		_sim_time += delta
		if replay != null: replay.record(self, delta)
		time_left -= delta
		for l in lamps:
			l.tick(delta)
		for c in coconuts:
			if is_instance_valid(c):
				c.tick(_sim_time)
		_apply_wind(delta)
		for a in animals:
			if a.global_position.y > FALL_Y:
				lose("fall", a.global_position, "", a.get_instance_id())
				return
		if goal != null:
			_check_goal(delta)
			if state != State.RUNNING:
				return
		var whole := int(ceil(time_left))
		if whole != _last_tick and whole <= 3 and whole > 0:
			_last_tick = whole
			Sfx.play("tick", -2.0, 1.0 + (3 - whole) * 0.1)
		if time_left <= 0.0:
			if goal != null:
				lose("time")
			else:
				win()


func _apply_wind(delta: float) -> void:
	if winds.is_empty():
		return
	for w in winds:
		w.tick(delta)
		if not w.active:
			continue
		for l in lines:
			if not l.static_ink and not l.freeze:
				w.push(l)
		for c in props:
			if is_instance_valid(c) and not c.freeze:
				w.push(c)
		for i in insects:
			if is_instance_valid(i) and i.flying:
				# insetos sentem o vento mais fraco: ele desvia, mas não decide a fase
				w.push(i, w.insect_scale)


func _check_goal(delta: float) -> void:
	var inside := true
	for a in animals:
		if not goal.rect.has_point(a.global_position):
			inside = false
			break
	_goal_t = _goal_t + delta if inside else 0.0
	if _goal_t >= float(data.get("goal", {}).get("hold", 0.35)):
		goal.reached = true
		Game.add_stat("goals", 1)
		win()


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 18.0, 0.0)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	elif camera != null:
		camera.offset = Vector2.ZERO
	_update_buzz()


func _prune() -> void:
	var alive: Array[Insect] = []
	for i in insects:
		if is_instance_valid(i) and not i.is_queued_for_deletion():
			alive.append(i)
	insects = alive
	if not props.is_empty():
		var kept: Array[Crate] = []
		for c in props:
			if is_instance_valid(c) and not c.is_queued_for_deletion():
				kept.append(c)
		props = kept
	if not projectiles.is_empty():
		var live: Array[Projectile] = []
		for pr in projectiles:
			if is_instance_valid(pr) and not pr.is_queued_for_deletion():
				live.append(pr)
		projectiles = live


func _update_buzz() -> void:
	if state != State.RUNNING:
		Sfx.stop_loop("bees")
		Sfx.stop_loop("mosq")
		Sfx.stop_loop("moth")
		return
	var counts := {"bee": 0, "wasp": 0, "mosquito": 0, "moth": 0}
	for i in insects:
		if is_instance_valid(i) and counts.has(i.kind):
			counts[i.kind] += 1
	var buzzing: int = counts["bee"] + counts["wasp"]
	if buzzing > 0:
		Sfx.loop("bees", "buzz_bee", -20.0 + minf(buzzing, 10) * 1.2, 1.0 + counts["wasp"] * 0.05)
	else:
		Sfx.stop_loop("bees")
	if counts["mosquito"] > 0:
		Sfx.loop("mosq", "buzz_mosquito", -22.0 + minf(counts["mosquito"], 8) * 1.0)
	else:
		Sfx.stop_loop("mosq")
	if counts["moth"] > 0:
		Sfx.loop("moth", "moth_flutter", -16.0)
	else:
		Sfx.stop_loop("moth")


func nearest_animal(pos: Vector2) -> Animal:
	var best: Animal = null
	var best_d := INF
	for a in animals:
		var d := pos.distance_squared_to(a.global_position)
		if d < best_d:
			best_d = d
			best = a
	return best


func nearest_insect(pos: Vector2) -> Insect:
	var best: Insect = null
	var best_d := INF
	for i in insects:
		if not is_instance_valid(i) or i.calmed:
			continue
		var d := pos.distance_squared_to(i.global_position)
		if d < best_d:
			best_d = d
			best = i
	return best


func nearest_crate(pos: Vector2, max_dist: float) -> Crate:
	var best: Crate = null
	var best_d := max_dist * max_dist
	for c in props:
		if not is_instance_valid(c) or c.is_queued_for_deletion():
			continue
		var d := pos.distance_squared_to(c.global_position)
		if d < best_d:
			best_d = d
			best = c
	return best


func nearest_honey(pos: Vector2) -> HoneyPot:
	var best: HoneyPot = null
	var best_d := INF
	for h in honeys:
		if not h.has_honey():
			continue
		var d := pos.distance_squared_to(h.global_position)
		if d < best_d:
			best_d = d
			best = h
	return best


func nearest_lit_lamp(pos: Vector2) -> Lamp:
	var best: Lamp = null
	var best_d := INF
	for l in lamps:
		if not l.lit:
			continue
		var d := pos.distance_squared_to(l.global_position)
		if d < best_d:
			best_d = d
			best = l
	return best


func shake(amount: float) -> void:
	if not Game.setting("reduce_motion"):
		_shake = maxf(_shake, amount)


# ------------------------------------------------------------------ fim de fase
func _on_animal_stung(animal: Animal, _insect: Node) -> void:
	if state != State.RUNNING:
		return
	Sfx.play("sting")
	Sfx.vibrate(120)
	shake(10.0)
	Fx.popup_text(fx_layer, animal.global_position + Vector2(0, -70), "Ai!", Palette.DANGER)
	lose("sting", animal.global_position, _insect.kind if _insect is Insect else "", animal.get_instance_id())


func on_animal_bonked(animal: Animal, reason: String = "coconut") -> void:
	if state != State.RUNNING:
		return
	Sfx.play("bonk", 2.0, 0.6)
	Sfx.vibrate(100)
	shake(8.0)
	animal.art.mood = "ouch"
	Fx.popup_text(fx_layer, animal.global_position + Vector2(0, -70), "Bonk!", Palette.WOOD_DARK)
	lose(reason, animal.global_position, "", animal.get_instance_id())


func on_animal_hugged(animal: Animal) -> void:
	if state != State.RUNNING:
		return
	Sfx.play("bloop", 2.0, 0.6)
	Sfx.vibrate(80)
	animal.art.mood = "ouch"
	Fx.popup_text(fx_layer, animal.global_position + Vector2(0, -70), "Abraço!", Color("a678e8"))
	lose("hug", animal.global_position, "", animal.get_instance_id())


func on_animal_in_water(animal: Animal) -> void:
	if animal.can_swim() or underwater or state != State.RUNNING:
		return
	Fx.splash(fx_layer, animal.global_position)
	Sfx.play("splash")
	lose("water", animal.global_position, "", animal.get_instance_id())


func ink_used() -> float:
	if free_mode:
		return 0.0
	return 1.0 - drawer.ink_left / maxf(drawer.ink_total, 1.0)


func win() -> void:
	if state != State.RUNNING:
		return
	set_simulation_speed(1)
	if replay != null: replay.clear()
	state = State.WON
	for n in nests:
		n.running = false
	for i in insects:
		if is_instance_valid(i):
			i.calm_down()
	for a in animals:
		a.celebrate()
	var used := ink_used()
	var stars := Scoring.stars_for(used, data.get("stars", [0.4, 0.7]))
	var met: Array = []
	for a in animals:
		met.append(a.species)
	var info: Dictionary
	if mode == "daily":
		info = Game.complete_daily(str(data.get("daily_key", "")))
		stars = 0
	elif mode == "custom":
		info = {"custom": true, "coins": 0, "new_friends": [], "achievements": Game.verify_custom(int(data.get("custom_index", -1)))}
		stars = 0
	elif free_mode:
		# Modo Livre: só diversão — não mexe em estrelas nem moedas
		info = {"free": true, "coins": 0, "new_friends": [], "achievements": Game.record_free_win()}
		stars = 0
	else:
		var medals := {"paw": paw_got, "first": first_try, "quick": quick}
		info = Game.complete_level(str(data.get("id", "?")), stars, used, met, boss_kind(), medals)
		info["medals"] = medals
	info["stars"] = stars
	info["ink_used"] = used
	last_result = info
	Sfx.play("win")
	Sfx.vibrate(60)
	for a in animals:
		Fx.confetti(fx_layer, a.global_position + Vector2(0, -40))
	state_changed.emit(state)
	_emit_result_later(true, info)


func lose(reason: String, point: Vector2 = Vector2.INF, attacker: String = "", subject: int = 0) -> void:
	if state != State.RUNNING:
		return
	set_simulation_speed(1)
	if replay != null: replay.finish(self)
	state = State.LOST
	lose_reason = reason
	for n in nests:
		n.running = false
	for a in animals:
		a.be_sad()
	Game.record_loss(str(data.get("id", "")) if mode == "campaign" and not free_mode else "")
	if not point.is_finite():
		point = goal.rect.get_center() if reason == "time" and goal != null else (animals[0].global_position if not animals.is_empty() else Vector2(360, 640))
	var analysis := "O inseto alcançou o bichinho. Observe o caminho até o contato."
	match reason:
		"fall": analysis = "O bichinho caiu. Observe o apoio e o movimento da linha."
		"water": analysis = "O bichinho entrou na água. Observe o caminho até a margem."
		"time": analysis = "O tempo acabou antes da chegada. Observe o caminho até a toca."
		"coconut", "snow", "shell": analysis = "Um objeto atingiu o bichinho. Observe a direção do impacto."
		"hug": analysis = "O bichinho chegou ao polvo. Observe o efeito da sucção."
	if reason == "sting" and attacker in ["broca", "drillfish"]:
		analysis = "Uma broca alcançou o bichinho. Confira as saídas e as camadas."
	last_result = {"reason": reason, "failure_point": point, "failure_id": subject, "analysis": analysis}
	state_changed.emit(state)
	if reason == "fall":
		Sfx.play("gasp", 0.0, 0.8)
	_emit_result_later(false, last_result)


func _emit_result_later(won: bool, info: Dictionary) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(1.3 if won else 1.0, true, false, true).timeout
	if not is_inside_tree():
		return
	if not won:
		Sfx.play("lose", -2.0)
	result_ready.emit(won, info)
