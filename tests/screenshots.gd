extends Node
## Gera capturas de tela das telas e de algumas fases (precisa de renderização real):
##   godot --path . --rendering-driver opengl3 res://tests/screenshots.tscn -- --out=/caminho
##   [--all-levels] [--shots=6-11:solve:1.5,7-11:none:1.3]
## Útil para revisar arte/UI e para a página da loja.

var out_dir := "user://screenshots"


func _ready() -> void:
	var all_levels := false
	var shots: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			# --shots=6-11:solve:1.5,7-11:none:1.3  (fase:modo:segundos)
			for spec in a.substr(8).split(","):
				var f := spec.split(":")
				shots.append([f[0], f[1], float(f[2])])
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		if a == "--all-levels":
			all_levels = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.persist = false
	Game.load_save()
	Game.data["met"] = ["capi", "brasa", "pingo", "nino", "tuca", "lulu"]
	Game.data["coins"] = 340
	Game.data["owned"] = ["oculos", "laco"]
	Game.data["equipped"] = {"brasa": "oculos", "nino": "laco"}
	for i in 8:
		Game.data["levels"][str(LevelDB.get_level(i)["id"])] = {"stars": 3 - i % 3}
	if not shots.is_empty():
		for spec in shots:
			await _level(spec[0], spec[1], spec[2])
		get_tree().quit()
		return
	if all_levels:
		for i in LevelDB.count():
			await _level(str(LevelDB.get_level(i)["id"]), "hint", 0.0)
		get_tree().quit()
		return
	await _screen(TitleScreen.new(), "01_titulo", 1.5)
	var map := LevelSelect.new()
	map.setup(1)
	await _screen(map, "02_mapa", 0.8)
	var map5 := LevelSelect.new()
	map5.setup(5)
	await _screen(map5, "02b_mapa_mundo5", 0.8)
	await _screen(CollectionScreen.new(), "03_colecao", 0.8)
	await _screen(SettingsScreen.new(), "04_ajustes", 0.8)
	for spec in [["1-1", "hint", 0.0], ["1-1", "solve", 2.5], ["1-4", "solve", 5.0], ["2-2", "solve", 3.0], ["3-3", "solve", 2.0], ["4-1", "solve", 3.0], ["4-3", "solve", 4.0], ["5-5", "solve", 3.0], ["5-6", "solve", 3.5], ["1-2", "none", 2.2], ["2-6", "draw", 0.0]]:
		await _level(spec[0], spec[1], spec[2])
	await _level_result("1-1")
	get_tree().quit()


func _screen(c: Control, name: String, wait: float) -> void:
	c.theme = UiKit.make_theme()
	add_child(c)
	await get_tree().create_timer(wait).timeout
	await _save(name)
	c.queue_free()
	await get_tree().process_frame


func _level(id: String, mode: String, wait: float) -> void:
	var idx := LevelDB.index_of(id)
	var lv := Level.new()
	lv.setup(idx, LevelDB.get_level(idx), true)
	add_child(lv)
	await get_tree().physics_frame
	await get_tree().physics_frame
	match mode:
		"hint":
			lv.show_hint()
			await get_tree().create_timer(0.6).timeout
		"solve":
			for s in lv.solution_strokes():
				lv.drawer.feed_stroke(s)
				await get_tree().physics_frame
			if lv.state == Level.State.DRAWING:
				lv.start_simulation()
		"none":
			lv.start_simulation()
		"draw":
			# traço pela metade, para mostrar a prévia e a barra de tinta
			var s: PackedVector2Array = lv.solution_strokes()[0]
			lv.drawer.press(s[0])
			for i in range(1, s.size() / 2):
				lv.drawer.move(s[i])
			await get_tree().physics_frame
	await get_tree().create_timer(wait + 0.3).timeout
	await _save("fase_%s_%s" % [id, mode] + ("_%.1f" % wait if wait > 0.0 else ""))
	lv.queue_free()
	await get_tree().process_frame


func _level_result(id: String) -> void:
	var idx := LevelDB.index_of(id)
	var lv := Level.new()
	lv.setup(idx, LevelDB.get_level(idx), true)
	add_child(lv)
	await get_tree().physics_frame
	for s in lv.solution_strokes():
		lv.drawer.feed_stroke(s)
	while lv.state == Level.State.RUNNING:
		await get_tree().physics_frame
	await get_tree().create_timer(3.2).timeout
	await _save("fase_%s_vitoria" % id)
	lv.queue_free()
	await get_tree().process_frame


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("captura: ", name)
