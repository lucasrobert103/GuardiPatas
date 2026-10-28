class_name Level
extends Node2D
## Uma fase: monta o cenário a partir dos dados, controla o ciclo
## DESENHAR → SIMULAR → VENCER/PERDER e conversa com HUD, áudio e progresso.

signal navigate(action: String)
signal state_changed(state: int)
signal result_ready(won: bool, info: Dictionary)

enum State { DRAWING, RUNNING, WON, LOST }

const CENTER := Vector2(360, 640)
const FALL_Y := 1360.0
const MAX_INSECTS := 45

var index := 0
var data: Dictionary = {}
var world_id := 1
var state := State.DRAWING
var survive := 8.0
var time_left := 8.0
var strokes_total := 1
var strokes_left := 1
var lose_reason := ""
var with_hud := true
var hint_shown := false
var last_result: Dictionary = {}

var animals: Array[Animal] = []
var insects: Array[Insect] = []
var nests: Array[Nest] = []
var lamps: Array[Lamp] = []
var platforms: Array[MovingPlatform] = []
var props: Array[Crate] = []
var lines: Array[DrawnLine] = []

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
	strokes_left = strokes_total


func _ready() -> void:
	_build()
	if with_hud:
		hud = Hud.new()
		add_child(hud)
		hud.bind(self)
		hud.action.connect(_on_hud_action)
	state_changed.emit(state)


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
		world.add_child(nest)
		nests.append(nest)
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
	drawer.setup(float(data.get("ink", 800)), nodraw)
	drawer.stroke_finished.connect(_on_stroke_finished)
	add_child(drawer)


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
	var line := DrawnLine.new()
	line.build(points)
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
	drawer.enabled = false
	drawer.hint_strokes = []
	drawer.queue_redraw()
	for a in animals:
		a.freeze = false
	for c in props:
		c.freeze = false
	for l in lines:
		l.freeze = false
	for n in nests:
		n.begin()
	for p in platforms:
		p.begin()
	state_changed.emit(state)


func add_insect(bug: Insect) -> void:
	if insects.size() >= MAX_INSECTS:
		bug.queue_free()
		return
	world.add_child(bug)
	insects.append(bug)


func _physics_process(delta: float) -> void:
	_prune()
	if state == State.RUNNING:
		_sim_time += delta
		time_left -= delta
		for l in lamps:
			l.tick(delta)
		for a in animals:
			if a.global_position.y > FALL_Y:
				lose("fall")
				return
		var whole := int(ceil(time_left))
		if whole != _last_tick and whole <= 3 and whole > 0:
			_last_tick = whole
			Sfx.play("tick", -2.0, 1.0 + (3 - whole) * 0.1)
		if time_left <= 0.0:
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
	lose("sting")


func on_animal_in_water(animal: Animal) -> void:
	if animal.can_swim() or state != State.RUNNING:
		return
	Fx.splash(fx_layer, animal.global_position)
	Sfx.play("splash")
	lose("water")


func ink_used() -> float:
	return 1.0 - drawer.ink_left / maxf(drawer.ink_total, 1.0)


func win() -> void:
	if state != State.RUNNING:
		return
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
	var info := Game.complete_level(str(data.get("id", "?")), stars, used, met)
	info["stars"] = stars
	info["ink_used"] = used
	last_result = info
	Sfx.play("win")
	Sfx.vibrate(60)
	for a in animals:
		Fx.confetti(fx_layer, a.global_position + Vector2(0, -40))
	state_changed.emit(state)
	_emit_result_later(true, info)


func lose(reason: String) -> void:
	if state != State.RUNNING:
		return
	state = State.LOST
	lose_reason = reason
	for n in nests:
		n.running = false
	for a in animals:
		a.be_sad()
	Game.record_loss()
	last_result = {"reason": reason}
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
