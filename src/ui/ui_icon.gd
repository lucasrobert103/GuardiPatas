class_name UiIcon
extends Control
## Ícones vetoriais da interface (não dependem de fonte/emoji).

var icon := "play"
var color := Palette.OUTLINE


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var w := maxf(s * 0.11, 3.0)
	var o := color
	match icon:
		"play":
			DrawUtil.shape(self, PackedVector2Array([c + Vector2(-0.28, -0.36) * s, c + Vector2(0.38, 0) * s, c + Vector2(-0.28, 0.36) * s]), Palette.WHITE, o, w * 0.8)
		"pause":
			draw_rect(Rect2(c + Vector2(-0.3, -0.34) * s, Vector2(0.2, 0.68) * s), o, true)
			draw_rect(Rect2(c + Vector2(0.1, -0.34) * s, Vector2(0.2, 0.68) * s), o, true)
		"restart":
			draw_arc(c, s * 0.3, -PI * 0.15, PI * 1.45, 20, o, w, true)
			var tip := c + Vector2.from_angle(-PI * 0.15) * s * 0.3
			DrawUtil.tri(self, tip + Vector2(-0.18, -0.08) * s, tip + Vector2(0.12, -0.12) * s, tip + Vector2(0.02, 0.18) * s, o, o, 0.0)
		"home":
			DrawUtil.shape(self, PackedVector2Array([c + Vector2(-0.38, 0) * s, c + Vector2(0, -0.36) * s, c + Vector2(0.38, 0) * s]), o, o, w * 0.5)
			draw_rect(Rect2(c + Vector2(-0.26, -0.02) * s, Vector2(0.52, 0.38) * s), o, true)
			draw_rect(Rect2(c + Vector2(-0.07, 0.14) * s, Vector2(0.14, 0.22) * s), Palette.WHITE, true)
		"hint":
			DrawUtil.disc(self, c + Vector2(0, -0.08) * s, s * 0.26, Palette.GOLD, o, w * 0.6)
			draw_rect(Rect2(c + Vector2(-0.12, 0.17) * s, Vector2(0.24, 0.16) * s), o, true)
			draw_line(c + Vector2(-0.05, -0.16) * s, c + Vector2(-0.12, -0.04) * s, Palette.WHITE, w * 0.6, true)
		"star":
			DrawUtil.shape(self, DrawUtil.star_points(c, s * 0.45, s * 0.2), Palette.GOLD, o, w * 0.6)
		"star_empty":
			DrawUtil.shape(self, DrawUtil.star_points(c, s * 0.45, s * 0.2), Color(0, 0, 0, 0.15), Color(o, 0.4), w * 0.6)
		"gear":
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(c + Vector2.from_angle(a) * s * 0.2, c + Vector2.from_angle(a) * s * 0.42, o, w * 1.4, true)
			DrawUtil.disc(self, c, s * 0.3, o, o, 0.0)
			draw_circle(c, s * 0.12, Palette.WHITE, true, -1.0, true)
		"lock":
			draw_arc(c + Vector2(0, -0.08) * s, s * 0.18, PI, TAU, 12, o, w, true)
			draw_rect(Rect2(c + Vector2(-0.26, -0.08) * s, Vector2(0.52, 0.42) * s), o, true)
			draw_circle(c + Vector2(0, 0.1) * s, s * 0.06, Palette.WHITE, true, -1.0, true)
		"coin":
			DrawUtil.disc(self, c, s * 0.4, Palette.GOLD, o, w * 0.6)
			draw_rect(Rect2(c + Vector2(-0.06, -0.2) * s, Vector2(0.12, 0.4) * s), Palette.GOLD_DARK, true)
		"back":
			draw_line(c + Vector2(0.3, 0) * s, c + Vector2(-0.25, 0) * s, o, w * 1.2, true)
			draw_line(c + Vector2(-0.3, 0) * s, c + Vector2(-0.05, -0.25) * s, o, w * 1.2, true)
			draw_line(c + Vector2(-0.3, 0) * s, c + Vector2(-0.05, 0.25) * s, o, w * 1.2, true)
		"next":
			draw_line(c + Vector2(-0.3, 0) * s, c + Vector2(0.25, 0) * s, o, w * 1.2, true)
			draw_line(c + Vector2(0.3, 0) * s, c + Vector2(0.05, -0.25) * s, o, w * 1.2, true)
			draw_line(c + Vector2(0.3, 0) * s, c + Vector2(0.05, 0.25) * s, o, w * 1.2, true)
		"heart":
			var pts := PackedVector2Array()
			for i in 32:
				var t := TAU * i / 32.0
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				pts.append(c + Vector2(x, y) * s * 0.024)
			DrawUtil.shape(self, pts, Color("ff6b8a"), o, w * 0.6)
		"trophy":
			DrawUtil.shape(self, PackedVector2Array([c + Vector2(-0.28, -0.32) * s, c + Vector2(0.28, -0.32) * s, c + Vector2(0.18, 0.05) * s, c + Vector2(-0.18, 0.05) * s]), Palette.GOLD, o, w * 0.6)
			draw_rect(Rect2(c + Vector2(-0.05, 0.05) * s, Vector2(0.1, 0.18) * s), o, true)
			draw_rect(Rect2(c + Vector2(-0.2, 0.22) * s, Vector2(0.4, 0.1) * s), o, true)
		"paw":
			draw_circle(c + Vector2(0, 0.12) * s, s * 0.2, o, true, -1.0, true)
			for p in [Vector2(-0.24, -0.1), Vector2(-0.09, -0.26), Vector2(0.09, -0.26), Vector2(0.24, -0.1)]:
				draw_circle(c + p * s, s * 0.09, o, true, -1.0, true)
		"check":
			draw_line(c + Vector2(-0.28, 0.02) * s, c + Vector2(-0.06, 0.24) * s, o, w * 1.3, true)
			draw_line(c + Vector2(-0.06, 0.24) * s, c + Vector2(0.3, -0.22) * s, o, w * 1.3, true)
		"close":
			draw_line(c + Vector2(-0.25, -0.25) * s, c + Vector2(0.25, 0.25) * s, o, w * 1.3, true)
			draw_line(c + Vector2(-0.25, 0.25) * s, c + Vector2(0.25, -0.25) * s, o, w * 1.3, true)
		"ink":
			DrawUtil.shape(self, PackedVector2Array([c + Vector2(0, -0.38) * s, c + Vector2(0.24, 0.05) * s, c + Vector2(0.18, 0.26) * s, c + Vector2(0, 0.34) * s, c + Vector2(-0.18, 0.26) * s, c + Vector2(-0.24, 0.05) * s]), Palette.INK, o, w * 0.6)
		"rock":
			DrawUtil.shape(self, PackedVector2Array([c + Vector2(-0.38, 0.28) * s, c + Vector2(-0.3, -0.08) * s, c + Vector2(-0.06, -0.3) * s,
				c + Vector2(0.24, -0.22) * s, c + Vector2(0.38, 0.06) * s, c + Vector2(0.34, 0.28) * s]), Palette.STONE, o, w * 0.6)
			draw_line(c + Vector2(-0.1, -0.12) * s, c + Vector2(0.04, 0.02) * s, Color(1, 1, 1, 0.6), w * 0.6, true)
		"block":
			draw_rect(Rect2(c + Vector2(-0.36, -0.26) * s, Vector2(0.72, 0.56) * s), Palette.STONE, true)
			draw_rect(Rect2(c + Vector2(-0.36, -0.26) * s, Vector2(0.72, 0.56) * s), o, false, w * 0.6)
			draw_line(c + Vector2(-0.36, 0.02) * s, c + Vector2(0.36, 0.02) * s, o, w * 0.4, true)
			draw_line(c + Vector2(0.0, -0.26) * s, c + Vector2(0.0, 0.02) * s, o, w * 0.4, true)
		"calendar":
			draw_rect(Rect2(c + Vector2(-0.36, -0.3) * s, Vector2(0.72, 0.64) * s), Palette.WHITE, true)
			draw_rect(Rect2(c + Vector2(-0.36, -0.3) * s, Vector2(0.72, 0.64) * s), o, false, w * 0.7)
			draw_rect(Rect2(c + Vector2(-0.36, -0.3) * s, Vector2(0.72, 0.18) * s), Palette.DANGER, true)
			for x in [-0.18, 0.18]:
				draw_line(c + Vector2(x, -0.4) * s, c + Vector2(x, -0.22) * s, o, w * 0.8, true)
			for k in 6:
				draw_circle(c + Vector2(-0.2 + (k % 3) * 0.2, 0.0 + (k / 3) * 0.17) * s, s * 0.045, o, true, -1.0, true)
		"bolt":
			DrawUtil.shape(self, PackedVector2Array([c + Vector2(0.08, -0.42) * s, c + Vector2(-0.24, 0.06) * s, c + Vector2(-0.02, 0.06) * s,
				c + Vector2(-0.1, 0.42) * s, c + Vector2(0.26, -0.08) * s, c + Vector2(0.04, -0.08) * s]), Palette.GOLD, o, w * 0.6)
		"gold_paw":
			draw_circle(c + Vector2(0, 0.12) * s, s * 0.22, Palette.GOLD, true, -1.0, true)
			draw_arc(c + Vector2(0, 0.12) * s, s * 0.22, 0.0, TAU, 20, o, w * 0.5, true)
			for p in [Vector2(-0.26, -0.1), Vector2(-0.1, -0.27), Vector2(0.1, -0.27), Vector2(0.26, -0.1)]:
				DrawUtil.disc(self, c + p * s, s * 0.1, Palette.GOLD, o, w * 0.4)
		"flame":
			DrawUtil.shape(self, PackedVector2Array([c + Vector2(0, -0.42) * s, c + Vector2(0.24, -0.04) * s, c + Vector2(0.26, 0.18) * s,
				c + Vector2(0.1, 0.36) * s, c + Vector2(-0.1, 0.36) * s, c + Vector2(-0.26, 0.18) * s, c + Vector2(-0.2, -0.1) * s, c + Vector2(-0.06, 0.0) * s]), Color("ff8a3d"), o, w * 0.6)
			DrawUtil.oval(self, c + Vector2(0, 0.2) * s, Vector2(0.1, 0.13) * s, Palette.GOLD, o, 0.0)
		"house":
			DrawUtil.shape(self, PackedVector2Array([c + Vector2(-0.4, -0.02) * s, c + Vector2(0, -0.38) * s, c + Vector2(0.4, -0.02) * s]), Palette.DANGER, o, w * 0.6)
			draw_rect(Rect2(c + Vector2(-0.28, -0.04) * s, Vector2(0.56, 0.38) * s), Palette.WOOD, true)
			draw_rect(Rect2(c + Vector2(-0.28, -0.04) * s, Vector2(0.56, 0.38) * s), o, false, w * 0.6)
			draw_rect(Rect2(c + Vector2(-0.08, 0.12) * s, Vector2(0.16, 0.22) * s), o, true)
		"camera":
			draw_rect(Rect2(c + Vector2(-0.38, -0.2) * s, Vector2(0.76, 0.5) * s), Palette.UI_SECONDARY, true)
			draw_rect(Rect2(c + Vector2(-0.38, -0.2) * s, Vector2(0.76, 0.5) * s), o, false, w * 0.6)
			draw_rect(Rect2(c + Vector2(-0.14, -0.32) * s, Vector2(0.28, 0.12) * s), o, true)
			DrawUtil.disc(self, c + Vector2(0, 0.05) * s, s * 0.15, Palette.WHITE, o, w * 0.6)
		"pencil":
			var a := c + Vector2(-0.3, 0.3) * s
			var b := c + Vector2(0.28, -0.28) * s
			draw_line(a, b, o, w * 3.0, true)
			draw_line(a + Vector2(0.06, -0.06) * s, b, Palette.GOLD, w * 2.0, true)
			DrawUtil.tri(self, a, a + Vector2(0.14, -0.02) * s, a + Vector2(0.02, -0.14) * s, Palette.CREAM, o, w * 0.4)
		"timer":
			DrawUtil.disc(self, c + Vector2(0, 0.05) * s, s * 0.34, Palette.WHITE, o, w * 0.7)
			draw_line(c + Vector2(0, 0.05) * s, c + Vector2(0, -0.17) * s, o, w * 0.8, true)
			draw_line(c + Vector2(0, 0.05) * s, c + Vector2(0.13, 0.12) * s, o, w * 0.8, true)
			draw_rect(Rect2(c + Vector2(-0.08, -0.45) * s, Vector2(0.16, 0.1) * s), o, true)
