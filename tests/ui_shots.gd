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
	get_window().size = sz
	get_tree().root.content_scale_size = Vector2i(720, 1280)
	await get_tree().process_frame
	var c: Control
	match screen:
		"editor":
			var ed := EditorScreen.new()
			ed.custom_index = -1
			c = ed
		"store": c = StoreScreen.new()
		"collection": c = CollectionScreen.new()
		"map":
			var m := LevelSelect.new()
			m.setup(-1)
			c = m
		_: c = TitleScreen.new()
	c.theme = UiKit.make_theme()
	add_child(c)
	await get_tree().process_frame
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
