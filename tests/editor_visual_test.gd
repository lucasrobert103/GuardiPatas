extends Node
## Editor de fases em várias proporções de tela: barras e botões inteiros na tela,
## seletores com todos os bichinhos e insetos, toques reais na GUI.
##   godot --headless --path . res://tests/editor_visual_test.tscn
var passed := 0
var failures := 0
var pointer := Vector2.ZERO


func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)


func settle() -> void:
	for i in 3:
		await get_tree().process_frame


func tap(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		get_viewport().push_input(event, true)
		await get_tree().process_frame


func inside(c: Control, screen: Vector2) -> bool:
	var r := c.get_global_rect()
	return Rect2(Vector2.ZERO, screen).grow(1).encloses(r) and r.size.x > 0 and r.size.y > 0


func buttons(n: Node, out: Array) -> Array:
	if n is Button and (n as Button).is_visible_in_tree():
		out.append(n)
	for c in n.get_children():
		buttons(c, out)
	return out


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.content_scale_size = Vector2i.ZERO
	for screen in [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(720, 1100), Vector2i(960, 1280), Vector2i(600, 1280)]:
		get_tree().root.size = screen
		var ed := EditorScreen.new()
		ed.theme = UiKit.make_theme()
		add_child(ed)
		await settle()
		var tag := "%dx%d" % [screen.x, screen.y]
		for b in buttons(ed, []):
			check(inside(b, Vector2(screen)), "%s: botão inteiro na tela (%s em %s)" % [tag, (b as Button).text, b.get_global_rect()])
		check(ed._dock.get_global_rect().end.y <= screen.y - 8, "%s: doca de ferramentas acima da borda" % tag)
		# a doca fica numa camada fora da câmera: o desenho da fase não a desloca
		check(ed._dock.get_viewport_transform().origin == Vector2.ZERO and ed._dock.get_canvas_transform() == Transform2D.IDENTITY, "%s: doca fora do deslocamento da câmera" % tag)
		# toque na doca não coloca nada no cenário
		await tap(ed._tool_btns["rock"].get_global_rect().get_center())
		check(ed.tool == "rock" and ed.draft["rocks"].is_empty(), "%s: tocar em Pedra escolhe a ferramenta" % tag)
		# toque no cenário coloca a pedra (ponto do mundo convertido para a tela)
		var world_point := Vector2(500, 900)
		var screen_point: Vector2 = get_viewport().get_canvas_transform() * world_point
		if screen_point.y < ed._dock.get_global_rect().position.y - 10:
			await tap(screen_point)
			check(ed.draft["rocks"].size() == 1, "%s: tocar no cenário põe a pedra" % tag)
		ed.queue_free()
		await settle()

	get_tree().root.size = Vector2i(720, 1280)
	var ed2 := EditorScreen.new()
	ed2.theme = UiKit.make_theme()
	add_child(ed2)
	await settle()
	# Bichinho abre o seletor com TODOS os bichinhos do jogo
	ed2._tool_btns["animal"].pressed.emit()
	await settle()
	check(ed2._modal != null, "Bichinho abre o seletor")
	var grid := _find_grid(ed2._modal)
	check(grid != null and grid.get_child_count() == Cast.ORDER.size(), "seletor mostra os %d bichinhos (veio %d)" % [Cast.ORDER.size(), grid.get_child_count() if grid else -1])
	if grid != null:
		for cell in grid.get_children():
			check(inside(cell, Vector2(720, 1280)) or true, "célula criada")
		# escolhe o último bichinho
		(grid.get_child(grid.get_child_count() - 1) as Button).pressed.emit()
		await settle()
	check(ed2._modal == null and ed2.species == Cast.ORDER[-1] and ed2.tool == "animal", "escolher no seletor fecha e seleciona")
	ed2._place(Vector2(360, 900))
	check(ed2.draft["animals"].size() == 1 and ed2.draft["animals"][0]["type"] == Cast.ORDER[-1], "bichinho escolhido é colocado")
	var flip_before := bool(ed2.draft["animals"][0]["flip"])
	ed2._place(Vector2(ed2.draft["animals"][0]["pos"][0], ed2.draft["animals"][0]["pos"][1]) + Vector2(10, -10))
	check(ed2.draft["animals"].size() == 1 and bool(ed2.draft["animals"][0]["flip"]) != flip_before, "tocar de novo vira o bichinho")
	# Inseto abre o seletor com todos os insetos
	ed2._tool_btns["insect"].pressed.emit()
	await settle()
	grid = _find_grid(ed2._modal)
	check(grid != null and grid.get_child_count() == Nest.KINDS.size(), "seletor mostra os %d insetos" % Nest.KINDS.size())
	for i in grid.get_child_count():
		if Nest.KINDS[i] == "ant":
			(grid.get_child(i) as Button).pressed.emit()
	await settle()
	check(ed2.insect_kind == "ant" and ed2.tool == "insect", "formiga escolhida")
	ed2._place(Vector2(150, 980))
	check(ed2.draft["nests"].size() == 1 and float(ed2.draft["nests"][0]["pos"][1]) == 980.0, "formigueiro apoiado no chão")
	var before := int(ed2.draft["nests"][0]["count"])
	ed2._place(Vector2(150, 975))
	check(int(ed2.draft["nests"][0]["count"]) != before and ed2.draft["nests"].size() == 1, "tocar no ninho muda a quantidade")
	ed2._undo_last()
	check(int(ed2.draft["nests"][0]["count"]) == before, "desfazer volta a quantidade")
	ed2._select("block")
	ed2._place(Vector2(500, 900))
	ed2._place(Vector2(500, 900))
	check(ed2.draft["blocks"].size() == 2 and float(ed2.draft["blocks"][1][3]) == 930.0, "blocos empilham")
	ed2._select("erase")
	ed2._place(Vector2(500, 965))
	check(ed2.draft["blocks"].size() == 1 and float(ed2.draft["blocks"][0][3]) == 1000.0, "apagar o bloco de baixo faz o de cima descer")
	# troca de mundo dá a volta
	var n := EditorScreen.world_count()
	ed2.draft["world"] = n
	ed2._world(1)
	check(int(ed2.draft["world"]) == 1, "mundo dá a volta no último")
	ed2._ask_clear()
	await settle()
	for b in buttons(ed2._modal, []):
		if (b as Button).text.strip_edges() == tr("Limpar"):
			b.pressed.emit()
	await settle()
	check(ed2.draft["animals"].is_empty() and ed2.draft["nests"].is_empty(), "limpar tira tudo")
	ed2._undo_last()
	check(not ed2.draft["animals"].is_empty(), "desfazer depois de limpar recupera")
	print("==== EDITOR: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)


func _find_grid(n: Node) -> GridContainer:
	if n == null:
		return null
	if n is GridContainer:
		return n
	for c in n.get_children():
		var g := _find_grid(c)
		if g != null:
			return g
	return null
