class_name PaintArt
## Desenhos do Ateliê: fundos e modelos para colorir, adesivos de formas fofas e ícones
## das ferramentas. Tudo vetorial e em escala (a mesma função desenha a miniatura e a tela).

const BASE := Vector2(688, 800)
const LINE := Color("4a3f5c")

## [id, nome, tipo] — "paper" = papel para desenhar livre; "color" = desenho para colorir;
## "scene" = cenário pronto para enfeitar.
const TEMPLATES := [
	["blank", "Papel em branco", "paper"],
	["dots", "Caderno de pontinhos", "paper"],
	["capi", "Capitu para colorir", "color"],
	["house", "Casinha", "color"],
	["hearts", "Corações", "color"],
	["garden", "Jardim de flores", "color"],
	["sea", "Fundo do mar", "color"],
	["rainbow", "Arco-íris", "color"],
	["night", "Noite estrelada", "color"],
	["meadow", "Prado ensolarado", "scene"],
	["beach", "Dia de praia", "scene"],
	["snow", "Montanha de neve", "scene"],
]

const SHAPES := ["heart", "star", "flower", "butterfly", "balloon", "bow", "crown", "cloud", "sun", "moon", "rainbow", "sparkle", "note", "paw", "cupcake", "leaf"]
const SHAPE_NAMES := {"heart": "Coração", "star": "Estrela", "flower": "Flor", "butterfly": "Borboleta", "balloon": "Balão",
	"bow": "Laço", "crown": "Coroa", "cloud": "Nuvem", "sun": "Sol", "moon": "Lua", "rainbow": "Arco-íris",
	"sparkle": "Brilho", "note": "Notinha", "paw": "Patinha", "cupcake": "Bolinho", "leaf": "Folha"}


static func template_kind(id: String) -> String:
	for t in TEMPLATES:
		if t[0] == id:
			return t[2]
	return "paper"


# ------------------------------------------------------------------ fundo
static func draw_bg(ci: CanvasItem, id: String, rect: Rect2) -> void:
	var k := rect.size.x / BASE.x
	var p := func(x: float, y: float) -> Vector2: return rect.position + Vector2(x, y) * k
	match id:
		"dots":
			ci.draw_rect(rect, Color("fffaf0"))
			for y in range(40, 800, 40):
				for x in range(36, 688, 40):
					ci.draw_circle(p.call(x, y), 2.2 * k, Color("d9cfe6"), true, -1, true)
		"sea":
			DrawUtil.vgradient(ci, rect, Color("d9f3ff"), Color("a9dcf5"))
		"night":
			DrawUtil.vgradient(ci, rect, Color("27306b"), Color("4b3f8f"))
		"meadow":
			DrawUtil.vgradient(ci, Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.7)), Color("9ed8ff"), Color("dff3ff"))
			ci.draw_circle(p.call(560, 120), 62 * k, Color("ffe066"), true, -1, true)
			ci.draw_circle(p.call(560, 120), 78 * k, Color("ffe06640"), true, -1, true)
			_cloud(ci, p.call(170, 130), 70 * k, Color(1, 1, 1, 0.95))
			_cloud(ci, p.call(380, 210), 50 * k, Color(1, 1, 1, 0.9))
			_hill(ci, rect, 540, 0.0, Color("9fdc7c"))
			_hill(ci, rect, 600, 1.7, Color("7cc46b"))
			for i in 22:
				var fx := 20.0 + fmod(i * 97.0, 650.0)
				var fy := 640.0 + fmod(i * 53.0, 140.0)
				var col: Color = [Color("ff8fb1"), Color("ffd23f"), Color("ffffff"), Color("b18cff")][i % 4]
				ci.draw_circle(p.call(fx, fy), 7 * k, col, true, -1, true)
				ci.draw_circle(p.call(fx, fy), 2.6 * k, Color("ffb340"), true, -1, true)
		"beach":
			DrawUtil.vgradient(ci, Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.55)), Color("8fd3ff"), Color("e6f7ff"))
			ci.draw_circle(p.call(120, 110), 56 * k, Color("ffd23f"), true, -1, true)
			_cloud(ci, p.call(470, 120), 60 * k, Color(1, 1, 1, 0.95))
			ci.draw_rect(Rect2(p.call(0, 430), Vector2(rect.size.x, 170 * k)), Color("4fb3e8"))
			for i in 7:
				var wx := 30.0 + i * 100.0
				ci.draw_arc(p.call(wx, 470), 26 * k, PI * 1.1, PI * 1.9, 10, Color(1, 1, 1, 0.75), 4 * k, true)
			_hill(ci, rect, 600, 0.6, Color("f6dc9a"), 30.0)
			for i in 10:
				ci.draw_circle(p.call(40 + i * 66, 700 + (i % 3) * 28), 4 * k, Color("e8c37a"), true, -1, true)
		"snow":
			DrawUtil.vgradient(ci, rect, Color("bfe3ff"), Color("f2f8ff"))
			DrawUtil.shape(ci, PackedVector2Array([p.call(-20, 620), p.call(220, 260), p.call(460, 620)]), Color("b8c6e0"), Color(0, 0, 0, 0), 0.0)
			DrawUtil.shape(ci, PackedVector2Array([p.call(160, 360), p.call(220, 260), p.call(280, 360), p.call(250, 345), p.call(220, 370), p.call(190, 345)]), Color("ffffff"), Color(0, 0, 0, 0), 0.0)
			DrawUtil.shape(ci, PackedVector2Array([p.call(260, 640), p.call(520, 230), p.call(780, 640)]), Color("a5b6d6"), Color(0, 0, 0, 0), 0.0)
			DrawUtil.shape(ci, PackedVector2Array([p.call(450, 340), p.call(520, 230), p.call(590, 340), p.call(555, 320), p.call(520, 350), p.call(485, 320)]), Color("ffffff"), Color(0, 0, 0, 0), 0.0)
			_hill(ci, rect, 600, 2.2, Color("ffffff"), 24.0)
			for i in 26:
				ci.draw_circle(p.call(fmod(i * 131.0, 688.0), fmod(i * 77.0, 560.0)), 4 * k, Color(1, 1, 1, 0.85), true, -1, true)
		_:
			ci.draw_rect(rect, Color("fffdf8"))


static func _hill(ci: CanvasItem, rect: Rect2, y: float, phase: float, col: Color, amp: float = 40.0) -> void:
	var k := rect.size.x / BASE.x
	var pts := PackedVector2Array()
	for i in 25:
		var x := i * BASE.x / 24.0
		pts.append(rect.position + Vector2(x, y + sin(i * 0.5 + phase) * amp) * k)
	pts.append(rect.position + Vector2(BASE.x, BASE.y) * k)
	pts.append(rect.position + Vector2(0, BASE.y) * k)
	ci.draw_colored_polygon(pts, col)


static func _cloud(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r * 0.6, col, true, -1, true)
	ci.draw_circle(c + Vector2(-r * 0.6, r * 0.15), r * 0.42, col, true, -1, true)
	ci.draw_circle(c + Vector2(r * 0.62, r * 0.12), r * 0.46, col, true, -1, true)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.6, 0), Vector2(r * 1.24, r * 0.55)), col)


# ------------------------------------------------------------------ desenhos para colorir
static func line_color(id: String) -> Color:
	return Color("fff6d8") if id == "night" else LINE


static func draw_lines(ci: CanvasItem, id: String, rect: Rect2) -> void:
	var k := rect.size.x / BASE.x
	var w := 5.0 * k
	var col := line_color(id)
	var p := func(x: float, y: float) -> Vector2: return rect.position + Vector2(x, y) * k
	var ring := func(c: Vector2, r: Vector2, rot: float = 0.0) -> void:
		ci.draw_polyline(DrawUtil.closed(DrawUtil.ellipse(rect.position + c * k, r * k, rot, 48)), col, w, true)
	var poly := func(pts: Array, closed: bool = false) -> void:
		var out := PackedVector2Array()
		for q in pts:
			out.append(rect.position + Vector2(q[0], q[1]) * k)
		if closed:
			out.append(out[0])
		ci.draw_polyline(out, col, w, true)
	match id:
		"capi":
			ring.call(Vector2(300, 520), Vector2(200, 120))                       # corpo
			ring.call(Vector2(560, 410), Vector2(104, 90))                        # cabeça
			ring.call(Vector2(503, 322), Vector2(22, 15), -0.4)                   # orelha
			ci.draw_circle(p.call(592, 392), 10 * k, col, true, -1, true)         # olho
			ci.draw_circle(p.call(596, 388), 3 * k, Color.WHITE, true, -1, true)
			ring.call(Vector2(642, 424), Vector2(15, 11))                          # focinho
			ci.draw_arc(p.call(612, 452), 16 * k, 0.3, PI - 0.6, 12, col, w * 0.8, true)
			ring.call(Vector2(566, 452), Vector2(15, 11))                          # bochecha
			for lx in [180.0, 262.0, 352.0, 428.0]:
				ring.call(Vector2(lx, 664), Vector2(30, 30))                       # patinhas
			ring.call(Vector2(566, 284), Vector2(30, 30))                          # tangerina
			ring.call(Vector2(588, 250), Vector2(18, 8), -0.5)
			_ground(ci, rect, 720.0, col, w)
			_flower_line(ci, p.call(80, 690), 26 * k, col, w)
			_flower_line(ci, p.call(640, 690), 22 * k, col, w)
			_sun_line(ci, p.call(100, 110), 46 * k, col, w)
		"house":
			poly.call([[190, 390], [500, 390], [500, 650], [190, 650]], true)
			poly.call([[160, 395], [345, 225], [530, 395]], true)
			poly.call([[430, 300], [430, 240], [472, 240], [472, 338]])
			poly.call([[302, 650], [302, 530], [382, 530], [382, 650]])
			ci.draw_circle(p.call(368, 592), 6 * k, col, true, -1, true)
			for wx in [215.0, 410.0]:
				poly.call([[wx, 430], [wx + 70, 430], [wx + 70, 500], [wx, 500]], true)
				poly.call([[wx + 35, 430], [wx + 35, 500]])
				poly.call([[wx, 465], [wx + 70, 465]])
			ring.call(Vector2(345, 330), Vector2(30, 30))
			ring.call(Vector2(604, 430), Vector2(64, 70))
			poly.call([[588, 498], [588, 650], [620, 650], [620, 498]])
			_ground(ci, rect, 650.0, col, w)
			_cloud_line(ci, p.call(150, 110), 70 * k, col, w)
			_cloud_line(ci, p.call(540, 140), 50 * k, col, w)
			_flower_line(ci, p.call(110, 700), 24 * k, col, w)
			_flower_line(ci, p.call(560, 720), 20 * k, col, w)
		"hearts":
			_heart_line(ci, p.call(344, 400), 15.0 * k, col, w)
			_heart_line(ci, p.call(344, 400), 7.0 * k, col, w)
			for h in [[110, 130, 4.0], [560, 120, 4.6], [100, 650, 3.6], [590, 660, 4.2], [344, 720, 2.6], [220, 60, 2.2], [470, 760, 2.0]]:
				_heart_line(ci, p.call(h[0], h[1]), h[2] * k, col, w)
			for s in [[600, 330, 18.0], [80, 380, 16.0], [610, 520, 12.0]]:
				_star_line(ci, p.call(s[0], s[1]), s[2] * k, col, w)
		"garden":
			for f in [[150, 380, 70.0, 640], [350, 300, 84.0, 640], [560, 400, 66.0, 640]]:
				poly.call([[f[0], f[1] + f[2] * 0.4], [f[0], f[3]]])
				ring.call(Vector2(f[0] - 34, f[1] + f[2] + 80), Vector2(32, 14), -0.5)
				ring.call(Vector2(f[0] + 34, f[1] + f[2] + 120), Vector2(32, 14), 0.5)
				_flower_line(ci, p.call(f[0], f[1]), f[2] * k, col, w)
			_butterfly_line(ci, p.call(520, 150), 1.0 * k, col, w)
			_butterfly_line(ci, p.call(170, 160), 0.7 * k, col, w)
			_ground(ci, rect, 660.0, col, w)
			_sun_line(ci, p.call(610, 60), 34 * k, col, w)
		"sea":
			for f in [[200, 250, 1.0, 1.0], [480, 420, 1.3, -1.0], [230, 560, 0.8, 1.0]]:
				_fish_line(ci, p.call(f[0], f[1]), f[2] * k, f[3], col, w)
			for b in [[540, 160, 16], [570, 110, 10], [520, 80, 7], [120, 400, 12], [90, 350, 8], [380, 160, 9]]:
				ring.call(Vector2(b[0], b[1]), Vector2(b[2], b[2]))
			_star_line(ci, p.call(560, 690), 42 * k, col, w)
			for sx in [80.0, 330.0, 640.0]:
				var pts := PackedVector2Array()
				for i in 12:
					pts.append(p.call(sx + sin(i * 0.9) * 18, 740 - i * 22))
				ci.draw_polyline(pts, col, w, true)
			_ground(ci, rect, 740.0, col, w)
		"rainbow":
			for i in 5:
				ci.draw_arc(p.call(344, 600), (130 + i * 38) * k, PI, TAU, 64, col, w, true)
			_cloud_line(ci, p.call(110, 600), 110 * k, col, w)
			_cloud_line(ci, p.call(578, 600), 110 * k, col, w)
			_sun_line(ci, p.call(110, 120), 44 * k, col, w)
			for s in [[560, 120, 20.0], [460, 70, 12.0], [640, 230, 10.0]]:
				_star_line(ci, p.call(s[0], s[1]), s[2] * k, col, w)
		"night":
			ci.draw_arc(p.call(520, 170), 80 * k, -2.3, 2.3, 40, col, w, true)
			ci.draw_arc(p.call(560, 150), 66 * k, -2.05, 2.05, 40, col, w, true)
			for s in [[120, 120, 26.0], [260, 220, 18.0], [380, 90, 14.0], [160, 360, 20.0], [620, 380, 16.0], [420, 300, 22.0]]:
				_star_line(ci, p.call(s[0], s[1]), s[2] * k, col, w)
			var pts := PackedVector2Array()
			for i in 25:
				pts.append(p.call(i * 688.0 / 24.0, 600 + sin(i * 0.45) * 50))
			ci.draw_polyline(pts, col, w, true)
			ring.call(Vector2(200, 650), Vector2(48, 58))   # corujinha
			ring.call(Vector2(183, 630), Vector2(13, 13))
			ring.call(Vector2(217, 630), Vector2(13, 13))
			poly.call([[192, 652], [200, 666], [208, 652]], true)


static func _ground(ci: CanvasItem, rect: Rect2, y: float, col: Color, w: float) -> void:
	var k := rect.size.x / BASE.x
	var pts := PackedVector2Array()
	for i in 25:
		pts.append(rect.position + Vector2(i * BASE.x / 24.0, y + sin(i * 0.8) * 8) * k)
	ci.draw_polyline(pts, col, w, true)


static func _flower_line(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 61:
		var a := TAU * i / 60.0
		pts.append(c + Vector2.from_angle(a) * r * (0.72 + 0.28 * absf(cos(a * 2.5))))
	ci.draw_polyline(pts, col, w, true)
	ci.draw_arc(c, r * 0.3, 0, TAU, 24, col, w, true)


static func _sun_line(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float) -> void:
	ci.draw_arc(c, r, 0, TAU, 32, col, w, true)
	for i in 8:
		var d := Vector2.from_angle(TAU * i / 8.0)
		ci.draw_line(c + d * r * 1.25, c + d * r * 1.6, col, w, true)


static func _cloud_line(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 73:
		var a := TAU * i / 72.0
		var rr := r * (0.62 + 0.14 * absf(sin(a * 3.0)))
		pts.append(c + Vector2(cos(a) * rr * 1.3, sin(a) * rr * 0.7))
	ci.draw_polyline(pts, col, w, true)


static func _heart_points(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 65:
		var a := TAU * i / 64.0
		pts.append(c + Vector2(16 * pow(sin(a), 3), -(13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a))) * s)
	return pts


static func _heart_line(ci: CanvasItem, c: Vector2, s: float, col: Color, w: float) -> void:
	ci.draw_polyline(_heart_points(c, s), col, w, true)


static func _star_line(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float) -> void:
	ci.draw_polyline(DrawUtil.closed(DrawUtil.star_points(c, r, r * 0.45)), col, w, true)


static func _fish_line(ci: CanvasItem, c: Vector2, s: float, dir: float, col: Color, w: float) -> void:
	ci.draw_polyline(DrawUtil.closed(DrawUtil.ellipse(c, Vector2(70, 42) * s, 0.0, 40)), col, w, true)
	var t := c + Vector2(-70 * dir, 0) * s
	ci.draw_polyline(PackedVector2Array([t, t + Vector2(-44 * dir, -32) * s, t + Vector2(-44 * dir, 32) * s, t]), col, w, true)
	ci.draw_circle(c + Vector2(36 * dir, -8) * s, 7 * s, col, true, -1, true)
	ci.draw_arc(c + Vector2(10 * dir, 0) * s, 26 * s, -0.9, 0.9, 10, col, w * 0.8, true)


static func _butterfly_line(ci: CanvasItem, c: Vector2, s: float, col: Color, w: float) -> void:
	for side in [-1.0, 1.0]:
		ci.draw_polyline(DrawUtil.closed(DrawUtil.ellipse(c + Vector2(side * 44, -26) * s, Vector2(40, 32) * s, side * 0.5, 32)), col, w, true)
		ci.draw_polyline(DrawUtil.closed(DrawUtil.ellipse(c + Vector2(side * 34, 30) * s, Vector2(28, 22) * s, -side * 0.5, 28)), col, w, true)
	ci.draw_polyline(DrawUtil.closed(DrawUtil.ellipse(c, Vector2(10, 46) * s, 0.0, 24)), col, w, true)
	ci.draw_line(c + Vector2(-4, -44) * s, c + Vector2(-22, -76) * s, col, w * 0.8, true)
	ci.draw_line(c + Vector2(4, -44) * s, c + Vector2(22, -76) * s, col, w * 0.8, true)


# ------------------------------------------------------------------ adesivos (formas)
## Desenha uma forma colorida centrada em `c`, com raio aproximado `r`.
static func draw_shape(ci: CanvasItem, shape: String, c: Vector2, r: float, color: Color) -> void:
	var o := Palette.OUTLINE
	var w := maxf(2.0, r * 0.09)
	match shape:
		"heart":
			DrawUtil.shape(ci, _heart_points(c + Vector2(0, -r * 0.1), r / 17.0), color, o, w)
			ci.draw_circle(c + Vector2(-r * 0.4, -r * 0.42), r * 0.12, Color(1, 1, 1, 0.7), true, -1, true)
		"star":
			DrawUtil.shape(ci, DrawUtil.star_points(c, r, r * 0.48), color, o, w)
			ci.draw_circle(c + Vector2(-r * 0.15, -r * 0.18), r * 0.1, Color(1, 1, 1, 0.7), true, -1, true)
		"flower":
			for i in 5:
				DrawUtil.disc(ci, c + Vector2.from_angle(TAU * i / 5.0 - PI / 2) * r * 0.55, r * 0.42, color, o, w)
			DrawUtil.disc(ci, c, r * 0.36, Color("ffd23f"), o, w)
		"butterfly":
			for side in [-1.0, 1.0]:
				DrawUtil.oval(ci, c + Vector2(side * r * 0.48, -r * 0.3), Vector2(r * 0.46, r * 0.38), color, o, w, side * 0.5)
				DrawUtil.oval(ci, c + Vector2(side * r * 0.38, r * 0.36), Vector2(r * 0.32, r * 0.26), color.lightened(0.25), o, w, -side * 0.5)
			DrawUtil.oval(ci, c, Vector2(r * 0.12, r * 0.55), o, o, 0.0)
		"balloon":
			ci.draw_line(c + Vector2(0, r * 0.75), c + Vector2(r * 0.1, r * 1.3), o, w * 0.7, true)
			DrawUtil.oval(ci, c + Vector2(0, -r * 0.1), Vector2(r * 0.7, r * 0.85), color, o, w)
			DrawUtil.tri(ci, c + Vector2(-r * 0.12, r * 0.82), c + Vector2(r * 0.12, r * 0.82), c + Vector2(0, r * 0.7), color, o, w * 0.6)
			DrawUtil.oval(ci, c + Vector2(-r * 0.28, -r * 0.4), Vector2(r * 0.12, r * 0.2), Color(1, 1, 1, 0.6), Color(0, 0, 0, 0), 0.0, 0.4)
		"bow":
			DrawUtil.tri(ci, c, c + Vector2(-r, -r * 0.6), c + Vector2(-r, r * 0.6), color, o, w)
			DrawUtil.tri(ci, c, c + Vector2(r, -r * 0.6), c + Vector2(r, r * 0.6), color, o, w)
			DrawUtil.disc(ci, c, r * 0.24, color.darkened(0.1), o, w)
		"crown":
			DrawUtil.shape(ci, PackedVector2Array([c + Vector2(-r, r * 0.5), c + Vector2(-r, -r * 0.4), c + Vector2(-r * 0.5, 0), c + Vector2(0, -r * 0.7),
				c + Vector2(r * 0.5, 0), c + Vector2(r, -r * 0.4), c + Vector2(r, r * 0.5)]), Color("ffd23f"), o, w)
			for x in [-0.5, 0.0, 0.5]:
				DrawUtil.disc(ci, c + Vector2(x * r, r * 0.2), r * 0.12, color, o, w * 0.6)
		"cloud":
			_cloud(ci, c, r, Palette.OUTLINE)
			_cloud(ci, c + Vector2(0, -w * 0.2), r - w, Color.WHITE)
		"sun":
			for i in 10:
				var d := Vector2.from_angle(TAU * i / 10.0)
				ci.draw_line(c + d * r * 0.7, c + d * r, Color("ffb340"), w * 1.6, true)
			DrawUtil.disc(ci, c, r * 0.6, Color("ffd23f"), o, w)
			ci.draw_circle(c + Vector2(-r * 0.2, -r * 0.08), r * 0.07, o, true, -1, true)
			ci.draw_circle(c + Vector2(r * 0.2, -r * 0.08), r * 0.07, o, true, -1, true)
			ci.draw_arc(c + Vector2(0, r * 0.05), r * 0.22, 0.3, PI - 0.3, 10, o, w * 0.7, true)
		"moon":
			var pts := PackedVector2Array()
			for i in 25:
				pts.append(c + Vector2.from_angle(PI * 0.35 + PI * 1.3 * i / 24.0) * r)
			for i in 25:
				var a := PI * 1.65 - PI * 1.3 * i / 24.0
				pts.append(c + Vector2(r * 0.35, -r * 0.1) + Vector2.from_angle(a) * r * 0.72)
			DrawUtil.shape(ci, pts, Color("fff0a0"), o, w)
		"rainbow":
			var cols := [Color("ff6b6b"), Color("ffb340"), Color("ffe066"), Color("7ed957"), Color("6bc4ff"), Color("b18cff")]
			for i in cols.size():
				ci.draw_arc(c + Vector2(0, r * 0.4), r * (1.0 - i * 0.13), PI, TAU, 32, cols[i], r * 0.14, true)
			_cloud(ci, c + Vector2(-r * 0.85, r * 0.4), r * 0.32, Color.WHITE)
			_cloud(ci, c + Vector2(r * 0.85, r * 0.4), r * 0.32, Color.WHITE)
		"sparkle":
			var pts := PackedVector2Array()
			for i in 8:
				var rr := r if i % 2 == 0 else r * 0.25
				pts.append(c + Vector2.from_angle(TAU * i / 8.0 - PI / 2) * rr)
			DrawUtil.shape(ci, pts, color, o, w)
		"note":
			ci.draw_line(c + Vector2(r * 0.18, r * 0.45), c + Vector2(r * 0.18, -r * 0.8), o, w * 1.4, true)
			DrawUtil.tri(ci, c + Vector2(r * 0.18, -r * 0.8), c + Vector2(r * 0.7, -r * 0.45), c + Vector2(r * 0.18, -r * 0.4), color, o, w * 0.7)
			DrawUtil.oval(ci, c + Vector2(-r * 0.1, r * 0.5), Vector2(r * 0.34, r * 0.25), color, o, w, -0.4)
		"paw":
			DrawUtil.oval(ci, c + Vector2(0, r * 0.25), Vector2(r * 0.5, r * 0.42), color, o, w)
			for t in [[-0.55, -0.3], [-0.2, -0.65], [0.2, -0.65], [0.55, -0.3]]:
				DrawUtil.disc(ci, c + Vector2(t[0], t[1]) * r, r * 0.2, color, o, w)
		"cupcake":
			DrawUtil.shape(ci, PackedVector2Array([c + Vector2(-r * 0.6, 0), c + Vector2(r * 0.6, 0), c + Vector2(r * 0.42, r * 0.8), c + Vector2(-r * 0.42, r * 0.8)]), Color("c98a4a"), o, w)
			DrawUtil.oval(ci, c + Vector2(0, -r * 0.15), Vector2(r * 0.72, r * 0.4), color, o, w)
			DrawUtil.disc(ci, c + Vector2(0, -r * 0.6), r * 0.16, Color("ff5d73"), o, w * 0.7)
		"leaf":
			DrawUtil.oval(ci, c, Vector2(r * 0.45, r * 0.9), color, o, w, 0.6)
			ci.draw_line(c + Vector2(-r * 0.45, r * 0.6), c + Vector2(r * 0.35, -r * 0.5), o, w * 0.7, true)


# ------------------------------------------------------------------ ícones das ferramentas
static func draw_tool(ci: CanvasItem, tool: String, c: Vector2, s: float, color: Color) -> void:
	var o := Palette.OUTLINE
	var w := maxf(2.0, s * 0.08)
	match tool:
		"pencil":
			ci.draw_line(c + Vector2(-0.32, 0.32) * s, c + Vector2(0.3, -0.3) * s, o, w * 3.0, true)
			ci.draw_line(c + Vector2(-0.24, 0.24) * s, c + Vector2(0.3, -0.3) * s, color, w * 1.8, true)
			DrawUtil.tri(ci, c + Vector2(-0.36, 0.36) * s, c + Vector2(-0.2, 0.32) * s, c + Vector2(-0.32, 0.2) * s, Palette.CREAM, o, w * 0.5)
		"brush":
			ci.draw_line(c + Vector2(0.36, -0.36) * s, c + Vector2(0.02, -0.02) * s, Color("c98a4a"), w * 2.2, true)
			DrawUtil.oval(ci, c + Vector2(-0.12, 0.12) * s, Vector2(0.14, 0.24) * s, color, o, w * 0.6, 0.78)
		"crayon":
			DrawUtil.shape(ci, PackedVector2Array([c + Vector2(-0.16, 0.38) * s, c + Vector2(-0.38, 0.16) * s, c + Vector2(0.18, -0.4) * s, c + Vector2(0.4, -0.18) * s]), color, o, w * 0.7)
			ci.draw_line(c + Vector2(-0.1, 0.1) * s, c + Vector2(0.12, -0.12) * s, Color(1, 1, 1, 0.6), w, true)
		"rainbow":
			var cols := [Color("ff6b6b"), Color("ffd23f"), Color("7ed957"), Color("6bc4ff"), Color("b18cff")]
			for i in cols.size():
				ci.draw_arc(c + Vector2(0, 0.2) * s, (0.42 - i * 0.07) * s, PI, TAU, 18, cols[i], w * 0.9, true)
		"glitter":
			DrawUtil.shape(ci, DrawUtil.star_points(c + Vector2(-0.08, 0.04) * s, 0.3 * s, 0.13 * s), Color("ffd23f"), o, w * 0.6)
			DrawUtil.shape(ci, DrawUtil.star_points(c + Vector2(0.26, -0.26) * s, 0.13 * s, 0.06 * s), color, o, w * 0.4)
			DrawUtil.shape(ci, DrawUtil.star_points(c + Vector2(0.24, 0.3) * s, 0.1 * s, 0.045 * s), Color.WHITE, o, w * 0.4)
		"neon":
			var a := c + Vector2(-0.36, 0.2) * s
			var b := c + Vector2(0.36, -0.2) * s
			ci.draw_line(a, b, Color(color, 0.35), w * 4.0, true)
			ci.draw_line(a, b, color.lightened(0.3), w * 2.0, true)
			ci.draw_line(a, b, Color.WHITE, w * 0.8, true)
		"spray":
			DrawUtil.shape(ci, PackedVector2Array([c + Vector2(-0.1, -0.12) * s, c + Vector2(0.2, -0.12) * s, c + Vector2(0.2, 0.42) * s, c + Vector2(-0.1, 0.42) * s]), color, o, w * 0.7)
			ci.draw_rect(Rect2(c + Vector2(-0.02, -0.26) * s, Vector2(0.14, 0.12) * s), o)
			for d in [Vector2(-0.3, -0.34), Vector2(-0.4, -0.2), Vector2(-0.28, -0.12), Vector2(-0.42, -0.38)]:
				ci.draw_circle(c + d * s, 0.035 * s, color, true, -1, true)
		"fill":
			DrawUtil.shape(ci, PackedVector2Array([c + Vector2(-0.3, -0.12) * s, c + Vector2(0.12, -0.34) * s, c + Vector2(0.34, 0.08) * s, c + Vector2(-0.08, 0.3) * s]), Palette.WHITE, o, w * 0.7)
			DrawUtil.oval(ci, c + Vector2(-0.3, 0.26) * s, Vector2(0.1, 0.14) * s, color, o, w * 0.5)
		"eraser":
			DrawUtil.shape(ci, PackedVector2Array([c + Vector2(-0.36, 0.1) * s, c + Vector2(0.04, -0.3) * s, c + Vector2(0.36, 0.02) * s, c + Vector2(-0.04, 0.42) * s]), Color("ffb3c7"), o, w * 0.7)
			ci.draw_line(c + Vector2(-0.18, -0.08) * s, c + Vector2(0.14, 0.24) * s, o, w * 0.6, true)
		"sticker":
			draw_shape(ci, "heart", c + Vector2(-0.1, 0.06) * s, 0.3 * s, Color("ff8fb1"))
			draw_shape(ci, "star", c + Vector2(0.24, -0.22) * s, 0.16 * s, Color("ffd23f"))
