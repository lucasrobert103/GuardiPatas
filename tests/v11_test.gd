extends Node
## Novidades da 1.1:
## - Modo Infinito prepara a fase numa tela de carregamento (silenciosa, rápida, sem deixar
##   começar antes) e nada roda escondido durante a partida; os corações não mudam sozinhos.
## - Fases normais: a tinta nunca acaba, só as estrelas diminuem, sem aviso.
## - Tela inicial: botão novo do Modo Infinito e o Ateliê (Pintar).
##   godot --headless --fixed-fps 60 --path . res://tests/v11_test.tscn
var passed := 0
var failures := 0
var main: Node


func check(v: bool, msg: String) -> void:
	if v:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", msg)


func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func until(cond: Callable, limit: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if (Time.get_ticks_msec() - t0) / 1000.0 > limit:
			return false
		await get_tree().process_frame
	return true


func find_button(n: Node, pred: Callable) -> Button:
	if n is Button and pred.call(n) and (n as Button).is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := find_button(c, pred)
		if r != null:
			return r
	return null


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	Legal.accept()
	Game.set_setting("lang", "pt_BR")
	Game.data["seen_insects"] = Nest.KINDS.duplicate() + ["termite_queen"]
	get_window().size = Vector2i(720, 1280)
	await _ink()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await until(func(): return main._current is TitleScreen, SplashScreen.DURATION + 3.0)
	await wait(0.6)
	await _title()
	await _infinite()
	print("==== NOVIDADES 1.1: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)


# ------------------------------------------------------------------ tinta sem fim
func _ink() -> void:
	var data := LevelDB.get_level(0)
	var lv := Level.new()
	lv.setup(0, data, false)
	add_child(lv)
	await get_tree().physics_frame
	check(lv.drawer.unlimited, "campanha: tinta sem fim")
	var budget := lv.drawer.ink_total
	# um rabisco enorme (3x o orçamento) passa inteiro, sem aviso de tinta acabando
	var pts := PackedVector2Array()
	for i in 120:
		pts.append(Vector2(80 + (i % 2) * 560, 260 + i * 2.0))
	var warned := [false]
	lv.drawer.press(pts[0])
	for p in pts:
		lv.drawer.move(p)
	await get_tree().physics_frame
	check(lv.drawer.drawing and lv.drawer.points.size() > 60, "continua desenhando depois do orçamento (%d pontos)" % lv.drawer.points.size())
	check(lv.drawer.ink_left < 0.0, "orçamento estourado (%.0f de %.0f)" % [lv.drawer.ink_left, budget])
	check(not lv.drawer._empty_warned, "sem aviso nem som de tinta acabando")
	check(Scoring.stars_for(lv.ink_used(), data.get("stars", [0.4, 0.7])) == 1, "acima do orçamento vale 1 estrela")
	lv.queue_free()
	for mode in ["daily", "custom", "practice"]:
		var d := data.duplicate(true)
		d["mode"] = mode
		var l2 := Level.new()
		l2.setup(-1, d, false)
		add_child(l2)
		await get_tree().physics_frame
		check(l2.drawer.unlimited, "%s: tinta sem fim" % mode)
		l2.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------ tela inicial
func _title() -> void:
	var title: TitleScreen = main._current
	var card := find_button(title, func(b): return b is TitleScreen.InfiniteCard)
	check(card != null, "botão novo do Modo Infinito na tela inicial")
	if card != null:
		var r := card.get_global_rect()
		check(r.size.x >= 400 and r.size.y >= 88 and Rect2(0, 0, 720, 1280).encloses(r), "botão do Infinito grande e inteiro na tela (%s)" % r)
	var tile := find_button(title, func(b):
		for c in b.get_children():
			if c is Label and (c as Label).text == "Pintar":
				return true
		return false)
	check(tile != null, "azulejo Pintar na tela inicial")
	if tile != null:
		check(Rect2(0, 0, 720, 1280).encloses(tile.get_global_rect()), "azulejo Pintar inteiro na tela (%s)" % tile.get_global_rect())
		tile.pressed.emit()
		await until(func(): return main._current is PaintScreen, 3.0)
		check(main._current is PaintScreen, "Pintar abre o Ateliê")
		await wait(0.6)
		main._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
		await until(func(): return main._current is TitleScreen, 3.0)
		check(main._current is TitleScreen, "voltar do Ateliê (sem pintar) vai ao título (%s dirty=%s)" % [main._current.get_script().get_global_name(), main._current.get("dirty")])
		await wait(0.4)


# ------------------------------------------------------------------ Modo Infinito
func _infinite() -> void:
	Infinite.run = {}
	main.go("infinite", null)
	await until(func(): return main._current is InfiniteScreen, 3.0)
	await wait(0.4)
	var scr: InfiniteScreen = main._current
	var start := find_button(scr, func(b): return b.text.strip_edges() == "Começar corrida")
	if start == null:
		var all := []
		_all_buttons(scr, all)
		print("  botões: ", all)
	check(start != null, "botão Começar corrida (%s)" % main._current.get_script().get_global_name())
	if start == null:
		return
	var heard := [0]
	var t0 := Time.get_ticks_msec()
	start.pressed.emit()
	await get_tree().process_frame
	check(scr.loading() and scr._loader.visible, "carregamento aparece na hora")
	check(start.disabled, "não dá para começar de novo enquanto prepara")
	check(Sfx.quiet > 0, "efeitos em silêncio enquanto prepara")
	check(Engine.time_scale > 1.0, "preparação acelerada")
	var txt := scr._step.text.to_lower()
	await wait(0.3)
	txt = scr._step.text.to_lower()
	check(txt != "" and not txt.contains("test"), "mensagem do que está fazendo, sem falar em teste (%s)" % scr._step.text)
	main._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await get_tree().process_frame
	check(main._current == scr, "voltar do Android não interrompe o carregamento")
	var ok := await until(func(): return main._current is Level, 12.0)
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	check(ok, "a fase abre depois de pronta")
	check(secs < 6.0, "carregamento rápido (%.1f s)" % secs)
	print("  carregamento da fase 1: %.1f s" % secs)
	check(Sfx.quiet == 0 and is_equal_approx(Engine.time_scale, 1.0) and Engine.physics_ticks_per_second == 60, "som e física normais na partida")
	var hearts := int(Infinite.run.get("hearts", 0))
	# o jogador fica pensando: nada roda escondido e os corações não mudam
	await wait(4.0)
	check(not main.infinite.is_working(), "nada é preparado escondido durante a partida")
	check(int(Infinite.run.get("hearts", 0)) == hearts and hearts == Infinite.HEARTS, "corações intactos (%d)" % int(Infinite.run.get("hearts", 0)))
	var lv: Level = main._current
	check(lv.mode == "infinite" and not lv.drawer.unlimited, "Modo Infinito mantém o desafio da tinta")
	# perder de verdade tira exatamente um coração
	lv.start_simulation()
	await until(func(): return lv.state == Level.State.LOST, 15.0)
	await wait(1.6)
	check(int(Infinite.run.get("hearts", 0)) == Infinite.HEARTS - 1, "perder tira um coração só (%d)" % int(Infinite.run.get("hearts", 0)))
	main.go("title", null)
	await until(func(): return main._current is TitleScreen, 3.0)
	check(Sfx.quiet == 0 and is_equal_approx(Engine.time_scale, 1.0), "tudo normal ao sair")


func _all_buttons(n: Node, out: Array) -> void:
	if n is Button:
		out.append([(n as Button).text, (n as Button).is_visible_in_tree()])
	for c in n.get_children():
		_all_buttons(c, out)
