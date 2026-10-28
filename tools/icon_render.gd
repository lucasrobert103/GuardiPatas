extends Node
## Gera os ícones do app com a própria arte do jogo (Capitu feliz sob um abrigo de tinta
## e uma abelha batendo nele). Uso:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --audio-driver Dummy res://tools/icon_render.tscn
## Saída em assets/icon/: icon_192.png, icon_512.png, adaptive_fg.png, adaptive_bg.png, adaptive_mono.png
## (adaptativos 432×432; o conteúdo importante fica no círculo seguro central de 288 px).

const OUT := "res://assets/icon"


class Layer extends Node2D:
	var mode := "bg"   # bg | fg | full
	var s := 1.0

	func _draw() -> void:
		var w := 432.0 * s
		if mode != "fg":
			DrawUtil.vgradient(self, Rect2(0, 0, w, w), Color("8fd3ff"), Color("e3f6ff"))
			for c in [Vector2(0.2, 0.22), Vector2(0.8, 0.16)]:
				DrawUtil.cloud(self, c * w, 34.0 * s, Color(1, 1, 1, 0.9))
			var hill := PackedVector2Array()
			for i in 33:
				var x := w * i / 32.0
				hill.append(Vector2(x, w * 0.74 - sin(float(i) / 32.0 * PI) * w * 0.05))
			hill.append(Vector2(w, w))
			hill.append(Vector2(0, w))
			draw_colored_polygon(hill, Palette.GRASS)
			for i in 9:
				var p := Vector2(w * (0.08 + i * 0.11), w * (0.84 + 0.05 * (i % 2)))
				draw_circle(p, 5.0 * s, Color("ff9ec7") if i % 2 == 0 else Color("fff1a8"), true, -1.0, true)
		if mode == "bg":
			return
		# abrigo de tinta (arco) — o gesto central do jogo
		var c := Vector2(w * 0.5, w * 0.64)
		var r := w * 0.27
		var pts := PackedVector2Array()
		for i in 41:
			var a := PI + PI * i / 40.0
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 1.02))
		draw_polyline(pts, Palette.OUTLINE, 30.0 * s, true)
		draw_polyline(pts, Palette.INK, 22.0 * s, true)
		var hi := PackedVector2Array()
		for i in range(6, 35):
			hi.append(pts[i] + Vector2(0, -4.0 * s))
		draw_polyline(hi, Palette.INK_HI, 6.0 * s, true)
		# risquinhos de impacto da abelha
		var hit := c + Vector2.from_angle(-PI * 0.22) * (r + 14.0 * s)
		for k in 3:
			var a := -PI * 0.22 + (k - 1) * 0.35
			draw_line(hit + Vector2.from_angle(a) * 10.0 * s, hit + Vector2.from_angle(a) * 24.0 * s, Palette.OUTLINE, 4.0 * s, true)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _render("adaptive_bg", "bg", 432, false)
	await _render("adaptive_fg", "fg", 432, true)
	await _render("icon_512", "full", 512, false)
	await _render("icon_192", "full", 192, false)
	# monocromático: silhueta branca do primeiro plano
	var fg := Image.load_from_file(ProjectSettings.globalize_path(OUT.path_join("adaptive_fg.png")))
	for y in fg.get_height():
		for x in fg.get_width():
			var a := fg.get_pixel(x, y).a
			fg.set_pixel(x, y, Color(1, 1, 1, a))
	fg.save_png(ProjectSettings.globalize_path(OUT.path_join("adaptive_mono.png")))
	print("ícones ok")
	get_tree().quit()


func _render(name: String, mode: String, px: int, transparent: bool) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(px, px)
	vp.transparent_bg = transparent
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var s := px / 432.0
	var layer := Layer.new()
	layer.mode = mode
	layer.s = s
	vp.add_child(layer)
	if mode != "bg":
		var capi := AnimalArt.new()
		capi.species = "capi"
		capi.preview = true
		capi.mood = "happy"
		capi.position = Vector2(216, 266) * s
		capi.scale = Vector2.ONE * 1.6 * s
		vp.add_child(capi)
		var bee := InsectArt.new()
		bee.kind = "bee"
		bee.radius = 17.0 * s
		bee.facing = -1.0
		bee.dazed = true
		bee.position = Vector2(272, 146) * s
		vp.add_child(bee)
	for i in 8:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT.path_join(name + ".png")))
	vp.queue_free()
