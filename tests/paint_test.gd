extends Node
## Ateliê: desenha com todas as ferramentas pelo toque de verdade, pinta com o balde,
## coloca adesivos, troca de modelo, desfaz/refaz, apaga e salva no Álbum.
##   godot --headless --path . res://tests/paint_test.tscn
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/paint_test.tscn -- --shot=/tmp/ateliê.png
var passed := 0
var failures := 0
var paint: PaintScreen
var pointer := Vector2.ZERO
var last_go: Array = []
## Sem placa de vídeo (CI headless) as imagens da tela vêm vazias: as conferências de
## pixel e o balde (que lê a imagem) só rodam com renderização de verdade.
var gpu := DisplayServer.get_name() != "headless"


func check(v: bool, msg: String) -> void:
	if v:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", msg)


func frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame


func post() -> void:
	if gpu:
		await RenderingServer.frame_post_draw
	else:
		await get_tree().process_frame


func move(p: Vector2, held: bool) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	e.relative = p - pointer
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	pointer = p
	get_viewport().push_input(e, true)
	await get_tree().process_frame


func button(down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.position = pointer
	e.global_position = pointer
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	get_viewport().push_input(e, true)
	await get_tree().process_frame


## Ponto da tela (0..1 dentro do quadro de pintura).
func at(u: float, v: float) -> Vector2:
	var r := paint._display.get_global_rect()
	return r.position + r.size * Vector2(u, v)


func stroke(pts: Array) -> void:
	await move(at(pts[0][0], pts[0][1]), false)
	await button(true)
	for i in range(1, pts.size()):
		var a: Vector2 = at(pts[i - 1][0], pts[i - 1][1])
		var b: Vector2 = at(pts[i][0], pts[i][1])
		for k in 6:
			await move(a.lerp(b, (k + 1) / 6.0), true)
	await button(false)


func tap(p: Vector2) -> void:
	await move(p, false)
	await button(true)
	await button(false)


func press_tool(id: String) -> void:
	var b: Button = paint._tool_btns[id]
	await tap(b.get_global_rect().get_center())


func pixel(u: float, v: float) -> Color:
	var img := paint._view.get_texture().get_image()
	return img.get_pixel(int(u * PaintScreen.CANVAS.x), int(v * PaintScreen.CANVAS.y))


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	Legal.accept()
	Game.set_setting("lang", "pt_BR")
	get_window().size = Vector2i(720, 1280)
	var shot := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.substr(7)
	paint = PaintScreen.new()
	paint.theme = UiKit.make_theme()
	paint.go.connect(func(s, arg): last_go = [s, arg])
	add_child(paint)
	await frames(6)

	# layout: tudo dentro da tela, quadro e doca sem sobrepor, acima da faixa de gestos
	var frame := paint._frame.get_global_rect()
	var dock := paint._dock.get_global_rect()
	check(Rect2(0, 0, 720, 1280).encloses(frame) and Rect2(0, 0, 720, 1280).encloses(dock), "quadro e doca dentro da tela")
	check(frame.end.y <= dock.position.y, "quadro acima da doca")
	check(dock.end.y <= 1280 - UiKit.GESTURE_GAP + 10, "doca acima da faixa de gestos")
	check(frame.size.x > 560, "quadro grande (%d px)" % frame.size.x)
	for id in paint._tool_btns:
		var r: Rect2 = (paint._tool_btns[id] as Control).get_global_rect()
		check(r.size.x >= 52 and Rect2(0, 0, 720, 1280).encloses(r), "ferramenta %s visível e tocável" % id)

	# 1) pincel vermelho: o traço aparece onde o dedo passou
	await press_tool("brush")
	paint._pick_color(Color("ff5d73"))
	await stroke([[0.1, 0.2], [0.5, 0.25], [0.9, 0.2]])
	await frames(3)
	await post()
	if gpu:
		var px := pixel(0.5, 0.25)
		check(px.r > 0.8 and px.g < 0.6, "pincel pinta de vermelho onde passou (%s)" % px)
	check(paint._actions.size() == 1 and paint.dirty, "traço vira uma ação desfazível")

	# 2) todas as outras ferramentas de traço
	var y := 0.3
	for id in ["pencil", "crayon", "rainbow", "glitter", "neon", "spray"]:
		await press_tool(id)
		y += 0.06
		await stroke([[0.15, y], [0.85, y]])
		check(paint.tool == id, "ferramenta %s selecionada" % id)
	check(paint._actions.size() == 7, "7 traços feitos (%d)" % paint._actions.size())

	if shot != "":
		await frames(3)
		await post()
		get_viewport().get_texture().get_image().save_png(shot.replace(".png", "_pinceis.png"))

	# 3) borracha apaga o pincel
	await press_tool("eraser")
	paint._pick_size(3)
	await stroke([[0.45, 0.25], [0.55, 0.25]])
	await frames(3)
	await post()
	if gpu:
		var er := pixel(0.5, 0.25)
		check(er.r > 0.95 and er.g > 0.95 and er.b > 0.9, "borracha volta ao papel (%s)" % er)

	# 4) desfazer / refazer
	paint.undo()
	await frames(3)
	await post()
	if gpu:
		check(pixel(0.5, 0.25).g < 0.6, "desfazer traz o traço de volta")
	check(paint._redo.size() == 1, "desfazer guarda para refazer")
	paint.redo()
	await frames(2)
	check(paint._redo.is_empty() and paint._actions.size() == 8, "refazer devolve a borracha")

	# 5) modelo para colorir + balde de tinta dentro do desenho
	paint._open_templates()
	await frames(3)
	check(paint._modal != null, "janela de modelos abre")
	var cells := []
	_collect(paint._modal, TemplateCellType(), cells)
	check(cells.size() == PaintArt.TEMPLATES.size(), "todos os modelos aparecem (%d)" % cells.size())
	for c in cells:
		if (c as PaintScreen.TemplateCell).template == "hearts":
			(c as Button).pressed.emit()
	await frames(3)
	check(paint.template == "hearts" and paint._modal == null, "escolher o modelo fecha a janela")
	paint.clear_all()
	await frames(2)
	await press_tool("fill")
	paint._pick_color(Color("7ed957"))
	await tap(at(0.5, 0.5))   # dentro do coração pequeno
	for i in 30:
		await frames(1)
		if paint._actions.size() > 0:
			break
	await frames(3)
	await post()
	if gpu:
		var inside := pixel(0.5, 0.5)
		var outside := pixel(0.03, 0.97)
		check(paint._actions.size() == 1, "balde vira uma ação desfazível")
		check(inside.g > 0.75 and inside.r < 0.6, "balde pinta dentro do coração (%s)" % inside)
		check(outside.r > 0.95 and outside.g > 0.95, "balde não vaza para fora das linhas (%s)" % outside)

	# 6) adesivos: forma, bichinho e inseto; mover, aumentar, virar, apagar
	await press_tool("sticker")
	check(paint._sticker_scroll.visible and paint._cat_row.visible, "adesivos mostram a galeria")
	await tap(at(0.2, 0.15))
	check(paint._stickers.get_child_count() == 1 and paint._selected != null, "toque coloca o adesivo e seleciona")
	var s0: Node2D = paint._stickers.get_child(0)
	var p0 := s0.position
	await move(at(0.2, 0.15), false)
	await button(true)
	await move(at(0.3, 0.2), true)
	await move(at(0.35, 0.22), true)
	await button(false)
	check(s0.position.distance_to(p0) > 40, "arrastar move o adesivo")
	var sc := s0.scale.y
	paint._sticker_action("bigger")
	check(s0.scale.y > sc, "botão + aumenta")
	paint._sticker_action("flip")
	check(s0.scale.x < 0, "virar espelha")
	paint._show_stickers("animals")
	await frames(2)
	check(paint._sticker_row.get_child_count() == Animal.SPECIES.size(), "todos os bichinhos como adesivo")
	paint.sticker = "animal:capi"
	await tap(at(0.75, 0.82))
	paint._show_stickers("insects")
	await frames(2)
	check(paint._sticker_row.get_child_count() == Nest.KINDS.size(), "todos os insetos como adesivo")
	paint.sticker = "insect:ladybug"
	await tap(at(0.85, 0.12))
	check(paint._stickers.get_child_count() == 3, "3 adesivos na pintura")
	paint._sticker_action("delete")
	check(paint._stickers.get_child_count() == 2 or paint._stickers.get_child(2).is_queued_for_deletion(), "apagar adesivo selecionado")
	await frames(2)

	# 7) salvar no Álbum
	var before: int = Game.data["album"].size()
	var file := ""
	if gpu:
		var res: Dictionary = await paint.save_to_album()
		check(Game.data["album"].size() == before + 1, "salva no Álbum")
		file = str(res.get("entry", {}).get("file", ""))
		var saved := Image.load_from_file(file) if file != "" else null
		check(saved != null and saved.get_width() == PaintScreen.CANVAS.x, "imagem salva no tamanho da pintura")
		check(not paint.dirty, "depois de salvar não pede para salvar de novo")

	if shot != "":
		paint._select_sticker(null)
		paint._select_tool("brush")
		await frames(4)
		await post()
		get_viewport().get_texture().get_image().save_png(shot)
		print("salvo ", shot)

	# 8) voltar sem mudanças sai direto; com mudanças pergunta
	await press_tool("brush")
	await stroke([[0.2, 0.9], [0.4, 0.9]])
	paint.on_back_pressed()
	await frames(2)
	check(paint._modal != null and last_go.is_empty(), "voltar com pintura nova pergunta se quer salvar")
	paint._leave()
	check(last_go.size() == 2 and last_go[0] == "title", "sair volta ao título")
	check(not PaintScreen._session.is_empty(), "pintura fica guardada para continuar depois")
	if file != "":
		Game.remove_photo(Game.data["album"].size() - 1)
	print("==== ATELIÊ: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)


func TemplateCellType() -> String:
	return "TemplateCell"


func _collect(n: Node, _t: String, out: Array) -> void:
	if n is PaintScreen.TemplateCell:
		out.append(n)
	for c in n.get_children():
		_collect(c, _t, out)
