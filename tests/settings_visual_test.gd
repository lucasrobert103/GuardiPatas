extends Node
var passed := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)
func wait_frames() -> void:
	for i in 4: await get_tree().process_frame
func tap(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = point
	get_viewport().push_input(move, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		get_viewport().push_input(event, true)
		await get_tree().process_frame
func _ready() -> void:
	Game.persist = false
	Game.load_save()
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.content_scale_size = Vector2i.ZERO
	get_tree().root.size = Vector2i(720,1280)
	var screen := SettingsScreen.new()
	add_child(screen)
	await wait_frames()
	var original := bool(Game.setting("vibration"))
	check(screen._controls["vibration"].button_pressed == original, "interruptor mostra estado salvo")
	await tap(screen._controls["vibration"])
	check(bool(Game.setting("vibration")) != original, "toque altera vibração")
	screen._controls["music"].value = 0.35
	check(is_equal_approx(float(Game.setting("music")),0.35), "volume atualiza preferências")
	var before := Game.data.duplicate(true)
	screen._ask_reset()
	await wait_frames()
	check(screen._confirm != null, "exclusão exige confirmação")
	screen.on_back_pressed()
	await wait_frames()
	check(screen._confirm == null and Game.data == before, "voltar cancela exclusão sem apagar")
	for language in ["pt_BR","en","es"]:
		Game.set_setting("lang", language)
		Game.set_setting("big_text", true)
		for dimensions in [Vector2i(360,640),Vector2i(720,1280),Vector2i(1280,720)]:
			get_tree().root.size = dimensions
			screen._queue_rebuild()
			await wait_frames()
			check(screen._scroll.get_global_rect().end.x <= dimensions.x and screen._scroll.get_global_rect().end.y <= dimensions.y, "rolagem cabe %s %s" % [language,dimensions])
			for key in screen._controls:
				var control: Control = screen._controls[key]
				check(control.get_global_rect().end.x <= dimensions.x + 1, "controle sem corte lateral " + key)
			screen._ask_reset()
			await wait_frames()
			check(screen._confirm_panel.size.x < dimensions.x and screen._confirm_panel.size.y < dimensions.y, "confirmação cabe na tela")
			screen._close_confirm()
			await wait_frames()
	screen.queue_free()
	await wait_frames()
	print("==== AJUSTES: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)
