class_name SplashScreen
extends Control
## Abertura "Desenvolvido por RetroNexa": o Pingo entra rolando enroladinho, pula de letra em
## letra (cada uma amassa no pulo), cai no buraco do "o" e vira a letra — desenrola, pisca
## e sorri. Logo oficial: fundo índigo, "RetroNexa" em Inter Bold branco, site embaixo.
## O mesmo logo em PNG está em assets/brand/ (tools/make_brand.py). Toque para pular.

signal go(screen: String, arg: Variant)

const BRAND := "RetroNexa"
const SITE := "retronexa.com.br"
const SLOT := 4                     # o "o" de Retro: é ali que o Pingo cai
const INDIGO := Color8(78, 69, 220)
const INDIGO_LIGHT := Color8(98, 90, 236)
const SOFT := Color8(225, 223, 255)
const FONT_BOLD := preload("res://assets/fonts/Inter-Bold.otf")
const FONT_MEDIUM := preload("res://assets/fonts/Inter-Medium.otf")

## Tempo da animação (segundos)
const T_ENTER := 0.9                # o Pingo aparece
const HOP := 0.42                   # duração de cada pulo entre letras
const HOP_LETTERS := [0, 1, 2, 3]   # R, e, t, r — depois cai no "o"
const T_LAND := T_ENTER + HOP * 5.0
const SETTLE := [[0.28, 26.0], [0.2, 10.0]]
const T_UNCURL := T_LAND + 0.48 + 0.15
const DURATION := T_UNCURL + 2.3

var _t := 0.0
var _done := false
var _reduce := false
var _pingo: AnimalArt
var _squash: Array[float] = []      # amassado de cada letra (0..1)
var _ball_squash := 0.0
var _hops_done := 0
var _uncurled := false
var _layout := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reduce = bool(Game.setting("reduce_motion"))
	for i in BRAND.length():
		_squash.append(0.0)
	_pingo = AnimalArt.new()
	_pingo.species = "pingo"
	_pingo.preview = true
	_pingo.mood = "scared"          # enroladinho, só os olhinhos espiando
	_pingo.visible = false
	add_child(_pingo)
	if _reduce:
		_t = T_LAND + 0.5


func _process(delta: float) -> void:
	_t += delta
	for i in _squash.size():
		_squash[i] = maxf(_squash[i] - delta * 3.5, 0.0)
	_ball_squash = maxf(_ball_squash - delta * 5.0, 0.0)
	_update_layout()
	_update_pingo()
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


# ------------------------------------------------------------------ layout das letras
func _update_layout() -> void:
	var w := size.x
	var fs := int(minf(w * 0.135, 130.0))
	var center := Vector2(w * 0.5, size.y * 0.46)
	var total_w := FONT_BOLD.get_string_size(BRAND, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var xs: Array[float] = []
	var ws: Array[float] = []
	for i in BRAND.length():
		xs.append((w - total_w) * 0.5 + FONT_BOLD.get_string_size(BRAND.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		ws.append(FONT_BOLD.get_string_size(BRAND[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	_layout = {"fs": fs, "center": center, "base": center.y + fs * 0.36, "xs": xs, "ws": ws,
		"xh": fs * 0.55, "cap": fs * 0.73, "r": fs * 0.29}


## Ponto onde o Pingo pousa: em cima da letra i (ou dentro do "o" quando i == SLOT).
func _perch(i: int) -> Vector2:
	var xs: Array = _layout["xs"]
	var ws: Array = _layout["ws"]
	var x: float = xs[i] + ws[i] * 0.5
	var base: float = _layout["base"]
	var r: float = _layout["r"]
	if i == SLOT:
		return Vector2(x, base - _layout["xh"] * 0.5)
	var tall := "RtNh".contains(BRAND[i])
	return Vector2(x, base - (_layout["cap"] if tall else _layout["xh"]) - r * 0.95)


# ------------------------------------------------------------------ o Pingo
func _update_pingo() -> void:
	if _layout.is_empty():
		return
	var r: float = _layout["r"]
	var sc := r / 34.0
	_pingo.visible = _t >= T_ENTER
	var pos := _perch(SLOT)
	var rot := 0.0
	if _t < T_LAND:
		var k := int((_t - T_ENTER) / HOP)
		var f := fmod(_t - T_ENTER, HOP) / HOP
		var from := Vector2(-r * 3.0, _perch(0).y - 220.0) if k == 0 else _perch(HOP_LETTERS[k - 1])
		var to := _perch(HOP_LETTERS[k]) if k < HOP_LETTERS.size() else _perch(SLOT)
		var arc := 110.0 if k >= HOP_LETTERS.size() else 70.0
		pos = from.lerp(to, f) + Vector2(0, -arc * 4.0 * f * (1.0 - f))
		rot = (_t - T_ENTER) * 9.0
		if k > _hops_done:
			_bounce_on(HOP_LETTERS[k - 1], k)
	elif _hops_done <= HOP_LETTERS.size():
		_bounce_on(SLOT, HOP_LETTERS.size() + 1)
	else:
		# pulinhos que vão diminuindo dentro do "o"
		var tt := _t - T_LAND
		for s in SETTLE:
			if tt < s[0]:
				var f: float = tt / float(s[0])
				pos.y -= float(s[1]) * 4.0 * f * (1.0 - f)
				break
			tt -= float(s[0])
	if _t >= T_UNCURL and not _uncurled:
		_uncurled = true
		_pingo.mood = "idle"
		_pingo.look = Vector2(-0.2, 0.3)
		_ball_squash = 1.0
		Sfx.play("pop", 0.0, 1.5)
		Sfx.play("retro_jingle", -2.0)
	if _uncurled and _t > T_UNCURL + 0.55 and _t < T_UNCURL + 1.4:
		_pingo.mood = "happy"
	elif _uncurled and _t >= T_UNCURL + 1.4:
		_pingo.mood = "idle"
	var squ := Vector2(1.0 + 0.25 * _ball_squash, 1.0 - 0.25 * _ball_squash)
	_pingo.scale = squ * sc * (0.9 if _uncurled else 1.0)
	_pingo.rotation = 0.0 if _uncurled else rot
	_pingo.position = pos + Vector2(0, r * 0.25 * _ball_squash)


func _bounce_on(letter: int, count: int) -> void:
	_hops_done = count
	_ball_squash = 1.0
	if letter != SLOT:
		_squash[letter] = 1.0
		Sfx.play("pop", -4.0, 0.9 + letter * 0.12)
	else:
		Sfx.play("bonk", -2.0, 1.4)


# ------------------------------------------------------------------ desenho
func _draw() -> void:
	if _layout.is_empty():
		return
	var w := size.x
	var h := size.y
	var fade_out := clampf((DURATION - _t) / 0.4, 0.0, 1.0)
	draw_rect(Rect2(0, 0, w, h), INDIGO, true)
	var center: Vector2 = _layout["center"]
	for i in 16:
		var rr := minf(w, h) * (0.64 - i * 0.032)
		draw_circle(center, rr, Color(INDIGO_LIGHT, 0.04 * clampf(_t / 0.8, 0.0, 1.0)), true, -1.0, true)
	var fs: int = _layout["fs"]
	var base: float = _layout["base"]
	var xs: Array = _layout["xs"]
	var ws: Array = _layout["ws"]
	# letras (menos o "o", que é o Pingo); amassam quando ele pula em cima
	for i in BRAND.length():
		if i == SLOT:
			continue
		var k := clampf((_t - 0.2 - i * 0.05) / 0.35, 0.0, 1.0)
		if k <= 0.0:
			continue
		var e := 1.0 - pow(1.0 - k, 3.0)
		var sq: float = _squash[i]
		var wob := sin(sq * PI * 2.0) * 0.08
		var scale_l := Vector2(1.0 + 0.2 * sq + wob, 1.0 - 0.32 * sq - wob)
		var pivot := Vector2(float(xs[i]) + float(ws[i]) * 0.5, base + (1.0 - e) * 30.0)
		draw_set_transform(pivot, 0.0, scale_l)
		draw_string(FONT_BOLD, Vector2(-float(ws[i]) * 0.5, 0), BRAND[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, k * fade_out))
	draw_set_transform(Vector2.ZERO)
	# sombrinha do Pingo no chão das letras
	if _pingo.visible:
		var px := _pingo.position.x
		var dist := clampf((base - _pingo.position.y) / 300.0, 0.0, 1.0)
		DrawUtil.oval(self, Vector2(px, base + 6.0), Vector2(_layout["r"] * (1.0 - dist * 0.5), 5.0), Color(0, 0, 0, 0.18 * (1.0 - dist)), Color(0, 0, 0, 0), 0.0)
	_pingo.modulate.a = fade_out
	# "desenvolvido por" em cima, site embaixo (o site chega quando o Pingo vira a letra)
	var a_top := clampf((_t - 0.1) / 0.4, 0.0, 1.0) * fade_out
	draw_string(FONT_MEDIUM, Vector2(0, center.y - fs * 0.72), tr("desenvolvido por"), HORIZONTAL_ALIGNMENT_CENTER, w, int(fs * 0.24), Color(SOFT, 0.8 * a_top))
	var a_site := clampf((_t - T_UNCURL - 0.2) / 0.45, 0.0, 1.0) * fade_out
	draw_string(FONT_MEDIUM, Vector2(0, base + fs * 0.78 + (1.0 - a_site) * 10.0), SITE, HORIZONTAL_ALIGNMENT_CENTER, w, int(fs * 0.36), Color(SOFT, a_site))
	draw_string(FONT_MEDIUM, Vector2(0, h - 60), tr("toque para continuar"), HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(1, 1, 1, 0.4 * a_site))
