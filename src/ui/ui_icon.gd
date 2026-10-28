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
		"timer":
			DrawUtil.disc(self, c + Vector2(0, 0.05) * s, s * 0.34, Palette.WHITE, o, w * 0.7)
			draw_line(c + Vector2(0, 0.05) * s, c + Vector2(0, -0.17) * s, o, w * 0.8, true)
			draw_line(c + Vector2(0, 0.05) * s, c + Vector2(0.13, 0.12) * s, o, w * 0.8, true)
			draw_rect(Rect2(c + Vector2(-0.08, -0.45) * s, Vector2(0.16, 0.1) * s), o, true)
