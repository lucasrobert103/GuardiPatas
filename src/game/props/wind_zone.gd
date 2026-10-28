class_name WindZone
extends Node2D
## Rajada de vento (ou correnteza, no mar): liga `on` s, desliga `off` s, em ciclo.
## Empurra linhas, caixas e insetos voadores dentro do retângulo (não os bichinhos).
## Antes de soprar, as folhinhas/bolhas avisam por 0,6 s.

var rect := Rect2()
var dir := Vector2.RIGHT
var force := 700.0
var on_time := 2.0
var off_time := 2.0
var delay := 1.0
var underwater := false
## Quanto os insetos/criaturas sentem o vento (as linhas sentem 100 %).
var insect_scale := 0.3
var active := false
var warning := false
var _cycle := 0.0
var _t := 0.0
var _running := false


func setup(cfg: Dictionary, p_underwater: bool) -> void:
	var r: Array = cfg["rect"]
	rect = Rect2(r[0], r[1], r[2], r[3])
	var d: Array = cfg.get("dir", [1, 0])
	dir = Vector2(float(d[0]), float(d[1])).normalized()
	force = float(cfg.get("force", 700))
	on_time = float(cfg.get("on", 2.0))
	off_time = float(cfg.get("off", 2.0))
	delay = float(cfg.get("delay", 1.0))
	insect_scale = float(cfg.get("insects", 0.3))
	underwater = p_underwater
	z_index = 25


func begin() -> void:
	_running = true
	_cycle = -delay


func tick(delta: float) -> void:
	if not _running:
		return
	_cycle += delta
	var period := on_time + off_time
	var phase := fposmod(_cycle, period) if _cycle >= 0.0 else -1.0
	var was := active
	active = phase >= 0.0 and phase < on_time
	warning = not active and ((phase >= period - 0.6) or (_cycle < 0.0 and _cycle > -0.6))
	if active and not was:
		Sfx.play("wasp_dash", -10.0, 0.5, 0.1, 0.2)


func push(body: RigidBody2D, scale: float = 1.0) -> void:
	if active and rect.has_point(body.global_position):
		body.apply_central_force(dir * force * body.mass * scale)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var col := Color(1, 1, 1, 0.5 if active else (0.3 if warning else 0.12))
	var step := 70.0
	var y := rect.position.y + 30.0
	var row := 0
	while y < rect.end.y:
		var x0 := rect.position.x + fmod(_t * (420.0 if active else 40.0) + row * 53.0, rect.size.x)
		var a := Vector2(x0, y)
		if dir.x < 0.0:
			a.x = rect.end.x - (x0 - rect.position.x)
		var b := a + dir * (60.0 if active else 26.0)
		if underwater:
			draw_arc(a, 4.0, 0.0, TAU, 8, col, 2.0, true)
		else:
			draw_line(a, b, col, 3.0, true)
			draw_arc(b + Vector2(0, -6), 6.0, PI * 0.5, PI * 1.8, 8, col, 3.0, true)
		y += step
		row += 1
	if warning:
		# folhinhas tremendo no canto de onde vem o vento
		var src := rect.position + Vector2(20, 40) if dir.x >= 0.0 else Vector2(rect.end.x - 20, rect.position.y + 40)
		for k in 3:
			DrawUtil.oval(self, src + Vector2(sin(_t * 30.0 + k) * 4.0, k * 26.0), Vector2(8, 4), Color("8fd16a"), Palette.OUTLINE, 2.0, 0.5)
