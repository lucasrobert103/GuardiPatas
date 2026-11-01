class_name ToyTrain
extends AnimatableBody2D
## Trenzinho de brinquedo: apita (seta piscando na borda) e atravessa a tela pelo trilho,
## EMPURRANDO tudo o que estiver no caminho: linhas, caixas, insetos e bichinhos.
## Bloqueio justo: deixar o abrigo fora do trilho (apoiado em blocos acima dele).
## cfg: {"type": "train", "y": 975, "dir": 1, "every": 6.0, "delay": 2.0, "speed": 300}

const LENGTH := 210.0
const HEIGHT := 44.0
const WARN := 1.2

var level: Level
var y := 975.0
var dir := 1.0
var every := 6.0
var delay := 2.0
var speed := 300.0
var running := false
var _t := 0.0
var _x := -400.0
var _moving := false
var _next := 0.0
var _wheel := 0.0


func setup(p_level: Level, cfg: Dictionary) -> void:
	level = p_level
	y = float(cfg.get("y", 975.0))
	dir = signf(float(cfg.get("dir", 1.0)))
	every = float(cfg.get("every", 6.0))
	delay = float(cfg.get("delay", 2.0))
	speed = float(cfg.get("speed", 300.0))
	collision_layer = Layers.TERRAIN
	collision_mask = 0
	sync_to_physics = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(LENGTH, HEIGHT)
	cs.shape = r
	add_child(cs)
	_park()
	z_index = -1  # passa "por trás" dos blocos de terreno, como num túnel


func _park() -> void:
	_moving = false
	_x = -LENGTH - 200.0 if dir > 0 else 720.0 + LENGTH + 200.0
	position = Vector2(_x, y)


func begin() -> void:
	running = true
	_next = delay


func warning() -> bool:
	return running and not _moving and _next - _t < WARN and _next - _t > 0.0


func _physics_process(delta: float) -> void:
	if not running or level == null or not level.is_running():
		return
	_t += delta
	if not _moving and _t >= _next:
		_moving = true
		_x = -LENGTH * 0.5 - 30.0 if dir > 0 else 720.0 + LENGTH * 0.5 + 30.0
		Sfx.play("ui_click", 0.0, 0.5)
	if _moving:
		_x += dir * speed * delta
		_wheel += delta * speed * 0.05
		position = Vector2(_x, y)
		if (dir > 0 and _x > 720.0 + LENGTH) or (dir < 0 and _x < -LENGTH):
			_park()
			_next = _t + every


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	if warning():
		# seta piscando na borda de onde ele vem
		var blink := absf(sin(_t * 14.0))
		var edge := to_local(Vector2(30.0 if dir > 0 else 690.0, y - 30.0))
		DrawUtil.tri(self, edge + Vector2(-dir * 18, -18), edge + Vector2(dir * 22, 0), edge + Vector2(-dir * 18, 18), Color(Palette.DANGER, 0.4 + 0.6 * blink), o, 3.0)
	if not _moving:
		return
	var half := Vector2(LENGTH, HEIGHT) * 0.5
	var cars := [Color("ff6b6b"), Color("5ec8f2"), Color("ffd23f")]
	for k in 3:
		var cx := -half.x + 35.0 + k * 70.0
		draw_rect(Rect2(Vector2(cx - 32, -half.y), Vector2(64, HEIGHT - 10)), cars[k], true)
		draw_rect(Rect2(Vector2(cx - 32, -half.y), Vector2(64, HEIGHT - 10)), o, false, 3.0)
		for wx in [-18.0, 18.0]:
			DrawUtil.disc(self, Vector2(cx + wx, half.y - 8), 9.0, Color("3a2b3c"), o, 2.0)
			draw_line(Vector2(cx + wx, half.y - 8), Vector2(cx + wx, half.y - 8) + Vector2.from_angle(_wheel) * 7.0, Palette.WHITE, 2.0, true)
	var front := Vector2(dir * (half.x - 20.0), -half.y - 14.0)
	draw_rect(Rect2(front + Vector2(-8, 0), Vector2(16, 16)), Color("3a2b3c"), true)
	for k in 3:
		var p := front + Vector2(-dir * k * 14.0, -10.0 - k * 12.0 - fmod(_t * 40.0, 12.0))
		draw_circle(p, 6.0 + k * 2.0, Color(1, 1, 1, 0.7 - k * 0.2), true, -1.0, true)
