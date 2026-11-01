class_name TermiteQueen
extends Node2D
## Rainha Térmita (chefona, sem violência): mora numa toca grande e, durante a fase,
## ABRE TÚNEIS novos no chão. Cada túnel avisa antes (rachadura pulsando por 1,4 s) no ponto
## exato onde vai abrir; depois vira um buraco de onde saem cupins/formigas.
## Bloqueio justo: deixar pernas/pontas do abrigo em cima de onde a rachadura aparece.
## cfg: {"kind": "termite_queen", "pos": [x, y], "tunnels": [[x, t], ...], "insect": "termite",
##       "count": 3, "interval": 0.6, "floor": 1000}

const WARN := 1.4

var level: Level
var tunnels: Array = []
var insect := "termite"
var count := 3
var interval := 0.6
var floor_y := 1000.0
var running := false
var _t := 0.0
var _opened: Dictionary = {}
var _anim := 0.0


func setup(p_level: Level, cfg: Dictionary) -> void:
	level = p_level
	position = Level._v(cfg.get("pos", [600, 1000]))
	tunnels = cfg.get("tunnels", [])
	insect = str(cfg.get("insect", "termite"))
	count = int(cfg.get("count", 3))
	interval = float(cfg.get("interval", 0.6))
	floor_y = float(cfg.get("floor", 1000.0))
	z_index = 22


func begin() -> void:
	running = true


func _physics_process(delta: float) -> void:
	if not running or level == null or not level.is_running():
		return
	_t += delta
	for i in tunnels.size():
		var t: float = float(tunnels[i][1])
		if not _opened.has(i) and _t >= t:
			_opened[i] = true
			_open(float(tunnels[i][0]))


func _open(x: float) -> void:
	var nest := Nest.new()
	nest.position = Vector2(x, floor_y)
	nest.setup(level, {"insect": insect, "count": count, "interval": interval, "delay": 0.2, "hole": true})
	level.world.add_child(nest)
	level.nests.append(nest)
	nest.begin()
	level.shake(5.0)
	_anim = 1.0
	Sfx.play("beetle_step", 0.0, 0.5)
	Fx.dust(level.fx_layer, Vector2(x, floor_y))
	Fx.popup_text(level.fx_layer, Vector2(x, floor_y - 40), "Túnel!", Palette.DANGER, 0.9)


func _process(delta: float) -> void:
	_anim = maxf(0.0, _anim - delta * 2.0)
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	# a rainha espiando da toca (grande, de coroa)
	var bob := sin(Time.get_ticks_msec() / 400.0) * 3.0 - _anim * 12.0
	DrawUtil.oval(self, Vector2(0, 6), Vector2(64, 20), Color("5a3a2a"), o, 4.0)
	DrawUtil.oval(self, Vector2(0, -16 + bob), Vector2(46, 30), Color("f3e3c3"), o, 4.0)
	DrawUtil.disc(self, Vector2(30, -36 + bob), 22.0, Color("c98a4a"), o, 4.0)
	for s in [-1.0, 1.0]:
		draw_line(Vector2(44, -36 + bob + s * 6), Vector2(62, -36 + bob + s * 12), o, 4.0, true)
	DrawUtil.disc(self, Vector2(34, -44 + bob), 6.0, Palette.WHITE, o, 2.5)
	draw_circle(Vector2(36, -44 + bob), 3.0, o, true, -1.0, true)
	DrawUtil.shape(self, PackedVector2Array([Vector2(16, -56 + bob), Vector2(20, -72 + bob), Vector2(28, -60 + bob), Vector2(34, -76 + bob), Vector2(40, -60 + bob), Vector2(46, -72 + bob), Vector2(46, -56 + bob)]), Palette.GOLD, o, 2.5)
	# rachaduras avisando onde os túneis vão abrir
	if not running:
		return
	for i in tunnels.size():
		if _opened.has(i):
			continue
		var left: float = float(tunnels[i][1]) - _t
		if left > WARN:
			continue
		var p := to_local(Vector2(float(tunnels[i][0]), floor_y))
		var pulse := 0.5 + 0.5 * sin(_t * 18.0)
		var k := 1.0 - left / WARN
		for s in [-1.0, 1.0]:
			draw_polyline(PackedVector2Array([p + Vector2(0, -4), p + Vector2(s * 10 * k, -10), p + Vector2(s * 18 * k, -4), p + Vector2(s * 26 * k, -12)]), Color(Palette.DANGER, 0.5 + 0.5 * pulse), 4.0, true)
		draw_arc(p + Vector2(0, -4), 30.0 + pulse * 6.0, PI, TAU, 16, Color(Palette.DANGER, 0.6), 3.0, true)
