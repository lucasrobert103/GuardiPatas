extends Node
## Captura rápida de uma tela em um tamanho de janela (revisão visual de layout):
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/ui_shots.tscn -- \
##       --screen=editor --size=720x1600 --out=/tmp/editor.png [--picker=animal]


func _ready() -> void:
	var screen := "title"
	var out := "user://shot.png"
	var picker := ""
	var wait := 1.2
	var sz := Vector2i(720, 1280)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screen="): screen = a.substr(9)
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--picker="): picker = a.substr(9)
		if a.begins_with("--wait="): wait = float(a.substr(7))
		if a.begins_with("--size="):
			var p := a.substr(7).split("x")
			sz = Vector2i(int(p[0]), int(p[1]))
	Game.persist = false
	Game.load_save()
	Game.data["met"] = Cast.ORDER.duplicate()
	Game.data["coins"] = 1250
	if not "--intro" in OS.get_cmdline_user_args():
		Game.data["seen_insects"] = Nest.KINDS.duplicate() + ["termite_queen"]
	if not "--consent" in OS.get_cmdline_user_args():
		Legal.accept()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="): Game.set_setting("lang", a.substr(7))
	get_window().size = sz
	get_tree().root.content_scale_size = Vector2i(720, 1280)
	await get_tree().process_frame
	if screen.begins_with("level:"):
		var idx := LevelDB.index_of(screen.substr(6))
		var lv := Level.new()
		lv.setup(idx, LevelDB.get_level(idx), true)
		add_child(lv)
		await get_tree().physics_frame
		if not "--intro" in OS.get_cmdline_user_args():
			for st in lv.solution_strokes():
				lv.drawer.feed_stroke(st)
				await get_tree().physics_frame
			if lv.state == Level.State.DRAWING:
				lv.start_simulation()
		await get_tree().create_timer(wait).timeout
		if "--pause" in OS.get_cmdline_user_args():
			lv.hud._open_pause()
			await get_tree().create_timer(0.8, true).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out)
		print("salvo ", out)
		get_tree().quit()
		return
	var c: Control
	match screen:
		"editor":
			var ed := EditorScreen.new()
			ed.custom_index = -1
			c = ed
		"store": c = StoreScreen.new()
		"infinite":
			var inf := InfiniteScreen.new()
			inf.director = InfiniteDirector.new()
			inf.add_child(inf.director)
			c = inf
		"magic":
			c = Control.new()
			c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			c.add_child(MenuBg.new())
			var pets := ["faisca", "lumi", "cometa", "pipoca", "capi", "mel", "zeca", "kiko"]
			var fxs := ["", "", "", "", "coracoes", "bolhas", "neve", "folhas"]
			for i in pets.size():
				var a := AnimalArt.new()
				a.species = pets[i]
				a.preview = true
				a.effect = fxs[i]
				a.scale = Vector2(1.5, 1.5)
				a.position = Vector2(180 + (i % 2) * 360, 170 + (i / 2) * 290)
				c.add_child(a)
		"gallery":
			c = Control.new()
			c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			c.add_child(MenuBg.new())
			var sp := ["bolota", "plim", "duda", "nhoque", "lua"]
			for i in sp.size():
				for m in 2:
					var a := AnimalArt.new()
					a.species = sp[i]
					a.preview = true
					a.mood = "idle" if m == 0 else "scared"
					a.scale = Vector2(1.6, 1.6)
					a.position = Vector2(180 + m * 360, 160 + i * 220)
					c.add_child(a)
			var kinds := ["firefly", "fly", "cicada", "bombardier", "mantis", "leafcutter"]
			for i in kinds.size():
				var ia := InsectArt.new()
				ia.kind = kinds[i]
				ia.radius = 22.0
				ia.aiming = i % 2 == 0
				ia.aim_progress = 0.6
				ia.position = Vector2(90 + (i % 3) * 270, 1180 + (i / 3) * 70)
				c.add_child(ia)
		"collection": c = CollectionScreen.new()
		"settings": c = SettingsScreen.new()
		"terms", "privacy", "rights", "parents":
			var lg := LegalScreen.new()
			lg.setup(screen)
			c = lg
		"map", "map9", "map10":
			var m := LevelSelect.new()
			m.setup(-1 if screen == "map" else int(screen.substr(3)))
			c = m
		_: c = TitleScreen.new()
	c.theme = UiKit.make_theme()
	add_child(c)
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--preview="):
			var parts := a.substr(10).split(":")
			ProductPreview.open(c, parts[0], parts[1], func(): pass)
	if c is EditorScreen:
		var ed: EditorScreen = c
		ed.draft["animals"] = [{"type": "capi", "pos": [360, 969], "flip": false}]
		ed.draft["nests"] = [{"insect": "bee", "pos": [600, 360], "count": 5, "interval": 0.35, "delay": 0.3}]
		ed._rebuild()
		if picker != "":
			ed._open_picker(picker)
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("salvo ", out)
	get_tree().quit()
