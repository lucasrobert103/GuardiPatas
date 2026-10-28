class_name AnimalArt
extends Node2D
## Desenho vetorial procedural dos seis bichinhos, com expressões e animações
## (idle, susto, picadinha, comemoração, tristeza). Tudo virado para a direita;
## `facing = -1` espelha. Coordenadas casam com as formas de colisão de Animal.

var species := "capi"
var mood := "idle"          # idle | scared | ouch | happy | sad
var look := Vector2.RIGHT   # direção para onde as pupilas olham (perigo!)
var accessory := ""
var facing := 1.0
var shell_flash := 0.0
var preview := false        # usado nas telas de menu (sem física)

var _t := 0.0
var _blink := 0.0
var _next_blink := 2.5
var _mood_t := 0.0
var _last_mood := "idle"

const COLORS := {
	"capi": {"main": Color("b07a4f"), "light": Color("d9a77a"), "dark": Color("8a5a39")},
	"brasa": {"main": Color("ff8a3d"), "light": Color("fff1e0"), "dark": Color("d96a24")},
	"pingo": {"main": Color("6d5a8c"), "light": Color("f6dcb8"), "dark": Color("4e3f66")},
	"lulu": {"main": Color("ff9ec7"), "light": Color("ffd0e4"), "dark": Color("e0569b")},
	"tuca": {"main": Color("7cc576"), "light": Color("6fbf7f"), "dark": Color("3f8f5a")},
	"nino": {"main": Color("8f9bb3"), "light": Color("f3ead8"), "dark": Color("6b7690")},
	"gelinho": {"main": Color("2f3a5c"), "light": Color("ffffff"), "dark": Color("ff9f43")},
	"tata": {"main": Color("b0906a"), "light": Color("d9c2a0"), "dark": Color("7f6448")},
	"pompom": {"main": Color("fff6ee"), "light": Color("ffc2d4"), "dark": Color("e8d8cc")},
	"nuvem": {"main": Color("fbfbff"), "light": Color("e8e8f4"), "dark": Color("4a4458")},
	"fofa": {"main": Color("9fb0c2"), "light": Color("d4dee8"), "dark": Color("6f8196")},
	"tito": {"main": Color("c77dff"), "light": Color("e5bfff"), "dark": Color("9b4fd6")},
	"patinha": {"main": Color("ffd84d"), "light": Color("fff0a8"), "dark": Color("ff9f43")},
	"kiko": {"main": Color("9aa3ad"), "light": Color("e9ecef"), "dark": Color("5f6670")},
}

## Pontos de ancoragem para acessórios (cabeça, olhos, pescoço).
const ANCHORS := {
	"capi": {"head": Vector2(30, -34), "eyes": Vector2(37, -14), "neck": Vector2(18, 8), "scale": 1.0},
	"brasa": {"head": Vector2(2, -38), "eyes": Vector2(4, -20), "neck": Vector2(2, 4), "scale": 0.95},
	"pingo": {"head": Vector2(4, -30), "eyes": Vector2(16, -5), "neck": Vector2(12, 16), "scale": 0.85},
	"lulu": {"head": Vector2(20, -22), "eyes": Vector2(27, -6), "neck": Vector2(8, 10), "scale": 0.8},
	"tuca": {"head": Vector2(40, -16), "eyes": Vector2(43, -6), "neck": Vector2(28, 4), "scale": 0.7},
	"nino": {"head": Vector2(8, -26), "eyes": Vector2(9, -14), "neck": Vector2(6, 0), "scale": 0.7},
	"gelinho": {"head": Vector2(4, -34), "eyes": Vector2(8, -18), "neck": Vector2(4, -2), "scale": 0.8},
	"tata": {"head": Vector2(14, -16), "eyes": Vector2(22, -2), "neck": Vector2(16, 8), "scale": 0.6},
	"pompom": {"head": Vector2(2, -30), "eyes": Vector2(4, -12), "neck": Vector2(2, 6), "scale": 0.75},
	"nuvem": {"head": Vector2(20, -20), "eyes": Vector2(22, -2), "neck": Vector2(16, 14), "scale": 0.75},
	"fofa": {"head": Vector2(32, -26), "eyes": Vector2(36, -10), "neck": Vector2(22, 8), "scale": 0.8},
	"tito": {"head": Vector2(0, -28), "eyes": Vector2(0, -6), "neck": Vector2(0, 10), "scale": 0.9},
	"patinha": {"head": Vector2(12, -24), "eyes": Vector2(15, -12), "neck": Vector2(6, 0), "scale": 0.65},
	"kiko": {"head": Vector2(2, -34), "eyes": Vector2(3, -16), "neck": Vector2(2, 4), "scale": 0.8},
}


func _process(delta: float) -> void:
	_t += delta
	if mood != _last_mood:
		_last_mood = mood
		_mood_t = 0.0
	_mood_t += delta
	shell_flash = maxf(shell_flash - delta * 2.5, 0.0)
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.14
		_next_blink = randf_range(2.2, 4.5)
	_blink = maxf(_blink - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var off := Vector2.ZERO
	var sc := Vector2.ONE
	var rot := 0.0
	var reduce: bool = Game.setting("reduce_motion")
	match mood:
		"idle":
			var b := sin(_t * 2.4)
			sc = Vector2(1.0 - 0.012 * b, 1.0 + 0.03 * b)
		"scared":
			if not reduce:
				off.x = sin(_t * 55.0) * 1.6
			sc = Vector2(1.03, 0.95)
		"ouch":
			var k := clampf(_mood_t * 6.0, 0.0, 1.0)
			sc = Vector2.ONE * (1.0 + 0.12 * sin(k * PI))
			if not reduce:
				off.x = sin(_t * 70.0) * 3.0 * (1.0 - k)
		"happy":
			var hop := absf(sin(_t * 6.5))
			if not reduce:
				off.y = -hop * 16.0
			sc = Vector2(1.0 + 0.06 * (1.0 - hop), 1.0 - 0.06 * (1.0 - hop))
			rot = sin(_t * 6.5) * 0.06
		"sad":
			sc = Vector2(1.03, 0.93)
			off.y = 3.0
	# a escala pivota pela base para o bicho "amassar" no chão
	var base_y := _base_y()
	off.y += base_y * (1.0 - sc.y)
	draw_set_transform(off, rot, Vector2(sc.x * facing, sc.y))
	match species:
		"capi": _draw_capi()
		"brasa": _draw_brasa()
		"pingo": _draw_pingo()
		"lulu": _draw_lulu()
		"tuca": _draw_tuca()
		"nino": _draw_nino()
		"gelinho": _draw_gelinho()
		"tata": _draw_tata()
		"pompom": _draw_pompom()
		"nuvem": _draw_nuvem()
		"fofa": _draw_fofa()
		"tito": _draw_tito()
		"patinha": _draw_patinha()
		"kiko": _draw_kiko()
	_draw_accessory()
	draw_set_transform(Vector2.ZERO)
	if mood == "ouch":
		_draw_ouch_stars()
	elif mood == "scared" and not preview:
		_draw_sweat()


func _base_y() -> float:
	match species:
		"brasa": return 46.0
		"capi": return 30.0
		"tuca": return 24.0
		"lulu": return 18.0
		"nino": return 22.0
		"gelinho": return 36.0
		"tata": return 24.0
		"pompom": return 42.0
		"nuvem": return 32.0
		"fofa": return 24.0
		"tito": return 24.0
		"patinha": return 22.0
		"kiko": return 38.0
	return 28.0


func _c(key: String) -> Color:
	return COLORS[species][key]


# ------------------------------------------------------------------ rosto
func _eye(c: Vector2, r: float, style: String = "full") -> void:
	var o := Palette.OUTLINE
	var lk := look.limit_length(1.0)
	if _blink > 0.0 and mood in ["idle", "scared"]:
		draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), o, 3.0, true)
		return
	match mood:
		"happy":
			DrawUtil.arc(self, c + Vector2(0, r * 0.5), r * 0.9, PI * 1.12, PI * 1.88, o, 3.2)
			return
		"ouch":
			draw_line(c + Vector2(-r, -r * 0.7), c + Vector2(r * 0.6, 0), o, 3.0, true)
			draw_line(c + Vector2(r * 0.6, 0), c + Vector2(-r, r * 0.7), o, 3.0, true)
			return
	if style == "dot":
		var rr := r * (1.25 if mood == "scared" else 1.0)
		draw_circle(c + lk * r * 0.15, rr, o, true, -1.0, true)
		draw_circle(c + lk * r * 0.15 + Vector2(-rr * 0.35, -rr * 0.35), rr * 0.35, Palette.WHITE, true, -1.0, true)
		if mood == "sad":
			draw_line(c + Vector2(-r * 1.2, -r * 1.3), c + Vector2(r * 1.1, -r * 0.8), o, 2.5, true)
		return
	var white_r := r * (1.3 if mood == "scared" else 1.0)
	DrawUtil.disc(self, c, white_r, Palette.WHITE, o, 2.5)
	var pupil_r := r * (0.38 if mood == "scared" else 0.58)
	var pc := c + lk * (white_r - pupil_r) * 0.55
	if mood == "sad":
		pc = c + Vector2(0, r * 0.3)
	draw_circle(pc, pupil_r, o, true, -1.0, true)
	draw_circle(pc + Vector2(-pupil_r * 0.35, -pupil_r * 0.4), pupil_r * 0.38, Palette.WHITE, true, -1.0, true)
	if mood == "sad":
		# pálpebra caída + lagriminha
		draw_colored_polygon(PackedVector2Array([c + Vector2(-white_r - 1, -white_r - 1), c + Vector2(white_r + 1, -white_r - 1), c + Vector2(white_r + 1, -white_r * 0.1), c + Vector2(-white_r - 1, -white_r * 0.35)]), _c("main"))
		draw_line(c + Vector2(-white_r, -white_r * 0.35), c + Vector2(white_r, -white_r * 0.1), o, 2.5, true)
		var tear := c + Vector2(white_r * 0.6, white_r + 4.0 + fmod(_mood_t * 14.0, 10.0))
		DrawUtil.oval(self, tear, Vector2(2.5, 3.5), Color("7cc8ff"), o, 1.5)


func _mouth(c: Vector2, w: float) -> void:
	var o := Palette.OUTLINE
	match mood:
		"idle":
			DrawUtil.arc(self, c + Vector2(0, -w * 0.35), w * 0.5, 0.35, PI - 0.35, o, 2.8)
		"happy":
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI * float(i) / 12.0
				pts.append(c + Vector2(cos(a) * w * 0.6, sin(a) * w * 0.7))
			DrawUtil.shape(self, pts, Color("7a2e3a"), o, 2.5)
			DrawUtil.oval(self, c + Vector2(0, w * 0.42), Vector2(w * 0.3, w * 0.18), Color("ff7f9a"), o, 0.0)
		"scared":
			DrawUtil.oval(self, c + Vector2(0, w * 0.1), Vector2(w * 0.28, w * 0.36), Color("7a2e3a"), o, 2.5)
		"ouch":
			var pts := PackedVector2Array()
			for i in 6:
				pts.append(c + Vector2(-w * 0.5 + w * 0.2 * i, (2.5 if i % 2 == 0 else -2.5)))
			draw_polyline(pts, o, 2.8, true)
		"sad":
			DrawUtil.arc(self, c + Vector2(0, w * 0.45), w * 0.45, PI + 0.45, TAU - 0.45, o, 2.8)


func _blush(c: Vector2, r: float) -> void:
	var col := Palette.BLUSH
	if mood == "ouch":
		col = Color(1.0, 0.3, 0.35, 0.85)
	draw_circle(c, r, col, true, -1.0, true)


# ------------------------------------------------------------------ espécies
func _draw_capi() -> void:
	var m := _c("main")
	var d := _c("dark")
	for x in [-38.0, -18.0, 16.0, 34.0]:
		DrawUtil.oval(self, Vector2(x, 25), Vector2(9, 7), d)
	DrawUtil.oval(self, Vector2(-8, 2), Vector2(50, 29), m)
	DrawUtil.oval(self, Vector2(-8, 13), Vector2(34, 12), _c("light"), Palette.OUTLINE, 0.0)
	DrawUtil.disc(self, Vector2(20, -27), 7.0, m)
	DrawUtil.oval(self, Vector2(32, -6), Vector2(27, 24), m)
	DrawUtil.oval(self, Vector2(47, 3), Vector2(15, 14), d)
	DrawUtil.oval(self, Vector2(54, -2), Vector2(2.5, 3.5), Palette.OUTLINE, Palette.OUTLINE, 0.0)
	_blush(Vector2(28, 6), 6.0)
	# olhos de pálpebra calma (marca registrada da Capitu)
	_eye(Vector2(36, -13), 6.0)
	if mood == "idle" and _blink <= 0.0:
		draw_colored_polygon(PackedVector2Array([Vector2(29, -20), Vector2(43, -20), Vector2(43, -14), Vector2(29, -14)]), m)
		draw_line(Vector2(29, -14), Vector2(43, -14), Palette.OUTLINE, 2.5, true)
	_mouth(Vector2(46, 13), 9.0)
	# laranjinha na cabeça (some se houver chapéu)
	if accessory == "" or accessory in ["oculos", "cachecol"]:
		var jump := 0.0
		if mood == "scared":
			jump = -6.0 - absf(sin(_t * 20.0)) * 3.0
		elif mood == "happy":
			jump = -absf(sin(_t * 6.5 + 0.6)) * 10.0
		var oc := Vector2(26, -38 + jump)
		DrawUtil.disc(self, oc, 9.0, Color("ffa62b"))
		DrawUtil.tri(self, oc + Vector2(-1, -8), oc + Vector2(9, -14), oc + Vector2(6, -6), Color("5cc46a"), Palette.OUTLINE, 2.0)


func _draw_brasa() -> void:
	var m := _c("main")
	var d := _c("dark")
	var wag := sin(_t * (9.0 if mood == "happy" else 2.0)) * 0.15
	DrawUtil.oval(self, Vector2(-26, 22), Vector2(27, 13), m, Palette.OUTLINE, Palette.OUTLINE_W, -0.7 + wag)
	DrawUtil.oval(self, Vector2(-44, 4 + wag * 20.0), Vector2(10, 8), _c("light"), Palette.OUTLINE, 3.0, -0.7 + wag)
	DrawUtil.oval(self, Vector2(-9, 42), Vector2(8, 5), d)
	DrawUtil.oval(self, Vector2(11, 42), Vector2(8, 5), d)
	DrawUtil.oval(self, Vector2(1, 18), Vector2(22, 25), m)
	DrawUtil.oval(self, Vector2(5, 21), Vector2(12, 17), _c("light"), Palette.OUTLINE, 0.0)
	var ear_drop := 6.0 if mood in ["sad", "scared"] else 0.0
	DrawUtil.tri(self, Vector2(-20, -26), Vector2(-4, -34), Vector2(-16, -52 + ear_drop), m)
	DrawUtil.tri(self, Vector2(6, -35), Vector2(21, -26), Vector2(17, -52 + ear_drop), m)
	DrawUtil.tri(self, Vector2(-15, -32), Vector2(-8, -35), Vector2(-14, -46 + ear_drop), Color("5a3a3a"), Palette.OUTLINE, 0.0)
	DrawUtil.tri(self, Vector2(10, -35), Vector2(17, -31), Vector2(16, -46 + ear_drop), Color("5a3a3a"), Palette.OUTLINE, 0.0)
	DrawUtil.disc(self, Vector2(2, -15), 22.0, m)
	DrawUtil.oval(self, Vector2(15, -7), Vector2(13, 9), _c("light"), Palette.OUTLINE, 2.5)
	DrawUtil.disc(self, Vector2(27, -10), 4.0, Palette.OUTLINE, Palette.OUTLINE, 0.0)
	_blush(Vector2(-8, -6), 5.0)
	_eye(Vector2(-3, -20), 5.5)
	_eye(Vector2(13, -21), 5.0)
	_mouth(Vector2(17, 0), 8.0)


func _draw_pingo() -> void:
	var m := _c("main")
	var curl := mood == "scared" or mood == "ouch"
	var spikes := PackedVector2Array()
	var start := -0.55 if not curl else 0.0
	var span := TAU - 1.45 if not curl else TAU
	var n := 22
	for i in n + 1:
		var a := start - float(i) / float(n) * span
		var r := 40.0 if i % 2 == 1 else 27.0
		spikes.append(Vector2(cos(a), sin(a)) * r)
	if not curl:
		spikes.append(Vector2.ZERO)
	DrawUtil.shape(self, spikes, m)
	DrawUtil.disc(self, Vector2.ZERO, 26.0, _c("dark"), Palette.OUTLINE, 0.0)
	# folhinha presa nos espinhos
	var lc := Vector2(-16, -30)
	DrawUtil.oval(self, lc, Vector2(9, 5), Color("5cc46a"), Palette.OUTLINE, 2.5, -0.6)
	draw_line(lc + Vector2(-6, 4), lc + Vector2(6, -4), Color("3f8f5a"), 2.0, true)
	if curl:
		# enrolado: só os olhinhos espiando
		_eye(Vector2(10, 2), 4.5)
		_eye(Vector2(20, 1), 4.0)
		return
	DrawUtil.oval(self, Vector2(-6, 24), Vector2(7, 5), _c("light"))
	DrawUtil.oval(self, Vector2(12, 25), Vector2(7, 5), _c("light"))
	DrawUtil.oval(self, Vector2(11, 4), Vector2(20, 18), _c("light"))
	DrawUtil.disc(self, Vector2(30, 3), 4.5, Color("5a3a4a"), Palette.OUTLINE, 2.0)
	_blush(Vector2(6, 10), 4.5)
	_eye(Vector2(11, -4), 5.0)
	_eye(Vector2(22, -5), 4.5)
	_mouth(Vector2(22, 11), 7.0)


func _draw_lulu() -> void:
	var m := _c("main")
	var d := _c("dark")
	var sway := sin(_t * 3.0) * 0.2
	DrawUtil.oval(self, Vector2(-30, 0), Vector2(17, 8), _c("light"), Palette.OUTLINE, Palette.OUTLINE_W, sway)
	DrawUtil.oval(self, Vector2(-6, 6), Vector2(8, 4), m)
	DrawUtil.oval(self, Vector2(-5, 4), Vector2(25, 13), m)
	DrawUtil.oval(self, Vector2(10, 15), Vector2(6, 4), m)
	# brânquias fofas
	var wiggle := sin(_t * 5.0) * 0.15
	for g in [[Vector2(8, -15), -2.2], [Vector2(4, -6), -2.75], [Vector2(6, 5), 2.65]]:
		var dir := Vector2.from_angle(g[1] + wiggle)
		DrawUtil.oval(self, g[0] + dir * 8.0, Vector2(9, 4), d, Palette.OUTLINE, 2.5, g[1] + wiggle)
	DrawUtil.oval(self, Vector2(19, -2), Vector2(21, 17), m)
	_blush(Vector2(13, 5), 4.0)
	_eye(Vector2(21, -6), 3.6, "dot")
	_eye(Vector2(33, -6), 3.2, "dot")
	_mouth(Vector2(29, 5), 13.0)


func _draw_tuca() -> void:
	var m := _c("main")
	var d := _c("dark")
	var hide := mood == "scared" or mood == "ouch"
	DrawUtil.oval(self, Vector2(-26, 19), Vector2(9, 7), m)
	DrawUtil.oval(self, Vector2(20, 19), Vector2(9, 7), m)
	DrawUtil.tri(self, Vector2(-40, 10), Vector2(-52, 16), Vector2(-40, 18), m, Palette.OUTLINE, 3.0)
	var hx := 28.0 if hide else 38.0
	if not hide or mood == "ouch":
		DrawUtil.oval(self, Vector2(hx, -2), Vector2(14, 12), m)
	# casco
	var shell := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		shell.append(Vector2(-4, 12) + Vector2(cos(a) * 40.0, sin(a) * 34.0))
	DrawUtil.shape(self, shell, d)
	for s in [[Vector2(-20, -4), 9.0], [Vector2(-2, -12), 10.0], [Vector2(16, -2), 8.0], [Vector2(-4, 4), 7.0]]:
		DrawUtil.disc(self, s[0], s[1], _c("light"), Palette.OUTLINE, 0.0)
	draw_line(Vector2(-44, 12), Vector2(36, 12), Palette.OUTLINE, Palette.OUTLINE_W, true)
	if shell_flash > 0.0:
		draw_colored_polygon(shell, Color(1, 1, 1, shell_flash * 0.8))
	if hide and mood != "ouch":
		_eye(Vector2(31, 4), 3.5)
		return
	# cachecol vermelho (marca da Tuca)
	DrawUtil.oval(self, Vector2(hx - 10, 6), Vector2(6, 9), Color("e04f5f"), Palette.OUTLINE, 2.5)
	DrawUtil.oval(self, Vector2(hx - 16, 16 + sin(_t * 3.0) * 2.0), Vector2(4, 8), Color("e04f5f"), Palette.OUTLINE, 2.5, 0.3)
	_eye(Vector2(hx + 4, -5), 4.5)
	_mouth(Vector2(hx + 9, 4), 7.0)


func _draw_nino() -> void:
	var m := _c("main")
	var d := _c("dark")
	var flick := sin(_t * (8.0 if mood != "idle" else 2.2)) * 0.12
	DrawUtil.oval(self, Vector2(-20, -6), Vector2(13, 25), m, Palette.OUTLINE, Palette.OUTLINE_W, 0.35 + flick)
	DrawUtil.oval(self, Vector2(-17, -32), Vector2(14, 11), m, Palette.OUTLINE, Palette.OUTLINE_W, 0.4 + flick)
	DrawUtil.oval(self, Vector2(-20, -10), Vector2(5, 16), Color("aab4ca"), Palette.OUTLINE, 0.0, 0.35 + flick)
	DrawUtil.oval(self, Vector2(-3, 19), Vector2(7, 4), d)
	DrawUtil.oval(self, Vector2(12, 19), Vector2(7, 4), d)
	DrawUtil.oval(self, Vector2(4, 6), Vector2(14, 15), m)
	DrawUtil.oval(self, Vector2(7, 8), Vector2(8, 11), _c("light"), Palette.OUTLINE, 0.0)
	DrawUtil.tri(self, Vector2(-6, -20), Vector2(2, -24), Vector2(-4, -34), m, Palette.OUTLINE, 3.0)
	DrawUtil.disc(self, Vector2(7, -11), 13.0, m)
	DrawUtil.disc(self, Vector2(20, -8), 2.5, Palette.OUTLINE, Palette.OUTLINE, 0.0)
	_blush(Vector2(1, -4), 3.5)
	_eye(Vector2(5, -13), 4.3)
	_eye(Vector2(14, -14), 3.9)
	_mouth(Vector2(15, -3), 6.0)
	# bolota nas mãozinhas
	var ac := Vector2(17, 9)
	DrawUtil.oval(self, ac, Vector2(6, 7), Color("c98a4a"), Palette.OUTLINE, 2.5)
	DrawUtil.oval(self, ac + Vector2(0, -5), Vector2(7, 3.5), Color("8a5a39"), Palette.OUTLINE, 2.5)


func _draw_gelinho() -> void:
	var m := _c("main")
	var orange := _c("dark")
	var slide := sin(_t * 2.0) * 0.08
	DrawUtil.oval(self, Vector2(-10, 34), Vector2(9, 4), orange)
	DrawUtil.oval(self, Vector2(8, 34), Vector2(9, 4), orange)
	DrawUtil.oval(self, Vector2(-20, 6), Vector2(7, 18), m, Palette.OUTLINE, Palette.OUTLINE_W, 0.35 + slide)
	DrawUtil.oval(self, Vector2(0, 2), Vector2(22, 34), m)
	DrawUtil.oval(self, Vector2(4, 8), Vector2(15, 25), _c("light"), Palette.OUTLINE, 0.0)
	DrawUtil.oval(self, Vector2(18, 8), Vector2(6, 15), m, Palette.OUTLINE, Palette.OUTLINE_W, -0.35 - slide)
	# cachecol azul (marca do Gelinho)
	DrawUtil.oval(self, Vector2(2, 8), Vector2(21, 6), Color("4aa3ff"), Palette.OUTLINE, 3.0)
	DrawUtil.oval(self, Vector2(-12, 18 + sin(_t * 3.0) * 2.0), Vector2(5, 9), Color("4aa3ff"), Palette.OUTLINE, 3.0, 0.3)
	DrawUtil.tri(self, Vector2(14, -16), Vector2(28, -12), Vector2(14, -8), orange, Palette.OUTLINE, 2.5)
	_blush(Vector2(-2, -10), 4.0)
	_eye(Vector2(2, -20), 4.5)
	_eye(Vector2(12, -21), 4.0)
	_mouth(Vector2(16, -2), 5.0)


func _draw_tata() -> void:
	var m := _c("main")
	var d := _c("dark")
	var curl := mood == "scared" or mood == "ouch"
	if curl:
		DrawUtil.disc(self, Vector2.ZERO, 24.0, m)
		for k in 4:
			draw_arc(Vector2.ZERO, 8.0 + k * 4.0, -PI * 0.9 + k * 0.2, PI * 0.2, 10, d, 3.0, true)
		_eye(Vector2(10, 4), 4.0)
		return
	DrawUtil.oval(self, Vector2(-8, 20), Vector2(6, 4), _c("light"))
	DrawUtil.oval(self, Vector2(10, 21), Vector2(6, 4), _c("light"))
	var shell := PackedVector2Array()
	for i in 15:
		var a := PI + PI * float(i) / 14.0
		shell.append(Vector2(-4, 14) + Vector2(cos(a) * 26.0, sin(a) * 34.0))
	DrawUtil.shape(self, shell, m)
	for k in 4:
		var x := -22.0 + k * 12.0
		draw_line(Vector2(x, 12), Vector2(x + 6, -16 + absf(k - 1.5) * 6.0), d, 3.0, true)
	DrawUtil.oval(self, Vector2(22, 2), Vector2(12, 10), _c("light"))
	DrawUtil.tri(self, Vector2(14, -6), Vector2(20, -8), Vector2(16, -20), _c("light"), Palette.OUTLINE, 2.5)
	draw_circle(Vector2(34, 2), 3.0, Color("ff8fa3"), true, -1.0, true)
	_eye(Vector2(24, -2), 3.8)
	_mouth(Vector2(30, 8), 5.0)


func _draw_pompom() -> void:
	var m := _c("main")
	var droop := 10.0 if mood in ["sad", "scared"] else 0.0
	DrawUtil.oval(self, Vector2(-8, -40 + droop * 0.5), Vector2(7, 18), m, Palette.OUTLINE, Palette.OUTLINE_W, -0.2 - droop * 0.03)
	DrawUtil.oval(self, Vector2(-8, -40 + droop * 0.5), Vector2(3, 12), _c("light"), Palette.OUTLINE, 0.0, -0.2 - droop * 0.03)
	DrawUtil.oval(self, Vector2(10, -42 + droop * 0.5), Vector2(7, 18), m, Palette.OUTLINE, Palette.OUTLINE_W, 0.2 + droop * 0.03)
	DrawUtil.oval(self, Vector2(10, -42 + droop * 0.5), Vector2(3, 12), _c("light"), Palette.OUTLINE, 0.0, 0.2 + droop * 0.03)
	DrawUtil.disc(self, Vector2(-20, 24), 8.0, m)
	DrawUtil.oval(self, Vector2(-6, 38), Vector2(9, 5), _c("dark"))
	DrawUtil.oval(self, Vector2(10, 38), Vector2(9, 5), _c("dark"))
	DrawUtil.oval(self, Vector2(0, 18), Vector2(20, 23), m)
	DrawUtil.disc(self, Vector2(2, -12), 18.0, m)
	_blush(Vector2(-6, -4), 4.5)
	_eye(Vector2(-2, -15), 4.5)
	_eye(Vector2(10, -16), 4.2)
	draw_circle(Vector2(16, -8), 3.0, Color("ff8fa3"), true, -1.0, true)
	_mouth(Vector2(15, -1), 6.0)
	# cenourinha (marca do Pompom)
	DrawUtil.tri(self, Vector2(12, 14), Vector2(24, 12), Vector2(22, 34), Color("ff9f43"), Palette.OUTLINE, 2.5)
	DrawUtil.oval(self, Vector2(18, 10), Vector2(6, 3), Color("5cc46a"), Palette.OUTLINE, 2.0, -0.4)


func _draw_nuvem() -> void:
	var m := _c("main")
	var d := _c("dark")
	for x in [-16.0, -4.0, 10.0, 20.0]:
		draw_line(Vector2(x, 20), Vector2(x, 32), d, 5.0, true)
	var puff := 1.0 + 0.03 * sin(_t * 3.0)
	for k in 9:
		var a := TAU * k / 9.0
		DrawUtil.disc(self, Vector2.from_angle(a) * 20.0 * puff + Vector2(-2, 0), 14.0, m, Palette.OUTLINE, 3.0)
	DrawUtil.disc(self, Vector2(-2, 0), 24.0, m, Palette.OUTLINE, 0.0)
	if shell_flash > 0.0:
		draw_circle(Vector2(-2, 0), 32.0, Color(1, 1, 1, shell_flash * 0.7), true, -1.0, true)
	DrawUtil.oval(self, Vector2(12, -12), Vector2(6, 3), d, Palette.OUTLINE, 2.0, -0.5)
	DrawUtil.oval(self, Vector2(22, 2), Vector2(13, 15), d)
	for k in 3:
		DrawUtil.disc(self, Vector2(16 + k * 6, -12), 5.0, m, Palette.OUTLINE, 2.0)
	_eye(Vector2(18, 0), 3.6, "dot")
	_eye(Vector2(27, 0), 3.4, "dot")
	draw_circle(Vector2(22, 8), 2.0, Color("ff8fa3"), true, -1.0, true)
	_mouth(Vector2(24, 11), 6.0)


func _draw_fofa() -> void:
	var m := _c("main")
	var d := _c("dark")
	DrawUtil.tri(self, Vector2(-44, 4), Vector2(-60, -8), Vector2(-58, 16), d, Palette.OUTLINE, 3.0)
	DrawUtil.oval(self, Vector2(-8, 6), Vector2(44, 20), m)
	DrawUtil.oval(self, Vector2(-6, 14), Vector2(30, 9), _c("light"), Palette.OUTLINE, 0.0)
	DrawUtil.oval(self, Vector2(6, 22), Vector2(12, 5), d, Palette.OUTLINE, Palette.OUTLINE_W, 0.4)
	DrawUtil.disc(self, Vector2(32, -8), 20.0, m)
	DrawUtil.oval(self, Vector2(44, -2), Vector2(9, 7), _c("light"))
	draw_circle(Vector2(50, -6), 3.5, Palette.OUTLINE, true, -1.0, true)
	for k in 3:
		draw_line(Vector2(46, 0 + k * 3), Vector2(60, -4 + k * 5), Palette.OUTLINE, 1.5, true)
	_blush(Vector2(28, 2), 4.0)
	_eye(Vector2(30, -12), 5.0)
	_eye(Vector2(42, -13), 4.6)
	_mouth(Vector2(44, 6), 6.0)


func _draw_tito() -> void:
	var m := _c("main")
	for k in 4:
		var x0 := -18.0 + k * 12.0
		var pts := PackedVector2Array()
		for j in 7:
			var t := float(j) / 6.0
			pts.append(Vector2(x0 + sin(_t * 3.0 + k + t * 4.0) * 6.0 * t, 6.0 + t * 22.0))
		draw_polyline(pts, Palette.OUTLINE, 11.0, true)
		draw_polyline(pts, m, 7.0, true)
		draw_circle(pts[pts.size() - 1], 3.5, m, true, -1.0, true)
	DrawUtil.oval(self, Vector2(0, -6), Vector2(24, 22), m)
	draw_circle(Vector2(-12, -14), 3.0, _c("light"), true, -1.0, true)
	draw_circle(Vector2(12, -18), 2.5, _c("light"), true, -1.0, true)
	_blush(Vector2(-12, 2), 4.0)
	_blush(Vector2(12, 2), 4.0)
	_eye(Vector2(-6, -6), 5.0)
	_eye(Vector2(8, -6), 5.0)
	_mouth(Vector2(1, 4), 7.0)
	# chapeuzinho de marinheiro (marca do Tito)
	if accessory == "":
		DrawUtil.shape(self, PackedVector2Array([Vector2(-14, -26), Vector2(14, -26), Vector2(10, -36), Vector2(-10, -36)]), Color.WHITE, Palette.OUTLINE, 2.5)
		draw_line(Vector2(-13, -28), Vector2(13, -28), Color("4aa3ff"), 3.0, true)


func _draw_patinha() -> void:
	var m := _c("main")
	var bob := sin(_t * 3.0) * 1.5
	DrawUtil.oval(self, Vector2(-6, 20), Vector2(7, 3), _c("dark"))
	DrawUtil.oval(self, Vector2(8, 20), Vector2(7, 3), _c("dark"))
	DrawUtil.tri(self, Vector2(-20, 0), Vector2(-30, -8), Vector2(-24, 6), m, Palette.OUTLINE, 2.5)
	DrawUtil.oval(self, Vector2(-2, 6 + bob), Vector2(21, 15), m)
	DrawUtil.oval(self, Vector2(-6, 6 + bob), Vector2(11, 7), _c("light"), Palette.OUTLINE, 2.5, 0.2)
	DrawUtil.disc(self, Vector2(12, -10 + bob), 13.0, m)
	draw_line(Vector2(10, -22 + bob), Vector2(6, -30 + bob), Palette.OUTLINE, 3.0, true)
	draw_line(Vector2(12, -22 + bob), Vector2(14, -31 + bob), Palette.OUTLINE, 3.0, true)
	DrawUtil.oval(self, Vector2(25, -7 + bob), Vector2(8, 4), _c("dark"))
	_blush(Vector2(8, -4 + bob), 3.5)
	_eye(Vector2(15, -13 + bob), 3.6, "dot")
	_mouth(Vector2(22, -2 + bob), 4.0)


func _draw_kiko() -> void:
	var m := _c("main")
	var d := _c("dark")
	DrawUtil.oval(self, Vector2(-8, 36), Vector2(8, 4), d)
	DrawUtil.oval(self, Vector2(10, 36), Vector2(8, 4), d)
	DrawUtil.oval(self, Vector2(0, 14), Vector2(22, 24), m)
	DrawUtil.oval(self, Vector2(2, 18), Vector2(12, 15), _c("light"), Palette.OUTLINE, 0.0)
	# folha de eucalipto
	DrawUtil.oval(self, Vector2(16, 14), Vector2(10, 5), Color("7fbf8a"), Palette.OUTLINE, 2.5, -0.6)
	DrawUtil.disc(self, Vector2(-16, -26), 12.0, m)
	DrawUtil.disc(self, Vector2(-16, -26), 6.0, _c("light"), Palette.OUTLINE, 0.0)
	DrawUtil.disc(self, Vector2(20, -26), 12.0, m)
	DrawUtil.disc(self, Vector2(20, -26), 6.0, _c("light"), Palette.OUTLINE, 0.0)
	DrawUtil.disc(self, Vector2(2, -14), 20.0, m)
	DrawUtil.oval(self, Vector2(4, -8), Vector2(6, 8), d)
	_blush(Vector2(-8, -4), 4.0)
	_eye(Vector2(-6, -16), 4.0)
	_eye(Vector2(13, -16), 4.0)
	# olhos sonolentos (Kiko vive cochilando)
	if mood == "idle" and _blink <= 0.0:
		for ex in [-6.0, 13.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(ex - 5, -22), Vector2(ex + 5, -22), Vector2(ex + 5, -17), Vector2(ex - 5, -17)]), m)
			draw_line(Vector2(ex - 5, -17), Vector2(ex + 5, -17), Palette.OUTLINE, 2.5, true)
	_mouth(Vector2(5, 2), 6.0)


# ------------------------------------------------------------------ acessórios
func _draw_accessory() -> void:
	if accessory == "":
		return
	var an: Dictionary = ANCHORS[species]
	var s: float = an["scale"]
	var h: Vector2 = an["head"]
	var o := Palette.OUTLINE
	match accessory:
		"bone":
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI + PI * float(i) / 12.0
				pts.append(h + Vector2(cos(a) * 16.0, sin(a) * 13.0) * s)
			DrawUtil.shape(self, pts, Color("4aa3ff"), o, 3.0)
			draw_line(h + Vector2(-4, -12) * s, h + Vector2(-4, 0) * s, Color.WHITE, 3.0 * s, true)
			draw_line(h + Vector2(5, -12) * s, h + Vector2(5, 0) * s, Color.WHITE, 3.0 * s, true)
			DrawUtil.oval(self, h + Vector2(16, 0) * s, Vector2(12, 4) * s, Color("2f7fd6"), o, 3.0)
		"laco":
			DrawUtil.tri(self, h, h + Vector2(-16, -10) * s, h + Vector2(-16, 10) * s, Color("ff5a7a"), o, 3.0)
			DrawUtil.tri(self, h, h + Vector2(16, -10) * s, h + Vector2(16, 10) * s, Color("ff5a7a"), o, 3.0)
			DrawUtil.disc(self, h, 5.0 * s, Color("ff8aa0"), o, 2.5)
			for p in [Vector2(-10, -2), Vector2(10, 3), Vector2(-9, 5), Vector2(9, -4)]:
				draw_circle(h + p * s, 1.8 * s, Color.WHITE, true, -1.0, true)
		"oculos":
			var e: Vector2 = an["eyes"]
			DrawUtil.oval(self, e + Vector2(-8, 0) * s, Vector2(8, 6) * s, Color("2b2440"), o, 2.5)
			DrawUtil.oval(self, e + Vector2(9, 0) * s, Vector2(8, 6) * s, Color("2b2440"), o, 2.5)
			draw_line(e + Vector2(-1, -1) * s, e + Vector2(2, -1) * s, o, 2.5, true)
			draw_line(e + Vector2(-12, -3) * s, e + Vector2(-7, -5) * s, Color(1, 1, 1, 0.7), 2.0, true)
		"flores":
			var cols := [Color("ff9ec7"), Color("ffd23f"), Color("ffffff"), Color("b18cff"), Color("ff8a3d")]
			for i in 5:
				var p := h + Vector2(-16 + 8 * i, -2 + absf(i - 2.0) * 2.0) * s
				DrawUtil.disc(self, p, 5.0 * s, cols[i], o, 2.0)
				draw_circle(p, 1.8 * s, Color("ffb300"), true, -1.0, true)
		"cachecol":
			var nk: Vector2 = an["neck"]
			DrawUtil.oval(self, nk, Vector2(20, 7) * s, Color("5cc46a"), o, 3.0)
			DrawUtil.oval(self, nk + Vector2(-10, 12) * s, Vector2(5, 10) * s, Color("5cc46a"), o, 3.0, 0.2)
			draw_line(nk + Vector2(-8, -5) * s, nk + Vector2(-8, 5) * s, Color("ffffff"), 2.0, true)
			draw_line(nk + Vector2(4, -6) * s, nk + Vector2(4, 6) * s, Color("ffffff"), 2.0, true)
		"coroa":
			var pts := PackedVector2Array([
				h + Vector2(-14, 2) * s, h + Vector2(-14, -12) * s, h + Vector2(-7, -5) * s, h + Vector2(0, -16) * s,
				h + Vector2(7, -5) * s, h + Vector2(14, -12) * s, h + Vector2(14, 2) * s])
			DrawUtil.shape(self, pts, Palette.GOLD, o, 3.0)
			draw_circle(h + Vector2(0, -3) * s, 3.0 * s, Color("ff5a7a"), true, -1.0, true)
		"palha":
			DrawUtil.oval(self, h + Vector2(0, 2) * s, Vector2(26, 6) * s, Color("f2d27a"), o, 3.0)
			var top := PackedVector2Array()
			for i in 13:
				var a := PI + PI * float(i) / 12.0
				top.append(h + Vector2(cos(a) * 13.0, sin(a) * 12.0) * s)
			DrawUtil.shape(self, top, Color("f2d27a"), o, 3.0)
			draw_line(h + Vector2(-13, -2) * s, h + Vector2(13, -2) * s, Color("e04f5f"), 4.0 * s, true)
		"estrela":
			DrawUtil.shape(self, DrawUtil.star_points(h + Vector2(8, -2) * s, 11.0 * s, 5.0 * s), Color("ff8a65"), o, 2.5)
			draw_circle(h + Vector2(8, -2) * s, 2.0 * s, Color("ffd23f"), true, -1.0, true)
		"touca":
			var cap := PackedVector2Array()
			for i in 13:
				var a := PI + PI * float(i) / 12.0
				cap.append(h + Vector2(cos(a) * 17.0, sin(a) * 15.0) * s)
			DrawUtil.shape(self, cap, Color("e04f5f"), o, 3.0)
			DrawUtil.oval(self, h + Vector2(0, 0) * s, Vector2(18, 5) * s, Color.WHITE, o, 2.5)
			DrawUtil.disc(self, h + Vector2(0, -17) * s, 6.0 * s, Color.WHITE, o, 2.5)


# ------------------------------------------------------------------ efeitos
func _draw_ouch_stars() -> void:
	var top := Vector2(0, -_base_y() - 22.0)
	for i in 3:
		var a := _t * 5.0 + TAU * i / 3.0
		var p := top + Vector2(cos(a) * 22.0, sin(a) * 7.0)
		DrawUtil.shape(self, DrawUtil.star_points(p, 7.0, 3.2), Palette.GOLD, Palette.OUTLINE, 2.0)


func _draw_sweat() -> void:
	var p := Vector2(-18.0 * facing, -_base_y() - 4.0) + Vector2(0, fmod(_t * 18.0, 8.0))
	DrawUtil.oval(self, p, Vector2(3.5, 5.0), Color("9fdcff"), Palette.OUTLINE, 2.0)
