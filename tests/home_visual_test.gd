extends Node
## Gestos reais da GUI e limites dos objetos em múltiplas proporções de tela.
var passed := 0
var failures := 0
var home: HomeScreen
var pointer := Vector2.ZERO


func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)


func settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func move(point: Vector2, held: bool = false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.relative = point - pointer
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	pointer = point
	get_viewport().push_input(event, true)
	await get_tree().process_frame


func button(down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = pointer
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	get_viewport().push_input(event, true)
	await get_tree().process_frame


func tap(point: Vector2) -> void:
	await move(point)
	await button(true)
	await button(false)


func drag(source: Vector2, target: Vector2) -> void:
	await move(source)
	await button(true)
	for i in range(1, 9):
		await move(source.lerp(target, i / 8.0), true)
	await button(false)


func inside(control: Control) -> bool:
	var rect := control.get_global_rect()
	return Rect2(Vector2.ZERO, home.size).grow(1).encloses(rect) and rect.size.x > 0 and rect.size.y > 0


func no_text_buttons(node: Node) -> bool:
	if node is Button and not node.text.is_empty():
		return false
	if node is OptionButton or node is ProgressBar:
		return false
	for child in node.get_children():
		if not no_text_buttons(child):
			return false
	return true


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.content_scale_size = Vector2i.ZERO
	get_tree().root.size = Vector2i(720, 1280)
	Game.persist = false
	Game.load_save()
	Game.data["met"] = Cast.ORDER.duplicate()
	Game.data["store"]["owned"] = ["pet_amora", "pet_bambu", "pet_gotinha"]
	Game.data["coins"] = 1000
	home = HomeScreen.new()
	home.theme = UiKit.make_theme()
	add_child(home)
	await settle()
	home.set_process(false)
	home._process(0)
	check(home._pets.size() == Cast.ORDER.size() + 3, "todos os resgatados e companheiros no carrossel")
	var visible_pets := 0
	for pet in home._pets:
		if pet.art.visible: visible_pets += 1
	check(visible_pets == 1, "um amigo em destaque")
	check(not home._status.visible, "nenhum parágrafo de instruções persistente")
	check(no_text_buttons(home), "objetos ilustrados sem botões de texto nem listas de opções")
	await tap(home._dock["food"].get_global_rect().get_center())
	check(home._mode == "food", "cozinha abre pelo objeto do menu")
	var state := PetCare.state("capi")
	state["food"] = 10.0
	await tap(home._objects["meal"].get_global_rect().get_center())
	check(state["food"] == 40, "tocar no prato alimenta exatamente uma vez")
	await drag(home._objects["fruit"].get_global_rect().get_center(), home._hero().art.position)
	check(state["food"] == 60 and not home._ghost.visible, "arrastar fruta até o bichinho alimenta e recolhe o objeto")
	await drag(home._objects["snack"].get_global_rect().get_center(), home._stage.position + Vector2(40, 30))
	check(state["food"] == 60, "soltar comida fora do bichinho cancela")
	# Movimento lento, abaixo do limiar por evento, ainda precisa ser um arraste.
	var food_point: Vector2 = home._objects["snack"].get_global_rect().get_center()
	await move(food_point)
	await button(true)
	for i in range(1, 51): await move(food_point + Vector2(i * 2, 0), true)
	await button(false)
	check(state["food"] == 60, "arraste lento para fora não vira alimentação por toque")
	# Ativação pelo teclado não deixa um objeto grudado no ponteiro.
	home._objects["meal"].grab_focus()
	for down in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_SPACE
		key.pressed = down
		get_viewport().push_input(key, true)
		await get_tree().process_frame
	check(state["food"] == 90 and home._drag_kind.is_empty(), "teclado alimenta sem iniciar arraste")

	await tap(home._dock["bath"].get_global_rect().get_center())
	home._process(0)
	state["clean"] = 10.0
	await drag(home._objects["soap"].get_global_rect().get_center(), home._hero().art.position)
	check(home._soap > 0, "sabão arrastado faz espuma")
	for i in 4: await tap(home._hero().art.position)
	check(home._soap == 1, "banho também funciona só com toques")
	await tap(home._objects["shower"].get_global_rect().get_center())
	check(state["clean"] == 100 and home._wet and home._soap == 0, "chuveiro limpa e enxágua")
	await tap(home._objects["towel"].get_global_rect().get_center())
	check(not home._wet, "toalha seca")
	await tap(home._dock["sleep"].get_global_rect().get_center())
	await tap(home._objects["bed"].get_global_rect().get_center())
	check(state["sleeping"], "tocar na cama coloca para dormir")
	home._process(0)
	check(home._name_label.label_settings.font_color.get_luminance() > 0.8, "nome continua legível no quarto escuro")
	await tap(home._objects["lamp"].get_global_rect().get_center())
	check(not state["sleeping"], "luminária acorda")
	home._process(0)
	check(home._name_label.label_settings.font_color == HomeArt.INK, "contraste diurno volta ao acordar")

	await tap(home._dock["clothes"].get_global_rect().get_center())
	await settle()
	var rail: HBoxContainer = home._wardrobe_scroll.get_child(0)
	var hat: HomeObject = rail.get_child(1)
	var coins := Game.coins()
	await tap(hat.get_global_rect().get_center())
	check(home._hero().art.accessory == "bone" and not Game.owns("bone") and Game.coins() == coins, "experimentar roupa não compra")
	check(home._buy.visible and home._wallet.cost == coins, "preço contextual e saldo disponíveis")
	await tap(home._buy.get_global_rect().get_center())
	check(Game.owns("bone") and Game.equipped("capi") == "bone" and Game.coins() == coins - 60, "compra explícita custa uma vez e veste")
	check(home._wallet.cost == Game.coins() and not home._buy.visible, "saldo atualiza e compra desaparece")
	await tap(rail.get_child(0).get_global_rect().get_center())
	check(Game.equipped("capi").is_empty(), "cabide vazio tira acessório")
	var old_buy := home._buy
	await tap(home._dock["food"].get_global_rect().get_center())
	await settle()
	check(not is_instance_valid(old_buy) and home._buy == null and home._wallet == null, "sair do guarda-roupa remove controles de compra")

	await tap(home._dock["play"].get_global_rect().get_center())
	home._process(0)
	state["energy"] = 80.0
	var catches := home._catches
	var start := home._ball.position
	await drag(start, start + Vector2(-100, -60))
	check(home._catches == catches + 1 and not home._ball.freeze and home._ball.linear_velocity.length() > 20, "bola física lançada pelo gesto")
	var transform: Transform2D = PhysicsServer2D.body_get_state(home._ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM)
	check(transform.origin.distance_to(start + Vector2(-100, -60)) < 30, "lançamento parte do ponto onde o dedo soltou")
	var bounced := false
	var falling := false
	for i in 180:
		await get_tree().physics_frame
		if home._ball.linear_velocity.y > 30: falling = true
		if falling and home._ball.linear_velocity.y < -30: bounced = true
	check(bounced, "bola cai pela gravidade e quica no chão")
	check(home._ball.bounds.grow(2).has_point(home._ball.position), "paredes mantêm bola dentro da sala")

	for dimensions in [Vector2i(360, 640), Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(1024, 1366), Vector2i(1280, 720)]:
		get_tree().root.size = dimensions
		await settle()
		for mode in ["play", "food", "bath", "sleep", "clothes"]:
			home._set_mode(mode)
			home._process(0)
			await settle()
			var valid := inside(home._back) and inside(home._album) and inside(home._roster_scroll)
			for object in home._dock.values(): valid = valid and inside(object)
			for need in home._needs.values(): valid = valid and inside(need) and need.get_global_rect().end.y <= home._stage.position.y
			for object in home._objects.values():
				valid = valid and inside(object) and object.get_global_rect().end.y <= home._roster_scroll.position.y
			if mode == "clothes":
				home._try_on("coroa")
				valid = valid and inside(home._buy) and inside(home._wallet) and inside(home._wardrobe_scroll)
				valid = valid and not home._buy.get_global_rect().intersects(home._wardrobe_scroll.get_global_rect())
			if mode == "play":
				valid = valid and home._ball.bounds.grow(1).has_point(home._ball.position)
			check(valid and no_text_buttons(home), "objetos dentro da tela e separados da navegação: %s %s" % [dimensions, mode])
	home.queue_free()
	await settle()
	print("==== CASINHA VISUAL: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)
