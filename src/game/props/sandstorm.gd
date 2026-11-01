class_name Sandstorm
extends Node2D
## Tempestade de areia: uma faixa de poeira que vai e volta, escondendo parte da tela.
## Só visual (não empurra nada): é preciso planejar antes de a poeira cobrir.
## cfg: {"type": "sandstorm", "rect": [x, y, w, h], "on": 2.5, "off": 2.0, "delay": 1.5}

var rect := Rect2()
var on_time := 2.5
var off_time := 2.0
var delay := 1.5
var level: Level
var _t := 0.0


func setup(p_level: Level, cfg: Dictionary) -> void:
	level = p_level
	var r: Array = cfg["rect"]
	rect = Rect2(r[0], r[1], r[2], r[3])
	on_time = float(cfg.get("on", 2.5))
	off_time = float(cfg.get("off", 2.0))
	delay = float(cfg.get("delay", 1.5))
	z_index = 60


func density() -> float:
	if level == null or not level.is_running():
		return 0.0
	var t := level._sim_time - delay
	if t < 0.0:
		return 0.0
	var phase := fposmod(t, on_time + off_time)
	if phase > on_time:
		return 0.0
	return clampf(minf(phase, on_time - phase) / 0.5, 0.0, 1.0)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var d := density()
	if d <= 0.0:
		return
	draw_rect(rect, Color(0.85, 0.68, 0.42, 0.82 * d), true)
	for i in 26:
		var y := rect.position.y + fmod(i * 47.0, rect.size.y)
		var x := rect.position.x + fmod(_t * 420.0 + i * 91.0, rect.size.x + 80.0) - 40.0
		draw_line(Vector2(x, y), Vector2(x + 40.0, y + 3.0), Color(1, 0.92, 0.75, 0.5 * d), 3.0, true)
