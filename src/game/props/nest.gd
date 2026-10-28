class_name Nest
extends StaticBody2D
## Ninho/colmeia/formigueiro: de onde os insetos saem. Mostra quantos ainda vão sair.
## O tipo visual segue o inseto: colmeia (voadores) ou montinho de terra (andarilhos).

const KINDS := ["bee", "mosquito", "wasp", "moth", "ant", "beetle", "termite", "caterpillar"]
const FLYERS := ["bee", "mosquito", "wasp", "moth"]

var insect := "bee"
var count := 6
var interval := 0.3
var delay := 0.3
var remaining := 0
var level: Level
var running := false
var _timer := 0.0
var _t := 0.0
var _pulse := 0.0


func setup(p_level: Level, cfg: Dictionary) -> void:
	level = p_level
	insect = str(cfg.get("insect", "bee"))
	if not KINDS.has(insect):
		insect = "bee"
	count = int(cfg.get("count", 6))
	interval = float(cfg.get("interval", 0.3))
	delay = float(cfg.get("delay", 0.3))
	remaining = count
	collision_layer = Layers.NEST
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 26.0 if is_flyer_nest() else 22.0
	cs.shape = c
	add_child(cs)


func is_flyer_nest() -> bool:
	return FLYERS.has(insect)


func begin() -> void:
	running = true
	_timer = delay


func _physics_process(delta: float) -> void:
	_pulse = maxf(_pulse - delta * 3.0, 0.0)
	if not running or remaining <= 0:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = interval
		_spawn()


func _spawn() -> void:
	remaining -= 1
	_pulse = 1.0
	var bug := make_insect(insect)
	bug.setup(level, insect)
	var out := Vector2(0, 44) if is_flyer_nest() else Vector2(0, -40)
	bug.position = position + out + Vector2(randf_range(-6, 6), 0)
	level.add_insect(bug)
	if is_flyer_nest():
		var to := Vector2.DOWN
		var target := level.nearest_animal(bug.position)
		if target != null:
			to = (target.global_position - bug.position).normalized()
		# leque de saída: cada inseto sai num ângulo um pouco diferente (só estético)
		var spread := randf_range(-0.7, 0.7)
		bug.linear_velocity = (Vector2.DOWN * 0.5 + to * 0.5).normalized().rotated(spread) * bug.max_speed * randf_range(0.5, 0.8)
	queue_redraw()


static func make_insect(kind: String) -> Insect:
	match kind:
		"mosquito": return Mosquito.new()
		"wasp": return Wasp.new()
		"moth": return Moth.new()
		"ant": return Ant.new()
		"beetle": return Beetle.new()
		"termite": return Termite.new()
		"caterpillar": return Caterpillar.new()
	return Bee.new()


func _process(delta: float) -> void:
	_t += delta
	if _pulse > 0.0:
		queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	var s := 1.0 + _pulse * 0.12
	if is_flyer_nest():
		draw_line(Vector2(0, -26), Vector2(0, -70), o, 4.0, true)
		var col := Color("f2b84b") if insect != "wasp" else Color("cfc4b4")
		if insect == "moth":
			col = Color("c4b0e0")
		for i in 4:
			var w := (24.0 - absf(i - 1.5) * 5.0) * s
			DrawUtil.oval(self, Vector2(0, -18 + i * 12.0) * s, Vector2(w, 9.0 * s), col, o, 3.0)
		DrawUtil.oval(self, Vector2(0, 16) * s, Vector2(8, 6) * s, Color("5a3a2a"), o, 2.5)
	else:
		var mound := PackedVector2Array()
		for i in 13:
			var a := PI + PI * float(i) / 12.0
			mound.append(Vector2(cos(a) * 34.0 * s, 20.0 + sin(a) * 32.0 * s))
		DrawUtil.shape(self, mound, Color("c08552"))
		DrawUtil.oval(self, Vector2(0, -6), Vector2(8, 5) * s, Color("5a3a2a"), o, 2.5)
	if remaining > 0:
		var font := ThemeDB.fallback_font
		var label := "x%d" % remaining
		var pos := Vector2(18, -30) if is_flyer_nest() else Vector2(18, -22)
		DrawUtil.disc(self, pos + Vector2(12, -6), 14.0, Palette.WHITE, o, 2.5)
		draw_string(font, pos + Vector2(0, 0), label, HORIZONTAL_ALIGNMENT_CENTER, 24, 15, o)
