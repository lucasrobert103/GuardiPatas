class_name SplashScreen
extends Control
## Abertura "Desenvolvido por RetroNexa" (retronexa.com.br), no estilo retrô/synthwave:
## sol listrado nascendo, grade em perspectiva e as letras caindo uma a uma com um jingle
## chiptune. Toque para pular.

signal go(screen: String, arg: Variant)

const BRAND := "RetroNexa"
const SITE := "retronexa.com.br"
const DURATION := 3.6
const PINK := Color("ff4fd8")
const CYAN := Color("4ff3ff")
const NIGHT := Color("120c2b")
const DUSK := Color("3a1c5c")

var _t := 0.0
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Sfx.play("retro_jingle", -2.0)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= DURATION:
		_finish()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and _t > 0.4:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	go.emit("title", null)


func _draw() -> void:
	var w := size.x
	var h := size.y
	DrawUtil.vgradient(self, Rect2(0, 0, w, h * 0.62), NIGHT, DUSK)
	draw_rect(Rect2(0, h * 0.62, w, h * 0.38), NIGHT, true)
	# estrelinhas
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 50:
		var p := Vector2(rng.randf_range(0, w), rng.randf_range(0, h * 0.5))
		var tw := 0.5 + 0.5 * sin(_t * 3.0 + i)
		draw_circle(p, rng.randf_range(1.0, 2.2), Color(1, 1, 1, 0.3 + 0.5 * tw), true, -1.0, true)
	# sol listrado nascendo
	var rise := clampf(_t / 1.2, 0.0, 1.0)
	var sun_c := Vector2(w * 0.5, h * 0.62 + 40.0 - rise * 150.0)
	var sun_r := minf(w * 0.32, 220.0)
	var bands := 24
	for i in bands:
		var y0 := sun_c.y - sun_r + i * sun_r * 2.0 / bands
		var y1 := y0 + sun_r * 2.0 / bands
		if i > bands * 0.55 and i % 2 == 1:
			continue
		var k := float(i) / bands
		var col := Color("ffd23f").lerp(PINK, k)
		var pts := PackedVector2Array()
		for yy in [y0, y1]:
			var dy: float = yy - sun_c.y
			var half := sqrt(maxf(sun_r * sun_r - dy * dy, 0.0))
			pts.append(Vector2(sun_c.x - half, yy))
			pts.append(Vector2(sun_c.x + half, yy))
		if pts.size() == 4:
			draw_colored_polygon(PackedVector2Array([pts[0], pts[1], pts[3], pts[2]]), col)
	draw_rect(Rect2(0, h * 0.62, w, h * 0.38), NIGHT, true)
	# grade em perspectiva correndo
	var horizon := h * 0.62
	var vp := Vector2(w * 0.5, horizon)
	for i in range(-10, 11):
		draw_line(vp, Vector2(w * 0.5 + i * w * 0.18, h), Color(PINK, 0.55), 2.0, true)
	for i in 12:
		var k := fmod(float(i) / 12.0 + _t * 0.35, 1.0)
		var y := horizon + (h - horizon) * k * k
		draw_line(Vector2(0, y), Vector2(w, y), Color(CYAN, 0.25 + 0.4 * k), 2.0, true)
	draw_line(Vector2(0, horizon), Vector2(w, horizon), Color(CYAN, 0.9), 3.0, true)
	# textos
	var font := UiKit.font()
	var fade_out := clampf((DURATION - _t) / 0.4, 0.0, 1.0)
	var a_top := clampf((_t - 0.3) / 0.4, 0.0, 1.0) * fade_out
	var center_y := h * 0.34
	draw_string(font, Vector2(0, center_y - 118), "DESENVOLVIDO POR", HORIZONTAL_ALIGNMENT_CENTER, w, 28, Color(1, 1, 1, a_top))
	var fs := int(minf(w / 5.2, 120.0))
	var total_w := font.get_string_size(BRAND, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := (w - total_w) * 0.5
	for i in BRAND.length():
		var ch := BRAND[i]
		var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var start := 0.45 + i * 0.08
		var k := clampf((_t - start) / 0.35, 0.0, 1.0)
		if k <= 0.0:
			x += cw
			continue
		var bounce := (1.0 - k) * -120.0 + sin(k * PI) * -14.0
		var col := PINK.lerp(CYAN, float(i) / (BRAND.length() - 1))
		col.a = k * fade_out
		var pos := Vector2(x, center_y + bounce)
		draw_string_outline(font, pos + Vector2(0, 6), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 14, Color(0, 0, 0, 0.5 * col.a))
		draw_string_outline(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color(1, 1, 1, col.a))
		draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		x += cw
	var a_site := clampf((_t - 1.4) / 0.4, 0.0, 1.0) * fade_out
	var line_w := total_w * clampf((_t - 1.2) / 0.5, 0.0, 1.0)
	draw_line(Vector2((w - line_w) * 0.5, center_y + 28), Vector2((w + line_w) * 0.5, center_y + 28), Color(CYAN, 0.9 * fade_out), 4.0, true)
	draw_string(font, Vector2(0, center_y + 78), SITE, HORIZONTAL_ALIGNMENT_CENTER, w, 34, Color(CYAN, a_site))
	draw_string(font, Vector2(0, h - 60), "toque para continuar", HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(1, 1, 1, 0.45 * a_site))
