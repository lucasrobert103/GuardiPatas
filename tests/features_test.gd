extends Node
## Recursos da 1.0: tutorial dos poderes, treino, missões, petiscos, bolhas, numeração.
##   godot --headless --fixed-fps 60 --path . res://tests/features_test.tscn
var passed := 0
var failures := 0


func check(v: bool, msg: String) -> void:
	if v:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", msg)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func run_level(data: Dictionary, strokes: Array) -> Level:
	var lv := Level.new()
	lv.setup(-1 if not data.has("_index") else int(data["_index"]), data, false)
	add_child(lv)
	await frames(2)
	for st in strokes:
		lv.drawer.feed_stroke(st)
		await frames(1)
	if lv.state == Level.State.DRAWING:
		lv.start_simulation()
	while lv.state == Level.State.RUNNING and lv._sim_time < lv.survive + 4.0:
		await frames(1)
	return lv


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	Game.set_setting("lang", "pt_BR")
	# numeração contínua
	check(LevelDB.count() >= 123, "campanha com %d fases" % LevelDB.count())
	check(Game.completed_count() == 0 and Game.next_level_index() == 0, "começa na Fase 1")
	Game.data["levels"]["1-1"] = {"stars": 3}
	check(Game.completed_count() == 1 and Game.next_level_index() == 1, "conta fases vencidas")
	# tutorial: cartão com demonstração ao vivo na 1ª fase com Vagalume
	Game.data = Game._default_data()
	var idx := -1
	for i in LevelDB.count():
		for n in LevelDB.get_level(i)["nests"]:
			if n["insect"] == "firefly" and idx < 0:
				idx = i
	check(idx >= 0 and Tutorials.new_kinds(LevelDB.get_level(idx)).has("firefly"), "Vagalume é novo na fase %d" % (idx + 1))
	var lv := Level.new()
	lv.setup(idx, LevelDB.get_level(idx), true)
	add_child(lv)
	await frames(4)
	var intro: InsectIntro = null
	if lv.hud.overlay != null:
		intro = _find(lv.hud.overlay, "InsectIntro")
	check(intro != null, "cartão do inseto novo com demonstração")
	await get_tree().create_timer(2.0).timeout
	check(intro != null and intro._lv != null and intro._lv.state == Level.State.RUNNING, "a demonstração roda a física de verdade")
	var go_btn := _button(lv.hud.overlay, "Jogar")
	check(go_btn != null, "botão Jogar no cartão")
	if go_btn: go_btn.pressed.emit()
	await frames(2)
	check(lv.hud.overlay == null and Game.data["seen_insects"].has("firefly"), "Jogar fecha o cartão e marca como visto")
	check(Tutorials.new_kinds(LevelDB.get_level(idx)).is_empty(), "o cartão não aparece de novo")
	lv.queue_free()
	await frames(2)
	# todas as demonstrações e treinos rodam; o treino com um arco é vencível
	for kind in Nest.KINDS + ["termite_queen"]:
		var demo := await run_level(Tutorials.demo_level(kind), Level._to_poly_list(Tutorials.demo_level(kind)["solution"]))
		check(demo.state != Level.State.DRAWING, "demonstração de %s roda" % kind)
		demo.queue_free()
	for kind in ["firefly", "ladybug", "ghost", "ninja", "dragonfly"]:
		var pr := Tutorials.practice_level(kind, 0)
		var won := await run_level(pr, Level._to_poly_list([Tutorials.dome(360, 56, 939)]))
		check(won.state == Level.State.WON, "treino de %s é vencível com um abrigo" % kind)
		won.queue_free()
		var lost := await run_level(pr, [])
		check(lost.state == Level.State.LOST, "treino de %s sem linha perde" % kind)
		lost.queue_free()
	# missões: 3 por fase e a solução cumpre a de tinta e a de sem dica
	var bad := 0
	for i in LevelDB.count():
		if Missions.for_level(str(LevelDB.get_level(i)["id"])).size() != 3: bad += 1
	check(bad == 0, "todas as fases têm 3 missões")
	Game.data = Game._default_data()
	var d0 := LevelDB.get_level(0).duplicate(true)
	d0["_index"] = 0
	var c0 := Game.coins()
	var l0 := await run_level(d0, Level._to_poly_list(d0["solution"]))
	var info: Dictionary = l0.last_result
	check(l0.state == Level.State.WON and info.get("missions_new", []).has("ink") and info.get("missions_new", []).has("nohint"), "solução cumpre tinta e sem dica (%s)" % str(info.get("missions_new", [])))
	check(Game.coins() > c0 and Missions.done_count("1-1") >= 2, "missões dão moedas e ficam salvas")
	check(Treats.total() > 0, "vitória dá petiscos (%d)" % Treats.total())
	l0.queue_free()
	# petiscos na Casinha
	Game.data["treats"] = {"morango": 2}
	var before := float(PetCare.state("capi")["love"])
	check(Treats.use("morango", "capi") and Treats.count("morango") == 1 and float(PetCare.state("capi")["love"]) > before, "dar petisco gasta 1 e dá carinho")
	check(not Treats.use("picole", "capi"), "sem petisco, não dá")
	# bolhas
	var game := BubbleGame.new()
	game.size = Vector2(720, 1280)
	add_child(game)
	await get_tree().create_timer(1.6).timeout
	var popped := false
	for k in 6:
		if game._bubbles.is_empty():
			await get_tree().create_timer(0.4).timeout
			continue
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		ev.position = game._bubbles[0]["p"]
		game._gui_input(ev)
		popped = true
	check(popped and game._score > 0, "estourar bolhas soma pontos (%d)" % game._score)
	var cb := Game.coins()
	game._t = BubbleGame.DURATION
	await get_tree().process_frame
	await get_tree().process_frame
	check(game._over and Game.stat("bubbles") >= game._score, "fim do banho registra as bolhas")
	check(Game.coins() >= cb, "bolhas dão moedas")
	game.queue_free()
	print("==== RECURSOS: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)


func _find(n: Node, cls: String) -> Node:
	if n.get_script() != null and n.get_script().get_global_name() == cls:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r != null: return r
	return null


func _button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text.strip_edges() == text:
		return n
	for c in n.get_children():
		var r := _button(c, text)
		if r != null: return r
	return null
