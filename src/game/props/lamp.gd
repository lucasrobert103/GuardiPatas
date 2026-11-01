class_name Lamp
extends StaticBody2D
## Lâmpada/lanterna: atrai mariposas enquanto estiver acesa.
## `duration` < 0 = sempre acesa; senão apaga depois de N segundos de simulação
## (um contador visível mostra quanto falta — nada de surpresa injusta).

var duration := -1.0
var time_left := -1.0
var lit := true
var _t := 0.0


func setup(p_duration: float) -> void:
	duration = p_duration
	time_left = p_duration
	collision_layer = Layers.TERRAIN
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 16.0
	cs.shape = c
	add_child(cs)


## Lâmpada ritmada: acende `on` s e apaga `off` s, sem parar (mostra o tempo para virar).
var rhythm_on := 0.0
var rhythm_off := 0.0
var _rhythm_t := 0.0


func set_rhythm(on: float, off: float, delay: float) -> void:
	rhythm_on = on
	rhythm_off = off
	_rhythm_t = -delay
	duration = -1.0


func rhythm_left() -> float:
	if rhythm_on <= 0.0:
		return -1.0
	var phase := fposmod(_rhythm_t, rhythm_on + rhythm_off)
	return (rhythm_on - phase) if phase < rhythm_on else (rhythm_on + rhythm_off - phase)


func tick(delta: float) -> void:
	if rhythm_on > 0.0:
		_rhythm_t += delta
		var was := lit
		lit = _rhythm_t < 0.0 or fposmod(_rhythm_t, rhythm_on + rhythm_off) < rhythm_on
		if was != lit:
			Sfx.play("ui_back" if not lit else "ui_click", -6.0, 0.6 if not lit else 1.2)
		return
	if duration < 0.0 or not lit:
		return
	time_left -= delta
	if time_left <= 0.0:
		lit = false
		Sfx.play("ui_back", -6.0, 0.6)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	draw_line(Vector2(0, -16), Vector2(0, -60), o, 3.0, true)
	if lit:
		var pulse := 1.0 + 0.06 * sin(_t * 5.0)
		draw_circle(Vector2.ZERO, 70.0 * pulse, Color(1.0, 0.92, 0.55, 0.16), true, -1.0, true)
		draw_circle(Vector2.ZERO, 42.0 * pulse, Color(1.0, 0.92, 0.55, 0.25), true, -1.0, true)
	DrawUtil.disc(self, Vector2.ZERO, 16.0, Color("ffe08a") if lit else Color("9a93a8"), o, 3.5)
	draw_rect(Rect2(-9, -22, 18, 8), Color("8a8aa0"), true)
	draw_rect(Rect2(-9, -22, 18, 8), o, false, 2.5, true)
	if lit and duration > 0.0:
		var frac := clampf(time_left / duration, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 24.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 24, Palette.GOLD_DARK, 4.0, true)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-20, 46), "%.0fs" % ceilf(time_left), HORIZONTAL_ALIGNMENT_CENTER, 40, 18, o)
