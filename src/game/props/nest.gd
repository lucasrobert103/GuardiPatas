class_name Nest
extends StaticBody2D
## Ninho/colmeia/formigueiro/toca: de onde os insetos saem. Mostra quantos ainda vão sair.
## Visual pelo tipo: colmeia (voadores), teia (aranha), coral (criaturas do mar),
## montinho (andarilhos) ou BURACO NO CHÃO (`"hole": true`).
## Buraco: fica rente ao chão, não bloqueia o desenho e pode ser TAMPADO — se uma linha
## ou caixa estiver em cima dele quando um inseto for sair, ele não sai.

const KINDS := ["bee", "mosquito", "wasp", "moth", "ant", "beetle", "termite", "caterpillar", "cricket", "broca", "spider", "crab", "jellyfish", "puffer", "drillfish"]
const FLYERS := ["bee", "mosquito", "wasp", "moth", "broca"]
const SEA := ["jellyfish", "puffer", "drillfish"]
const PLUG_RADIUS := 10.0

var insect := "bee"
var count := 6
var interval := 0.3
var delay := 0.3
var remaining := 0
var hole := false
var plugged := false
var level: Level
var running := false
var _timer := 0.0
var _t := 0.0
var _pulse := 0.0
var _plug_shape := CircleShape2D.new()
var _plug_announced := false


func setup(p_level: Level, cfg: Dictionary) -> void:
	level = p_level
	insect = str(cfg.get("insect", "bee"))
	if not KINDS.has(insect):
		insect = "bee"
	count = int(cfg.get("count", 6))
	interval = float(cfg.get("interval", 0.3))
	delay = float(cfg.get("delay", 0.3))
	hole = bool(cfg.get("hole", false))
	remaining = count
	collision_mask = 0
	_plug_shape.radius = PLUG_RADIUS
	if hole:
		# rente ao chão e sem colisão: dá para desenhar por cima (e tampar)
		collision_layer = 0
		return
	collision_layer = Layers.NEST
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 26.0 if is_hanging() else 22.0
	cs.shape = c
	add_child(cs)


func is_flyer_nest() -> bool:
	return FLYERS.has(insect)


## Colmeias e teias ficam penduradas; os insetos saem por baixo.
func is_hanging() -> bool:
	return is_flyer_nest() or insect == "spider" or SEA.has(insect)


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
		if hole and _is_plugged():
			if not plugged:
				plugged = true
				queue_redraw()
				if not _plug_announced:
					_plug_announced = true
					Game.add_stat("plugs", 1)
					Fx.popup_text(level.fx_layer, global_position + Vector2(0, -40), "Tampado!", Palette.UI_GOOD, 1.0)
					Sfx.play("pop", -4.0, 0.8)
			return
		if plugged:
			plugged = false
			queue_redraw()
		_spawn()


func _is_plugged() -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = _plug_shape
	q.transform = Transform2D(0.0, global_position + Vector2(0, -8))
	q.collision_mask = Layers.LINE | Layers.PROP
	return not get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


func _spawn() -> void:
	remaining -= 1
	_pulse = 1.0
	var bug := make_insect(insect)
	bug.setup(level, insect)
	var out := Vector2(0, -40)
	if hole:
		out = Vector2(0, -bug.radius - 6.0)
	elif is_hanging():
		out = Vector2(0, 44)
	bug.position = position + out + Vector2(randf_range(-6, 6) if not hole else 0.0, 0)
	level.add_insect(bug)
	if hole:
		bug.linear_velocity = Vector2(randf_range(-20, 20), -180)
		Fx.dust(level.fx_layer, global_position)
	elif is_flyer_nest() or SEA.has(insect):
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
		"cricket": return Cricket.new()
		"broca", "drillfish": return CarpenterBee.new()
		"spider": return Spider.new()
		"crab": return Crab.new()
		"jellyfish": return Jellyfish.new()
		"puffer": return Puffer.new()
	return Bee.new()


func _process(delta: float) -> void:
	_t += delta
	if _pulse > 0.0 or hole:
		queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	var s := 1.0 + _pulse * 0.12
	if hole:
		_draw_hole(o, s)
	elif insect == "spider":
		draw_line(Vector2(0, -26), Vector2(0, -90), Color(1, 1, 1, 0.7), 2.0, true)
		for k in 6:
			var a := TAU * k / 6.0
			draw_line(Vector2.ZERO, Vector2.from_angle(a) * 30.0 * s, Color(1, 1, 1, 0.8), 2.0, true)
		for ring in [12.0, 22.0, 30.0]:
			var pts := PackedVector2Array()
			for k in 7:
				pts.append(Vector2.from_angle(TAU * k / 6.0) * ring * s)
			draw_polyline(pts, Color(1, 1, 1, 0.7), 1.5, true)
	elif SEA.has(insect):
		for k in 3:
			DrawUtil.oval(self, Vector2(-16 + k * 16, -6 + (k % 2) * 8) * s, Vector2(14, 18) * s, Color("ff8a8a").lerp(Color("c77dff"), k * 0.4), o, 3.0)
		DrawUtil.oval(self, Vector2(0, 14) * s, Vector2(10, 7) * s, Color("1f4f6f"), o, 2.5)
	elif is_flyer_nest():
		draw_line(Vector2(0, -26), Vector2(0, -70), o, 4.0, true)
		var col := Color("f2b84b")
		if insect == "wasp":
			col = Color("cfc4b4")
		elif insect == "moth":
			col = Color("c4b0e0")
		elif insect == "broca":
			col = Color("a07a5a")
		for i in 4:
			var w := (24.0 - absf(i - 1.5) * 5.0) * s
			DrawUtil.oval(self, Vector2(0, -18 + i * 12.0) * s, Vector2(w, 9.0 * s), col, o, 3.0)
		DrawUtil.oval(self, Vector2(0, 16) * s, Vector2(8, 6) * s, Color("5a3a2a"), o, 2.5)
	else:
		var mound := PackedVector2Array()
		for i in 13:
			var a := PI + PI * float(i) / 12.0
			mound.append(Vector2(cos(a) * 34.0 * s, 20.0 + sin(a) * 32.0 * s))
		DrawUtil.shape(self, mound, Color("f0c97c") if insect == "crab" else Color("c08552"))
		DrawUtil.oval(self, Vector2(0, -6), Vector2(8, 5) * s, Color("5a3a2a"), o, 2.5)
	if remaining > 0:
		var font := ThemeDB.fallback_font
		var label := "x%d" % remaining
		var pos := Vector2(18, -30) if is_hanging() else Vector2(18, -22)
		if hole:
			pos = Vector2(20, -34)
		DrawUtil.disc(self, pos + Vector2(12, -6), 14.0, Palette.WHITE, o, 2.5)
		draw_string(font, pos + Vector2(0, 0), label, HORIZONTAL_ALIGNMENT_CENTER, 24, 15, o)


func _draw_hole(o: Color, s: float) -> void:
	# buraco no chão (desenhado sobre a grama), com aviso pulsante enquanto aberto
	DrawUtil.oval(self, Vector2(0, -2), Vector2(24, 9) * s, Color("5a3a2a"), o, 3.0)
	DrawUtil.oval(self, Vector2(0, 0), Vector2(15, 5) * s, Color("2b1d18"), o, 0.0)
	if plugged:
		draw_line(Vector2(-14, -12), Vector2(14, -12), Palette.UI_GOOD, 4.0, true)
		return
	if insect in ["broca", "drillfish"]:
		var marker := Vector2(0, -24)
		DrawUtil.oval(self, marker, Vector2(10, 5), Color("94dbe4") if insect == "drillfish" else Palette.GOLD, o, 2)
		DrawUtil.tri(self, marker + Vector2(8, -5), marker + Vector2(20, 0), marker + Vector2(8, 5), Color("d1e3e8"), o, 2)
	if not running:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_arc(Vector2(0, -2), 30.0 + pulse * 4.0, PI, TAU, 16, Color(Palette.DANGER, 0.6), 3.0, true)
