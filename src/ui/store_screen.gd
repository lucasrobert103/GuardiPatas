class_name StoreScreen
extends Control

signal go(screen: String, arg: Variant)
var _content: VBoxContainer
var _status: Label
var _balance: Label
var _modal: Control
var _pending := ""
var _answer := 0
var _entry: LineEdit


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBg.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var box := UiKit.vbox(12)
	margin.add_child(box)
	var back := UiKit.button("Voltar", Palette.UI_SECONDARY, "back", 0, 64)
	back.pressed.connect(func(): go.emit("title", null))
	box.add_child(back)
	box.add_child(UiKit.label("Lojinha da Turma", 42))
	box.add_child(UiKit.label("TESTE · Sem cobrança" if Store.test_mode() else "Compras indisponíveis", 26, Palette.UI_TEXT))
	_balance = UiKit.label("", 26)
	box.add_child(_balance)
	_status = UiKit.label("Preços ilustrativos. Moedas e compras de teste ficam em um progresso separado.\nOs novos amigos vivem na Casinha; não substituem animais nas fases.", 22, Palette.UI_TEXT, 0, Palette.WHITE, true)
	box.add_child(_status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_content = UiKit.vbox(16)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)
	_refresh()


func _refresh() -> void:
	_balance.text = "%d moedas · %d dicas" % [Game.coins(), Game.hints()]
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	for id in Store.PRODUCTS:
		var product: Dictionary = Store.PRODUCTS[id]
		var panel := UiKit.panel()
		_content.add_child(panel)
		var box := UiKit.vbox(10)
		panel.add_child(box)
		if product.has("pets"):
			var portrait := Control.new()
			portrait.custom_minimum_size = Vector2(0, 140)
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var art := AnimalArt.new()
			art.species = product["pets"][0]
			art.preview = true
			art.position = Vector2(290, 80)
			art.scale = Vector2(1.5, 1.5)
			portrait.add_child(art)
			box.add_child(portrait)
		box.add_child(UiKit.label(product["name"], 28))
		var desc := UiKit.label(product["description"], 22, Palette.UI_TEXT, 0, Palette.WHITE, true)
		desc.custom_minimum_size = Vector2(540, 0)
		box.add_child(desc)
		var have: bool = Store.owned(id) and not product.get("repeatable", false)
		var buy := UiKit.button("Adquirido" if have else "Testar compra · " + product["price"], Palette.UI_GOOD, "", 0, 72)
		buy.disabled = have or not Store.test_mode()
		buy.pressed.connect(_ask.bind(id))
		box.add_child(buy)
	var wardrobe := UiKit.button("Usar moedas em roupinhas", Palette.UI_SECONDARY, "", 0, 72)
	wardrobe.pressed.connect(func(): go.emit("collection", "wardrobe"))
	_content.add_child(wardrobe)
	var home := UiKit.button("Visitar companheiros na Casinha", Palette.UI_SECONDARY, "", 0, 72)
	home.pressed.connect(func(): go.emit("home", null))
	_content.add_child(home)


func _ask(id: String) -> void:
	if _modal != null or not Store.test_mode() or not Store.PRODUCTS.has(id):
		return
	_pending = id
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)
	_modal.add_child(UiKit.dim())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(center)
	var panel := UiKit.panel()
	panel.custom_minimum_size = Vector2(580, 0)
	center.add_child(panel)
	var box := UiKit.vbox(16)
	panel.add_child(box)
	box.add_child(UiKit.label("Área dos responsáveis", 32))
	var a := randi_range(12, 29)
	var b := randi_range(12, 29)
	_answer = a + b
	var notice := UiKit.label("Peça a um responsável para continuar.\n%s · %s (valor ilustrativo)\nSimulação sem cobrança. Quanto é %d + %d?" % [Store.PRODUCTS[id]["name"], Store.PRODUCTS[id]["price"], a, b], 24, Palette.UI_TEXT, 0, Palette.WHITE, true)
	notice.custom_minimum_size = Vector2(500, 0)
	box.add_child(notice)
	_entry = LineEdit.new()
	_entry.placeholder_text = "Resposta"
	_entry.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_entry.custom_minimum_size.y = 64
	box.add_child(_entry)
	var cancel := UiKit.button("Cancelar", Palette.UI_SECONDARY, "", 0, 70)
	cancel.pressed.connect(_cancel)
	box.add_child(cancel)
	var pay := UiKit.button("Pagar (simulação)", Palette.UI_GOOD, "", 0, 70)
	pay.pressed.connect(_pay)
	box.add_child(pay)
	_entry.grab_focus()


func _cancel() -> void:
	_pending = ""
	if _modal != null:
		remove_child(_modal)
		_modal.queue_free()
		_modal = null


func _pay() -> void:
	if _pending.is_empty():
		return
	if not _entry.text.is_valid_int() or _entry.text.to_int() != _answer:
		_entry.clear()
		_entry.placeholder_text = "Peça ajuda a um responsável e tente novamente"
		return
	var result := Store.checkout(_pending, Store.new_order_id())
	_cancel()
	_status.text = result["message"]
	_refresh()
