class_name LineDrawer
extends Node2D
## Captura do traço: recebe posições do dedo (já em coordenadas do mundo), valida cada
## ponto contra obstáculos/zonas proibidas/orçamento de tinta e desenha a prévia.
## As consultas de física rodam no _physics_process (forma segura de usar o espaço físico).

signal stroke_finished(points: PackedVector2Array)
signal ink_changed(left: float, total: float)
signal stroke_started

const MIN_STEP := 8.0
const MAX_STEP := 18.0
const CLEARANCE := DrawnLine.THICKNESS * 0.5 + 3.0
const MIN_STROKE := 24.0

var ink_total := 800.0
var ink_left := 800.0
var enabled := true
var drawing := false
var points := PackedVector2Array()
var nodraw: Array[Rect2] = []
var bounds := Rect2(8, 150, 704, 1122)
var hint_strokes: Array = []

var _pending: Array[Vector2] = []
var _end_requested := false
var _blocked_at := Vector2.ZERO
var _blocked_t := 0.0
var _empty_warned := false
var _shape := CircleShape2D.new()
## Um pouco menor que `_shape`: a corda entre dois pontos livres que contornam um
## corpo convexo passa ~1 px mais perto dele; sem essa folga o traço "empacaria".
var _cast_shape := CircleShape2D.new()
var _t := 0.0
var _scribble_vol := -40.0


func _ready() -> void:
	_shape.radius = CLEARANCE
	_cast_shape.radius = CLEARANCE - 2.5


func setup(p_ink: float, p_nodraw: Array[Rect2]) -> void:
	ink_total = p_ink
	ink_left = p_ink
	nodraw = p_nodraw


# ------------------------------------------------------------------ entrada
func press(pos: Vector2) -> void:
	if not enabled or drawing:
		return
	if ink_left < MIN_STEP:
		_warn_empty()
		return
	drawing = true
	points.clear()
	_pending.clear()
	_pending.append(pos)
	_empty_warned = false


func move(pos: Vector2) -> void:
	if drawing:
		_pending.append(pos)


func release() -> void:
	if drawing:
		_end_requested = true


## Usado por testes/dicas: processa um traço inteiro de forma síncrona,
## passando pela MESMA validação do dedo.
func feed_stroke(pts: PackedVector2Array) -> bool:
	if pts.is_empty():
		return false
	press(pts[0])
	for i in range(1, pts.size()):
		move(pts[i])
	release()
	return _flush()


func _physics_process(_delta: float) -> void:
	_flush()


func _flush() -> bool:
	var finished := false
	if drawing:
		for p in _pending:
			_consume(p)
		_pending.clear()
		if _end_requested:
			_end_requested = false
			drawing = false
			finished = _finish()
	_update_scribble_sound()
	return finished


func _consume(p: Vector2) -> void:
	if points.is_empty():
		var start := _nudge_free(p)
		if start.is_finite():
			points.append(start)
			stroke_started.emit()
		else:
			_flag_blocked(p)
		return
	var last := points[points.size() - 1]
	var dist := last.distance_to(p)
	if dist < MIN_STEP:
		return
	# movimentos rápidos viram vários passos pequenos (cada um validado)
	var steps := int(ceil(dist / MAX_STEP))
	for s in steps:
		var target := last.lerp(p, float(s + 1) / float(steps))
		if not _extend_to(target):
			return
		last = points[points.size() - 1]


func _extend_to(target: Vector2) -> bool:
	var last := points[points.size() - 1]
	if ink_left <= 0.5:
		_warn_empty()
		return false
	var seg := target - last
	if seg.length() > ink_left:
		target = last + seg.normalized() * ink_left
		seg = target - last
	if not _in_bounds(target) or _in_nodraw(target):
		_flag_blocked(target)
		return false
	# o dedo encostou num obstáculo: o traço "contorna" para o ponto livre mais
	# próximo (abraça o bichinho/terreno) em vez de simplesmente parar
	if not _is_free(target):
		var nudged := _nudge_free(target, last)
		if not nudged.is_finite():
			_flag_blocked(target)
			return false
		target = nudged
		seg = target - last
		if seg.length() < 1.0:
			return false
	var safe := _cast(last, seg)
	if safe < 1.0:
		target = last + seg * maxf(safe - 0.05, 0.0)
		_flag_blocked(last + seg)
		if target.distance_to(last) < 2.0:
			return false
	if not _is_free(target):
		_flag_blocked(target)
		return false
	ink_left -= last.distance_to(target)
	points.append(target)
	ink_changed.emit(ink_left, ink_total)
	queue_redraw()
	return safe >= 1.0


func _finish() -> bool:
	var raw_len := LineMath.length(points)
	if points.size() < 2 or raw_len < MIN_STROKE:
		# toque acidental: devolve a tinta e ignora
		ink_left = minf(ink_left + raw_len, ink_total)
		ink_changed.emit(ink_left, ink_total)
		points.clear()
		queue_redraw()
		return false
	var prepared := LineMath.prepare_stroke(points)
	points.clear()
	queue_redraw()
	Sfx.play("draw_end", -4.0, 1.0, 0.1)
	stroke_finished.emit(prepared)
	return true


# ------------------------------------------------------------------ validação
func _in_bounds(p: Vector2) -> bool:
	return bounds.grow(-CLEARANCE).has_point(p)


func _in_nodraw(p: Vector2) -> bool:
	for r in nodraw:
		if r.grow(CLEARANCE).has_point(p):
			return true
	return false


func _is_free(p: Vector2) -> bool:
	if not _in_bounds(p) or _in_nodraw(p):
		return false
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = _shape
	q.transform = Transform2D(0.0, p)
	q.collision_mask = Layers.DRAW_BLOCK
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


## Procura, em anéis crescentes, o ponto livre mais próximo de `p` (até 18 px).
## Com `prefer`, desempata pelo candidato mais perto do ponto anterior do traço.
## Retorna Vector2(INF, INF) se não houver.
func _nudge_free(p: Vector2, prefer: Vector2 = Vector2(INF, INF)) -> Vector2:
	if _is_free(p):
		return p
	for r in [3.0, 6.0, 9.0, 12.0, 15.0, 18.0]:
		var best := Vector2(INF, INF)
		var best_d := INF
		for k in 16:
			var c: Vector2 = p + Vector2.from_angle(TAU * k / 16.0) * r
			if not _is_free(c):
				continue
			var d := c.distance_squared_to(prefer) if prefer.is_finite() else 0.0
			if d < best_d:
				best_d = d
				best = c
		if best.is_finite():
			return best
	return Vector2(INF, INF)


func _cast(from: Vector2, motion: Vector2) -> float:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = _cast_shape
	q.transform = Transform2D(0.0, from)
	q.motion = motion
	q.collision_mask = Layers.DRAW_BLOCK
	var res := get_world_2d().direct_space_state.cast_motion(q)
	if res.size() < 1:
		return 1.0
	return res[0]


var debug_log := false


func _flag_blocked(p: Vector2) -> void:
	if debug_log:
		print("      bloqueado em ", p, " tinta=", ink_left)
	if _blocked_t <= 0.0:
		Sfx.play("draw_blocked", -8.0, 1.0, 0.1, 0.25)
	_blocked_at = p
	_blocked_t = 0.5
	queue_redraw()


func _warn_empty() -> void:
	if _empty_warned:
		return
	_empty_warned = true
	Sfx.play("ink_empty", -2.0)
	Sfx.vibrate(40)


func _update_scribble_sound() -> void:
	var want := -10.0 if (drawing and points.size() > 1) else -40.0
	_scribble_vol = lerpf(_scribble_vol, want, 0.25)
	if _scribble_vol > -38.0:
		Sfx.loop("scribble", "draw_loop", _scribble_vol, 1.0 + randf_range(-0.05, 0.05))
	else:
		Sfx.stop_loop("scribble")


# ------------------------------------------------------------------ desenho
func _process(delta: float) -> void:
	_t += delta
	if _blocked_t > 0.0:
		_blocked_t -= delta
		queue_redraw()
	if not hint_strokes.is_empty():
		queue_redraw()


func _draw() -> void:
	for r in nodraw:
		draw_rect(r, Palette.NODRAW, true)
		var x := r.position.x - r.size.y
		while x < r.end.x:
			var a := Vector2(maxf(x, r.position.x), r.position.y + maxf(r.position.x - x, 0.0))
			var b := Vector2(minf(x + r.size.y, r.end.x), r.end.y - maxf(x + r.size.y - r.end.x, 0.0))
			draw_line(a, b, Color(Palette.DANGER, 0.45), 3.0, true)
			x += 22.0
		draw_rect(r, Color(Palette.DANGER, 0.8), false, 3.0, true)
	for stroke in hint_strokes:
		var pts: PackedVector2Array = stroke
		var dash := 0.0
		for i in range(1, pts.size()):
			var a := pts[i - 1]
			var b := pts[i]
			var l := a.distance_to(b)
			var k := 0.0
			while k < l:
				var on := fmod(dash + k + _t * 40.0, 24.0) < 13.0
				var e := minf(k + 6.0, l)
				if on:
					draw_line(a.lerp(b, k / l), a.lerp(b, e / l), Color(1, 1, 1, 0.85), 8.0, true)
				k = e
			dash += l
		if pts.size() > 0:
			var pulse := 10.0 + 3.0 * sin(_t * 6.0)
			draw_circle(pts[0], pulse, Color(Palette.GOLD, 0.8), true, -1.0, true)
	if points.size() >= 1:
		var low := ink_left / maxf(ink_total, 1.0) < 0.2
		var col := Palette.INK_LOW if low else Palette.INK
		if points.size() >= 2:
			draw_polyline(points, Palette.OUTLINE, DrawnLine.THICKNESS + Palette.OUTLINE_W * 2.0, true)
		draw_circle(points[0], DrawnLine.THICKNESS * 0.5 + Palette.OUTLINE_W, Palette.OUTLINE, true, -1.0, true)
		draw_circle(points[points.size() - 1], DrawnLine.THICKNESS * 0.5 + Palette.OUTLINE_W, Palette.OUTLINE, true, -1.0, true)
		if points.size() >= 2:
			draw_polyline(points, col, DrawnLine.THICKNESS, true)
		draw_circle(points[0], DrawnLine.THICKNESS * 0.5, col, true, -1.0, true)
		draw_circle(points[points.size() - 1], DrawnLine.THICKNESS * 0.5, col, true, -1.0, true)
	if _blocked_t > 0.0:
		var a := clampf(_blocked_t / 0.5, 0.0, 1.0)
		var c := Color(Palette.DANGER, a)
		draw_line(_blocked_at + Vector2(-9, -9), _blocked_at + Vector2(9, 9), c, 5.0, true)
		draw_line(_blocked_at + Vector2(-9, 9), _blocked_at + Vector2(9, -9), c, 5.0, true)
