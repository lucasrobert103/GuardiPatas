class_name QueenBee
extends Node2D
## Rainha Zumbina (chefona, sem violência): paira no alto indo de um lado ao outro e,
## a cada poucos segundos, infla as bochechas (aviso visível de 1 s) e SOPRA uma rajada
## que empurra linhas, caixas e bichinhos para longe dela. As operárias saem do ninho dela.
## Bloqueio justo: abrigo baixo e pesado, travado em pedras.

const GUST_EVERY := 3.2
const WARN_TIME := 1.0
const GUST_IMPULSE := 320.0
const GUST_RANGE := 900.0

var level: Level
var home := Vector2(360, 300)
var sway := 200.0
var running := false
var _t := 0.0
var _gust_t := GUST_EVERY
var _puff := 0.0
var _blow := 0.0


func begin() -> void:
	running = true


func _physics_process(delta: float) -> void:
	if not running or level == null:
		return
	_t += delta
	position = home + Vector2(sin(_t * 0.7) * sway, sin(_t * 1.4) * 20.0)
	if level.state != Level.State.RUNNING:
		_puff = 0.0
		return
	_gust_t -= delta
	_puff = clampf(1.0 - _gust_t / WARN_TIME, 0.0, 1.0) if _gust_t < WARN_TIME else 0.0
	if _gust_t <= 0.0:
		_gust_t = GUST_EVERY
		_gust()
	_blow = maxf(_blow - delta * 2.0, 0.0)


func _gust() -> void:
	_blow = 1.0
	Sfx.play("wasp_dash", -2.0, 0.6)
	level.shake(6.0)
	var bodies: Array = []
	bodies.append_array(level.lines)
	bodies.append_array(level.props)
	bodies.append_array(level.animals)
	for b in bodies:
		if not is_instance_valid(b):
			continue
		var body := b as RigidBody2D
		if body == null or body.freeze:
			continue
		var to := body.global_position - global_position
		if to.length() > GUST_RANGE:
			continue
		var dir := Vector2(to.x, maxf(to.y, 0.0)).normalized()
		body.apply_central_impulse(dir * GUST_IMPULSE * clampf(body.mass / 3.0, 0.4, 1.0))
	for i in level.insects:
		if is_instance_valid(i):
			var away := (i.global_position - global_position).normalized()
			i.apply_central_impulse(away * 120.0 * i.mass)
			i.daze(0.4)
	Fx.dust(level.fx_layer, global_position + Vector2(0, 60))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	var flap := 0.6 + 0.4 * absf(sin(_t * 20.0))
	DrawUtil.oval(self, Vector2(-14, -40 * flap), Vector2(26, 34 * flap), Color(1, 1, 1, 0.8), o, 3.0, -0.4)
	DrawUtil.oval(self, Vector2(18, -40 * flap), Vector2(24, 32 * flap), Color(1, 1, 1, 0.85), o, 3.0, 0.4)
	DrawUtil.oval(self, Vector2.ZERO, Vector2(52, 40), Palette.GOLD, o, 5.0)
	for x in [-18.0, 6.0, 28.0]:
		var h := 40.0 * sqrt(maxf(1.0 - (x / 52.0) * (x / 52.0), 0.0))
		draw_line(Vector2(x, -h + 3), Vector2(x, h - 3), o, 9.0, true)
	# coroa
	DrawUtil.shape(self, PackedVector2Array([Vector2(-18, -36), Vector2(-18, -56), Vector2(-8, -46), Vector2(0, -62), Vector2(8, -46), Vector2(18, -56), Vector2(18, -36)]), Palette.GOLD, o, 3.0)
	draw_circle(Vector2(0, -46), 4.0, Color("ff5a7a"), true, -1.0, true)
	# rosto: bochechas que inflam antes da rajada
	var cheek := 8.0 + _puff * 9.0
	draw_circle(Vector2(-18, 12), cheek, Color(1.0, 0.56, 0.68, 0.9), true, -1.0, true)
	draw_circle(Vector2(18, 12), cheek, Color(1.0, 0.56, 0.68, 0.9), true, -1.0, true)
	DrawUtil.disc(self, Vector2(-14, -6), 8.0, Palette.WHITE, o, 2.5)
	DrawUtil.disc(self, Vector2(14, -6), 8.0, Palette.WHITE, o, 2.5)
	draw_circle(Vector2(-13, -5), 4.0, o, true, -1.0, true)
	draw_circle(Vector2(15, -5), 4.0, o, true, -1.0, true)
	if _puff > 0.0:
		DrawUtil.disc(self, Vector2(0, 22), 5.0 + _puff * 3.0, Color("7a2e3a"), o, 2.0)
		DrawUtil.disc(self, Vector2(0, -78), 13.0, Palette.GOLD, o, 2.5)
		draw_line(Vector2(0, -86), Vector2(0, -76), o, 3.0, true)
		draw_circle(Vector2(0, -71), 1.8, o, true, -1.0, true)
	else:
		DrawUtil.arc(self, Vector2(0, 16), 9.0, 0.3, PI - 0.3, o, 3.0)
	if _blow > 0.0:
		for k in 4:
			var y := 40.0 + k * 22.0 * (1.0 + (1.0 - _blow))
			draw_arc(Vector2(0, y), 30.0 + k * 16.0, 0.4, PI - 0.4, 14, Color(1, 1, 1, _blow * 0.7), 4.0, true)
