extends Node
## Gera a imagem de destaque da Play Store (1024×500) com a arte do jogo.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --audio-driver Dummy res://tools/store_render.tscn
## Saída: store/feature_graphic_pt.png, _en.png, _es.png

const SIZE := Vector2i(1024, 500)


class Scene extends Node2D:
	func _draw() -> void:
		var w := float(SIZE.x)
		var h := float(SIZE.y)
		DrawUtil.vgradient(self, Rect2(0, 0, w, h), Color("8fd3ff"), Color("e3f6ff"))
		draw_circle(Vector2(900, 90), 70.0, Color(1, 0.95, 0.6, 0.3), true, -1.0, true)
		DrawUtil.disc(self, Vector2(900, 90), 44.0, Color("ffe066"), Color("f5b83d"), 4.0)
		for c in [Vector2(120, 80), Vector2(640, 60), Vector2(380, 120)]:
			DrawUtil.cloud(self, c, 30.0, Color(1, 1, 1, 0.9))
		var far := PackedVector2Array()
		for i in 41:
			var x := w * i / 40.0
			far.append(Vector2(x, 360 - sin(i * 0.5) * 24.0 - 20.0))
		far.append(Vector2(w, h))
		far.append(Vector2(0, h))
		draw_colored_polygon(far, Color("a9dba0"))
		draw_rect(Rect2(0, 400, w, 100), Palette.GRASS, true)
		draw_line(Vector2(0, 400), Vector2(w, 400), Palette.GRASS_DARK, 6.0, true)
		draw_rect(Rect2(0, 440, w, 60), Palette.DIRT, true)
		for i in 14:
			var p := Vector2(30 + i * 74, 420 + (i % 2) * 10)
			draw_circle(p, 6.0, Color("ff9ec7") if i % 2 == 0 else Color("fff1a8"), true, -1.0, true)
		# o abrigo de tinta sobre a turma (lado direito)
		var c := Vector2(735, 400)
		var pts := PackedVector2Array()
		for i in 41:
			var a := PI + PI * i / 40.0
			pts.append(c + Vector2(cos(a) * 250.0, sin(a) * 190.0))
		draw_polyline(pts, Palette.OUTLINE, 26.0, true)
		draw_polyline(pts, Palette.INK, 18.0, true)
		var hi := PackedVector2Array()
		for i in range(6, 34):
			hi.append(pts[i] + Vector2(0, -4))
		draw_polyline(hi, Palette.INK_HI, 5.0, true)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://store"))
	for lang in [["pt_BR", "pt"], ["en", "en"], ["es", "es"]]:
		TranslationServer.set_locale(lang[0])
		await _render("res://store/feature_graphic_%s.png" % lang[1])
	print("destaque ok")
	get_tree().quit()


func _render(path: String) -> void:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	vp.add_child(Scene.new())
	var parade := [["pompom", 545], ["capi", 640], ["tito", 735], ["brasa", 815], ["gelinho", 890], ["pingo", 960]]
	for p in parade:
		var art := AnimalArt.new()
		art.species = p[0]
		art.preview = true
		art.mood = "happy"
		art.scale = Vector2.ONE * 1.25
		art.position = Vector2(p[1], 400 - Animal.half_height(p[0]) * 1.25 - 2)
		vp.add_child(art)
	for b in [[560, 110, 1.0], [1000, 230, -1.0], [440, 330, 1.0]]:
		var bee := InsectArt.new()
		bee.kind = "bee"
		bee.radius = 18.0
		bee.facing = b[2]
		bee.position = Vector2(b[0], b[1])
		vp.add_child(bee)
	var ui := Control.new()
	ui.size = Vector2(SIZE)
	ui.theme = UiKit.make_theme()
	vp.add_child(ui)
	var t := UiKit.title("GuardiPatas", 96)
	t.position = Vector2(30, 110)
	t.size = Vector2(470, 120)
	ui.add_child(t)
	var sub := UiKit.label(UiKit.tr_text("Proteja os Bichinhos!"), 38, Palette.WHITE, 12, Palette.OUTLINE)
	sub.position = Vector2(30, 230)
	sub.size = Vector2(470, 60)
	ui.add_child(sub)
	for i in 10:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	vp.queue_free()
	await get_tree().process_frame
