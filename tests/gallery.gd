extends Node
## Galeria para revisão de arte: todos os bichinhos (com expressões) e todas as criaturas,
## mais a abertura. Uso: godot --path . --rendering-driver opengl3 res://tests/gallery.tscn -- --out=/pasta

var out_dir := "user://gallery"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.persist = false
	var splash := SplashScreen.new()
	splash.theme = UiKit.make_theme()
	add_child(splash)
	await get_tree().create_timer(2.2).timeout
	await _save("splash")
	splash.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("dff3ff")
	bg.size = Vector2(720, 1280)
	add_child(bg)
	var moods := ["idle", "scared", "happy", "ouch"]
	var i := 0
	for sp in Cast.ORDER:
		for m in moods.size():
			var art := AnimalArt.new()
			art.species = sp
			art.preview = true
			art.mood = moods[m]
			art.position = Vector2(95 + m * 175, 70 + (i % 7) * 175)
			if i >= 7:
				art.position.x += 0
			art.scale = Vector2(1.0, 1.0)
			add_child(art)
		i += 1
		if i == 7:
			await get_tree().create_timer(0.5).timeout
			await _save("animais_1")
			for c in get_children():
				if c is AnimalArt:
					c.queue_free()
	await get_tree().create_timer(0.5).timeout
	await _save("animais_2")
	for c in get_children():
		if c is AnimalArt:
			c.queue_free()
	var k := 0
	for kind in Nest.KINDS:
		var ia := InsectArt.new()
		ia.kind = kind
		ia.radius = 22.0 if kind != "puffer" else 30.0
		ia.position = Vector2(120 + (k % 4) * 160, 120 + (k / 4) * 170)
		add_child(ia)
		k += 1
	await get_tree().create_timer(0.5).timeout
	await _save("criaturas")
	get_tree().quit()


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("captura: ", name)
