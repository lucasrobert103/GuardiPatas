extends Node
## Quadros da abertura em vários instantes, para revisar a animação:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 720x1280 res://tests/splash_frames.tscn -- --out=/pasta

var out_dir := "user://splash"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.persist = false
	var s := SplashScreen.new()
	s.set_process(false)
	add_child(s)
	await get_tree().process_frame
	var times := [0.5, 1.05, 1.3, 1.55, 1.75, 2.2, 2.75, 3.0, 3.3, 3.75, 4.3, 5.2]
	if "--all" in OS.get_cmdline_user_args():
		# 20 quadros por segundo, a abertura inteira (para montar um GIF)
		times = []
		var t := 0.05
		while t < SplashScreen.DURATION:
			times.append(t)
			t += 0.05
	var dt := 1.0 / 60.0
	for t in times:
		while s._t < t:
			s._process(dt)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("t%04d.png" % int(t * 100)))
	get_tree().quit()
