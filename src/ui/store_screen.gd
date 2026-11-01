class_name StoreScreen
extends Control
## Lojinha em abas: Destaques (pacotes), Moedas, Bichinhos (mágicos e companheiros) e
## Efeitos (comprados com moedas do jogo, equipados em qualquer bichinho).
## Toda compra com dinheiro passa pela Área dos responsáveis (conta de somar).

signal go(screen: String, arg: Variant)

var _tab := "destaque"
var _content: VBoxContainer
var _status: Label
var _balance: Label
var _modal: Control
var _pending := ""
var _answer := 0
var _entry: LineEdit
var _tab_btns: Dictionary = {}
var _fx_target := "capi"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBg.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiKit.keep_safe(margin, 18, 22, 18, 22)
	add_child(margin)
	var box := UiKit.vbox(10)
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	margin.add_child(box)
	var head := UiKit.hbox(10)
	box.add_child(head)
	var back := UiKit.icon_button("back", Palette.UI_PANEL, 76)
	back.pressed.connect(func(): go.emit("title", null))
	head.add_child(back)
	var title := UiKit.label("Lojinha da Turma", 38, Palette.WHITE, 12, Palette.OUTLINE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	head.add_child(title)
	var chip := UiKit.panel(Palette.GOLD)
	var cs := UiKit.panel_style(Palette.GOLD, 24)
	cs.content_margin_top = 6
	cs.content_margin_bottom = 6
	cs.content_margin_left = 14
	cs.content_margin_right = 14
	chip.add_theme_stylebox_override("panel", cs)
	head.add_child(chip)
	_balance = UiKit.label("", 22)
	chip.add_child(_balance)
	var mode := "TESTE · Sem cobrança" if Store.test_mode() else ("" if Store.real_mode() else "Compras indisponíveis neste aparelho")
	if mode != "":
		box.add_child(UiKit.label(mode, 22, Palette.WHITE, 8, Palette.OUTLINE))
	var tabs := UiKit.hbox(8)
	box.add_child(tabs)
	for t in Store.CATEGORIES:
		var b := UiKit.button(t[1], Palette.UI_SECONDARY, "", 0, 70)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.add_theme_font_size_override("font_size", UiKit.fs(22))
		var id: String = t[0]
		b.pressed.connect(func():
			_tab = id
			_refresh())
		tabs.add_child(b)
		_tab_btns[id] = b
	_status = UiKit.label("", 21, Palette.WHITE, 8, Palette.OUTLINE, true)
	box.add_child(_status)
	var scroll := ScrollContainer.new()
	DragScroll.attach(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_content = UiKit.vbox(14)
	_content.alignment = BoxContainer.ALIGNMENT_BEGIN
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)
	Store.purchase_finished.connect(_on_purchase_finished)
	if not Game.data["met"].is_empty():
		_fx_target = str(Game.data["met"][0])
	_refresh()
	Sfx.music("music_menu")


func _exit_tree() -> void:
	if Store.purchase_finished.is_connected(_on_purchase_finished):
		Store.purchase_finished.disconnect(_on_purchase_finished)


func _refresh() -> void:
	_balance.text = tr("%d moedas · %d dicas") % [Game.coins(), Game.hints()]
	for k in _tab_btns:
		var b: Button = _tab_btns[k]
		var col := Palette.GOLD if k == _tab else Palette.UI_SECONDARY
		b.add_theme_stylebox_override("normal", UiKit.btn_style(col, false))
		b.add_theme_stylebox_override("hover", UiKit.btn_style(col.lightened(0.06), false))
	if _status.text == "":
		_status.text = tr("Os bichinhos da loja vivem na Casinha e os efeitos são só enfeite: nada muda a dificuldade das fases.")
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	match _tab:
		"efeitos":
			_build_effects()
		_:
			for id in Store.products_in(_tab):
				_content.add_child(_product_card(id))
			if _tab == "bichinhos":
				var home := UiKit.button("Visitar os bichinhos na Casinha", Palette.UI_SECONDARY, "house", 0, 72)
				home.pressed.connect(func(): go.emit("home", null))
				_content.add_child(home)
			if _tab == "moedas":
				var wardrobe := UiKit.button("Usar moedas em roupinhas", Palette.UI_SECONDARY, "coin", 0, 72)
				wardrobe.pressed.connect(func(): go.emit("collection", "wardrobe"))
				_content.add_child(wardrobe)


func _product_card(id: String) -> Control:
	var product: Dictionary = Store.PRODUCTS[id]
	var panel := UiKit.panel(Palette.CREAM if product.has("tag") else Palette.UI_PANEL)
	var row := UiKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	panel.add_child(row)
	var pic := _preview(product)
	# tocar no desenho também abre a prévia
	pic.mouse_filter = Control.MOUSE_FILTER_STOP
	pic.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_show_product(id))
	row.add_child(pic)
	var col := UiKit.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var name_row := UiKit.hbox(8)
	name_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_child(name_row)
	var n := UiKit.label(product["name"], 26)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_row.add_child(n)
	if product.has("tag"):
		var tag := PanelContainer.new()
		var ts := UiKit.panel_style(Palette.DANGER, 14)
		ts.content_margin_top = 2
		ts.content_margin_bottom = 2
		ts.content_margin_left = 10
		ts.content_margin_right = 10
		ts.set_border_width_all(3)
		tag.add_theme_stylebox_override("panel", ts)
		tag.add_child(UiKit.label(product["tag"], 17, Palette.WHITE))
		name_row.add_child(tag)
	var desc := UiKit.label(product["description"], 20, Palette.UI_TEXT, 0, Palette.WHITE, true)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc.custom_minimum_size = Vector2(300, 0)
	col.add_child(desc)
	var have: bool = Store.fully_owned(id)
	var label := "Adquirido" if have else (("Testar · " if Store.test_mode() else "Comprar · ") + Store.price_of(id))
	var buy := UiKit.button(label, Palette.UI_GOOD, "" if have else "coin", 0, 68)
	buy.add_theme_font_size_override("font_size", UiKit.fs(22))
	buy.disabled = have or not Store.can_buy()
	buy.pressed.connect(_show_product.bind(id))
	col.add_child(buy)
	return panel


## Sempre mostra a prévia antes; o "Comprar" da prévia leva à Área dos responsáveis.
func _show_product(id: String) -> void:
	if _modal != null or not Store.PRODUCTS.has(id):
		return
	var p := ProductPreview.open(self, "product", id, func(): _ask.call_deferred(id))
	if Store.fully_owned(id) or not Store.can_buy():
		p._confirm.disabled = true


## Desenho do produto: o bichinho (com o efeito dele), o efeito num amigo ou um montinho de moedas.
func _preview(product: Dictionary) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(150, 150)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pets: Array = product.get("pets", [])
	if not pets.is_empty():
		for i in mini(pets.size(), 3):
			var art := AnimalArt.new()
			art.species = pets[i]
			art.preview = true
			art.scale = Vector2.ONE * (1.25 if pets.size() == 1 else 0.75)
			art.position = Vector2(75, 92) if pets.size() == 1 else Vector2(40 + i * 36, 70 + (i % 2) * 40)
			holder.add_child(art)
		return holder
	if product.has("effects"):
		var art := AnimalArt.new()
		art.species = "capi"
		art.preview = true
		art.effect = "arco_iris"
		art.position = Vector2(75, 95)
		holder.add_child(art)
		return holder
	var icon := "hint" if product.has("hints") and not product.has("coins") else ("star" if product.get("vip", false) else "coin")
	var stacks := clampi(int(product.get("coins", 0)) / 1000 + 1, 1, 5)
	for i in stacks:
		var ic := UiIcon.new()
		ic.icon = icon
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.size = Vector2(70, 70)
		ic.position = Vector2(40 + (i % 3) * 18 - (i / 3) * 9, 60 - i * 10)
		holder.add_child(ic)
	return holder


# ------------------------------------------------------------------ efeitos (moedas do jogo)
func _build_effects() -> void:
	var pack := "effects_all"
	if not Store.fully_owned(pack):
		_content.add_child(_product_card(pack))
	_content.add_child(UiKit.label("Escolha quem vai usar o efeito:", 22, Palette.WHITE, 8, Palette.OUTLINE))
	var scroll := ScrollContainer.new()
	DragScroll.attach(scroll)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 96
	_content.add_child(scroll)
	var who := UiKit.hbox(8)
	scroll.add_child(who)
	var friends: Array = Game.data["met"].duplicate()
	for pet in Store.companions():
		friends.append(pet)
	if friends.is_empty():
		friends = ["capi"]
	if not friends.has(_fx_target):
		_fx_target = str(friends[0])
	for sp in friends:
		var nm: String = Store.PETS[sp]["name"] if Store.PETS.has(sp) else Animal.SPECIES[sp]["name"]
		var b := UiKit.button(nm, Palette.UI_GOOD if sp == _fx_target else Palette.UI_MUTED, "", 0, 70)
		b.add_theme_font_size_override("font_size", UiKit.fs(20))
		var s: String = sp
		b.pressed.connect(func():
			_fx_target = s
			_refresh())
		who.add_child(b)
	for fx in Game.EFFECTS:
		_content.add_child(_effect_card(str(fx)))


func _effect_card(fx: String) -> Control:
	var cfg: Dictionary = Game.EFFECTS[fx]
	var panel := UiKit.panel()
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	panel.add_child(row)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(130, 120)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := AnimalArt.new()
	art.species = _fx_target
	art.preview = true
	art.effect = fx
	art.scale = Vector2.ONE * EditorScreen.fit_scale(_fx_target, 0.95) if Animal.SPECIES.has(_fx_target) else Vector2(0.9, 0.9)
	art.position = Vector2(65, 75)
	holder.add_child(art)
	row.add_child(holder)
	var n := UiKit.label(cfg["name"], 24)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(n)
	var b: Button
	if Game.owns_effect(fx):
		var on := str(Game.data["fx_equipped"].get(_fx_target, "")) == fx
		b = UiKit.button("Tirar" if on else "Usar", Palette.UI_SECONDARY if on else Palette.UI_GOOD, "", 150, 68)
		b.pressed.connect(func():
			Game.equip_effect(_fx_target, fx)
			Sfx.play("pop")
			_refresh())
	else:
		var price: int = cfg["price"]
		b = UiKit.button(str(price), Palette.GOLD, "coin", 150, 68)
		b.pressed.connect(func():
			ProductPreview.open(self, "effect", fx, func():
				if Game.buy_effect(fx):
					Sfx.play("coin")
					Game.equip_effect(_fx_target, fx)
					_status.text = tr("%s liberado!") % tr(str(cfg["name"]))
				_refresh(), _fx_target))
	row.add_child(b)
	return panel


# ------------------------------------------------------------------ compra com responsável
func _ask(id: String) -> void:
	if _modal != null or not Store.can_buy() or not Store.PRODUCTS.has(id):
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
	panel.custom_minimum_size = Vector2(minf(size.x - 40.0, 580.0), 0)
	center.add_child(panel)
	var box := UiKit.vbox(16)
	panel.add_child(box)
	box.add_child(UiKit.label("Área dos responsáveis", 32))
	var a := randi_range(12, 29)
	var b := randi_range(12, 29)
	_answer = a + b
	var how := tr("Simulação sem cobrança.") if Store.test_mode() else tr("A cobrança é feita pelo Google Play.")
	var notice := UiKit.label(tr("Peça a um responsável para continuar.\n%s · %s\n%s Quanto é %d + %d?") % [tr(Store.PRODUCTS[id]["name"]), Store.price_of(id), how, a, b], 24, Palette.UI_TEXT, 0, Palette.WHITE, true)
	notice.custom_minimum_size = Vector2(minf(size.x - 120.0, 500.0), 0)
	box.add_child(notice)
	_entry = LineEdit.new()
	_entry.placeholder_text = tr("Resposta")
	_entry.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_entry.custom_minimum_size.y = 64
	box.add_child(_entry)
	var row := UiKit.hbox(10)
	box.add_child(row)
	var cancel := UiKit.button("Cancelar", Palette.UI_SECONDARY, "", 0, 70)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_cancel)
	row.add_child(cancel)
	var pay := UiKit.button("Pagar (simulação)" if Store.test_mode() else "Continuar", Palette.UI_GOOD, "", 0, 70)
	pay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pay.pressed.connect(_pay)
	row.add_child(pay)
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
		_entry.placeholder_text = tr("Peça ajuda a um responsável e tente novamente")
		return
	var product := _pending
	_cancel()
	var result := Store.buy(product)
	_status.text = tr(str(result["message"]))
	if not result.get("pending", false):
		_refresh()


func _on_purchase_finished(_product: String, ok: bool, message: String) -> void:
	_status.text = tr(message)
	if ok:
		Sfx.play("coin")
	_refresh()
