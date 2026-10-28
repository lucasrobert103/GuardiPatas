class_name SplashScreen
extends Control
## Abertura "Desenvolvido por RetroNexa" com o logo oficial redesenhado: fundo índigo,
## "RetroNexa" em branco (Inter Bold) com as letras subindo uma a uma, e o site embaixo.
## O mesmo logo em PNG está em assets/brand/ (gerado por tools/make_brand.py). Toque para pular.

signal go(screen: String, arg: Variant)

const BRAND := "RetroNexa"
const SITE := "retronexa.com.br"
const DURATION := 3.6
const INDIGO := Color8(78, 69, 220)
const INDIGO_LIGHT := Color8(98, 90, 236)
const SOFT := Color8(225, 223, 255)
const FONT_BOLD := preload("res://assets/fonts/Inter-Bold.otf")
const FONT_MEDIUM := preload("res://assets/fonts/Inter-Medium.otf")

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
	var fade_out := clampf((DURATION - _t) / 0.4, 0.0, 1.0)
	draw_rect(Rect2(0, 0, w, h), INDIGO, true)
	# brilho suave atrás do logo
	var center := Vector2(w * 0.5, h * 0.46)
	for i in 16:
		var r := minf(w, h) * (0.64 - i * 0.032)
		draw_circle(center, r, Color(INDIGO_LIGHT, 0.04 * clampf(_t / 0.8, 0.0, 1.0)), true, -1.0, true)
	# palavra: as letras sobem uma a uma (posições pelo prefixo, mantendo o kerning)
	var fs := int(minf(w * 0.135, 130.0))
	var total_w := FONT_BOLD.get_string_size(BRAND, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x0 := (w - total_w) * 0.5
	var base_y := center.y + fs * 0.36
	for i in BRAND.length():
		var k := clampf((_t - 0.25 - i * 0.06) / 0.4, 0.0, 1.0)
		if k <= 0.0:
			continue
		var e := 1.0 - pow(1.0 - k, 3.0)
		var x := x0 + FONT_BOLD.get_string_size(BRAND.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(FONT_BOLD, Vector2(x, base_y + (1.0 - e) * 36.0), BRAND[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, k * fade_out))
	# "desenvolvido por" em cima, site embaixo
	var a_top := clampf((_t - 0.1) / 0.4, 0.0, 1.0) * fade_out
	draw_string(FONT_MEDIUM, Vector2(0, center.y - fs * 0.72), tr("desenvolvido por"), HORIZONTAL_ALIGNMENT_CENTER, w, int(fs * 0.24), Color(SOFT, 0.8 * a_top))
	var a_site := clampf((_t - 1.0) / 0.45, 0.0, 1.0) * fade_out
	draw_string(FONT_MEDIUM, Vector2(0, base_y + fs * 0.78 + (1.0 - a_site) * 10.0), SITE, HORIZONTAL_ALIGNMENT_CENTER, w, int(fs * 0.36), Color(SOFT, a_site))
	draw_string(FONT_MEDIUM, Vector2(0, h - 60), tr("toque para continuar"), HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(1, 1, 1, 0.4 * a_site))
