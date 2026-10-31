extends Node
var passed := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func process_frames() -> void:
	for i in 4: await get_tree().process_frame
func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion, true)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		get_viewport().push_input(event, true)
		await get_tree().process_frame
func _ready() -> void:
	Game.persist = false
	Game.load_save()
	var level := Level.new()
	level.setup(0,LevelDB.get_level(0), true)
	add_child(level)
	await frames(2)
	check(level.replay != null and level.replay.frames.is_empty(), "não registra desenho")
	level.start_simulation()
	while level.state == Level.State.RUNNING: await get_tree().physics_frame
	check(level.state == Level.State.LOST and level.replay.finished, "picada real encerra registro")
	check(level.last_result["failure_point"].is_finite() and level.last_result["failure_id"] != 0, "contato informa local e amigo atingido")
	check(level.last_result["analysis"].contains("broca"), "explicação corresponde à broca que alcançou o amigo")
	var begin: Dictionary = level.replay.frames[0]
	var next: Dictionary = level.replay.frames[1]
	var middle := level.replay.at((float(next["time"])-float(begin["time"]))/2)
	var expected: Vector2 = (begin["actors"][0]["position"] as Vector2).lerp(next["actors"][0]["position"],0.5)
	check((middle["actors"][0]["position"] as Vector2).is_equal_approx(expected), "reprodução interpola posições entre amostras")
	var recorded := level.replay.frames.duplicate(true)
	await frames(90)
	check(level.replay.frames == recorded, "registro não muda depois da derrota")
	check(level.hud.review_btn != null and level.hud.review_btn.visible, "resultado oferece revisão gratuita")
	var data := Game.data.duplicate(true)
	var normal_ticks := Engine.physics_ticks_per_second
	await click(level.hud.review_btn)
	await process_frames()
	var view: AttemptReview = level.hud.review
	check(view != null and get_tree().paused, "GUI abre revisão e pausa o mundo")
	check(not view.playing and is_equal_approx(view.cursor, view.model.duration()), "abre no instante da derrota sem movimento automático")
	await click(view._play)
	check(view.playing, "reprodução inicia pelo controle real")
	view._process(0.2)
	check(view.cursor > 0 and view.cursor <= 0.15, "reprodução avança em meia velocidade")
	view.playing = false
	view._timeline.value = 0
	check(view.cursor == 0, "arrastar linha do tempo acessa começo do trecho")
	check(Game.data == data and level.replay.frames == recorded and Engine.time_scale == 1 and Engine.physics_ticks_per_second == normal_ticks, "rever não cobra dica nem muda resultado ou velocidade física")
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(360,640),Vector2i(720,1280),Vector2i(1280,720)]:
		get_tree().root.size = dimensions
		await process_frames()
		check(view._canvas.size.y >= 120 and view._timeline.get_global_rect().end.x <= dimensions.x and view._box.get_global_rect().end.y <= dimensions.y, "revisão cabe na tela %s" % dimensions)
	Game.set_setting("big_text", true)
	for language in ["en", "es"]:
		level.hud.on_back_pressed()
		await process_frames()
		Game.set_setting("lang", language)
		level.hud._open_review()
		await process_frames()
		view = level.hud.review
		get_tree().root.size = Vector2i(360,640)
		await process_frames()
		check(view._canvas.size.y >= 120 and view._timeline.get_global_rect().end.y < 640, "texto grande e idioma cabem na revisão " + language)
	Game.set_setting("big_text", false)
	Game.set_setting("lang", "pt_BR")
	level.hud.on_back_pressed()
	await process_frames()
	check(level.hud.review == null and not get_tree().paused and level.hud.overlay.visible, "voltar restaura resultado e pausa anterior")
	get_tree().paused = true
	level.hud._open_review()
	await process_frames()
	level.hud.on_back_pressed()
	await process_frames()
	check(get_tree().paused, "fechar preserva uma pausa que já existia")
	get_tree().paused = false
	level.hud._open_review()
	await process_frames()
	var again: AttemptReview = level.hud.review
	var navigated := {"yes":false}
	level.hud.action.connect(func(action: String):
		if action == "restart": navigated["yes"] = true)
	again.retry.emit()
	await process_frames()
	check(navigated["yes"] and not get_tree().paused, "recomeçar pela revisão restaura relógio")
	level.hud._open_review()
	await process_frames()
	level.queue_free()
	await process_frames()
	check(not get_tree().paused, "sair da fase não deixa o jogo pausado")

	level = Level.new()
	level.setup(-1,{"id":"replay-buffer", "mode":"custom", "world":1, "survive":30,
		"animals":[{"type":"capi","pos":[360,969]}],
		"bosses":[{"kind":"owl","pos":[360,300],"delay":20}],
		"terrain":[{"poly":[[-400,1000],[1120,1000],[1120,1800],[-400,1800]],"style":"ground"}]},true)
	add_child(level)
	await frames(2)
	level.start_simulation()
	await frames(320)
	check(level.replay.frames.size() <= AttemptReplay.MAX_FRAMES and level.replay.duration() <= 3.001 and level.replay.duration() > 2.7, "buffer limitado aos últimos três segundos")
	check(float(level.replay.frames[0]["time"]) > 2, "descarta começo de tentativas longas")
	var before := level.replay.frames.size()
	level.hud._open_pause()
	await process_frames()
	check(level.replay.frames.size() == before, "pausa não grava frames")
	level.hud._close_overlay()
	level.lose("time")
	check(level.last_result["analysis"].contains("tempo"), "tempo esgotado tem explicação própria")
	level.hud._on_result(false, level.last_result)
	level.hud._open_review()
	await process_frames()
	var boss_art: Node2D = level.hud.review._canvas._actors[level.bosses[0].get_instance_id()]
	check(boss_art is Boss and boss_art.level == null and not boss_art.running and boss_art.process_mode == Node.PROCESS_MODE_DISABLED, "chefão na revisão tem arte original e nenhum comportamento físico")
	level.queue_free()
	await process_frames()

	level = Level.new()
	level.setup(0,LevelDB.get_level(0),true)
	add_child(level)
	await frames(2)
	for stroke in level.solution_strokes():
		level.drawer.feed_stroke(stroke)
		await frames(1)
	while level.state == Level.State.RUNNING: await get_tree().physics_frame
	check(level.state == Level.State.WON and level.replay.frames.is_empty(), "vitória mantém solução e libera histórico")
	level.queue_free()
	await process_frames()
	print("==== REVISÃO: %d ok, %d falhas ====" % [passed,failures])
	get_tree().quit(1 if failures else 0)
