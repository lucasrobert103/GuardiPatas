class_name ProductPreview
extends Control
## Janela de PRÉVIA antes de qualquer compra (moedas do jogo ou dinheiro de verdade):
## mostra o produto grande e animado — o bichinho com o efeito dele, o acessório ou o efeito
## num bichinho à escolha (setas para trocar), o pacote com tudo o que vem — e só então
## o botão de comprar.
##   ProductPreview.open(parent, "product" | "item" | "effect", id, on_confirm)

signal confirmed
signal closed

var kind := "product"
var id := ""
## Bichinho que aparece primeiro vestindo o acessório/efeito.
var wearer_species := ""
var _stage: Control
var _arts: Array[AnimalArt] = []
var _wearers: Array = []
var _wearer := 0
var _t := 0.0
var _confirm: Button


static func open(parent: Control, p_kind: String, p_id: String, on_confirm: Callable, wearer: String = "") -> ProductPreview:
	var p := ProductPreview.new()
	p.kind = p_kind
	p.id = p_id
	p.wearer_species = wearer
	p.confirmed.connect(on_confirm)
	parent.add_child(p)
	return p


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := UiKit.dim(0.6)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	var st := UiKit.panel_style(Palette.CREAM)
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 16
	st.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size.x = minf(get_viewport_rect().size.x - 36.0, 640.0)
	center.add_child(panel)
	var col := UiKit.vbox(12)
	panel.add_child(col)
	var head := UiKit.hbox(8)
	col.add_child(head)
	var title := UiKit.label(_name(), 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(title)
	var x := UiKit.icon_button("close", Palette.UI_SECONDARY, 64)
	x.pressed.connect(close)
	head.add_child(x)
	# palco animado
	_stage = Stage.new()
	_stage.custom_minimum_size = Vector2(0, 300)
	(_stage as Stage).owner_preview = self
	col.add_child(_stage)
	_build_stage()
	if kind != "product":
		var pick := UiKit.hbox(10)
		col.add_child(pick)
		var prev := UiKit.icon_button("back", Palette.UI_SECONDARY, 60)
		prev.pressed.connect(func(): _cycle(-1))
		pick.add_child(prev)
		pick.add_child(UiKit.label("Ver em outro bichinho", 20))
		var nxt := UiKit.icon_button("next", Palette.UI_SECONDARY, 60)
		nxt.pressed.connect(func(): _cycle(1))
		pick.add_child(nxt)
	var desc := UiKit.label(_description(), 21, Palette.UI_TEXT, 0, Palette.WHITE, true)
	desc.custom_minimum_size = Vector2(minf(get_viewport_rect().size.x - 100.0, 580.0), 0)
	col.add_child(desc)
	var items := _contents()
	if not items.is_empty():
		var inc := UiKit.label(tr("O que vem: %s") % ", ".join(items), 20, Palette.UI_PRIMARY.darkened(0.3), 0, Palette.WHITE, true)
		inc.custom_minimum_size = desc.custom_minimum_size
		col.add_child(inc)
	var row := UiKit.hbox(10)
	col.add_child(row)
	var back := UiKit.button("Voltar", Palette.UI_SECONDARY, "", 0, 76)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(close)
	row.add_child(back)
	_confirm = UiKit.button(_buy_text(), Palette.UI_GOOD, "coin", 0, 76)
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm.clip_text = true
	_confirm.add_theme_font_size_override("font_size", UiKit.fs(22))
	_confirm.disabled = not _affordable()
	_confirm.pressed.connect(func():
		confirmed.emit()
		close())
	row.add_child(_confirm)
	if not _affordable() and kind != "product":
		col.add_child(UiKit.label(tr("Faltam %d moedas. Vença fases para juntar mais!") % (_price() - Game.coins()), 20, Palette.DANGER))
	modulate.a = 0.0
	panel.pivot_offset = Vector2(panel.custom_minimum_size.x * 0.5, 300)
	panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("pop", -4.0, 1.2)


func close() -> void:
	closed.emit()
	queue_free()


# ------------------------------------------------------------------ textos e preço
func _name() -> String:
	match kind:
		"item": return tr(str(Game.ITEMS[id]["name"]))
		"effect": return tr(str(Game.EFFECTS[id]["name"]))
	return tr(str(Store.PRODUCTS[id]["name"]))


func _description() -> String:
	match kind:
		"item": return tr("Acessório para vestir em qualquer bichinho. É só enfeite: não muda o jogo.")
		"effect": return tr("Efeito especial em volta do bichinho, nas fases e na Casinha. É só enfeite: não muda o jogo.")
	return tr(str(Store.PRODUCTS[id]["description"]))


func _price() -> int:
	match kind:
		"item": return int(Game.ITEMS[id]["price"])
		"effect": return int(Game.EFFECTS[id]["price"])
	return 0


func _affordable() -> bool:
	return kind == "product" or Game.coins() >= _price()


func _buy_text() -> String:
	if kind == "product":
		return ("Testar · " if Store.test_mode() else "Comprar · ") + Store.price_of(id)
	return tr("Comprar · %d") % _price()


## Lista do que o pacote entrega.
func _contents() -> Array:
	if kind != "product":
		return []
	var cfg: Dictionary = Store.PRODUCTS[id]
	var out: Array = []
	if cfg.has("coins"):
		out.append(tr("%d moedas") % int(cfg["coins"]))
	if cfg.has("hints"):
		out.append(tr("%d dicas") % int(cfg["hints"]))
	for pet in cfg.get("pets", []):
		out.append(str(Store.PETS[pet]["name"]))
	if cfg.has("effects"):
		out.append(tr("%d efeitos especiais") % (cfg["effects"] as Array).size())
	for it in cfg.get("items", []):
		out.append(tr(str(Game.ITEMS[it]["name"])))
	if cfg.get("vip", false):
		out.append(tr("dobro de moedas para sempre"))
	return out


# ------------------------------------------------------------------ palco
func _build_stage() -> void:
	for a in _arts:
		a.queue_free()
	_arts.clear()
	if kind != "product":
		_wearers = Game.data["met"].duplicate()
		for pet in Store.companions():
			_wearers.append(pet)
		if _wearers.is_empty():
			_wearers = ["capi", "brasa", "pompom"]
		if wearer_species != "" and _wearers.has(wearer_species):
			_wearer = _wearers.find(wearer_species)
			wearer_species = ""
		_wearer = clampi(_wearer, 0, _wearers.size() - 1)
		var art := _make(str(_wearers[_wearer]), 2.0)
		if kind == "item":
			art.accessory = id
		else:
			art.effect = id
		return
	var cfg: Dictionary = Store.PRODUCTS[id]
	var pets: Array = cfg.get("pets", [])
	if not pets.is_empty():
		var shown := pets.slice(0, 4)
		for i in shown.size():
			_make(str(shown[i]), 2.0 if shown.size() == 1 else (1.4 if shown.size() == 2 else 1.05))
		return
	if cfg.has("effects"):
		for i in 3:
			var art := _make(["capi", "pompom", "zeca"][i], 1.2)
			art.effect = str(cfg["effects"][[7, 3, 5][i] % (cfg["effects"] as Array).size()])
	elif cfg.has("items"):
		var a1 := _make("capi", 1.5)
		a1.accessory = str(cfg["items"][0])
		if (cfg["items"] as Array).size() > 1:
			var a2 := _make("brasa", 1.5)
			a2.accessory = str(cfg["items"][1])


func _make(sp: String, sc: float) -> AnimalArt:
	var art := AnimalArt.new()
	art.species = sp
	art.preview = true
	if Animal.SPECIES.has(sp):
		sc *= EditorScreen.fit_scale(sp, 1.0)
	art.scale = Vector2(sc, sc)
	_stage.add_child(art)
	_arts.append(art)
	return art


func _cycle(dir: int) -> void:
	if _wearers.is_empty():
		return
	_wearer = (_wearer + dir + _wearers.size()) % _wearers.size()
	_build_stage()
	Sfx.play("pop", -6.0, 1.3)


func _process(delta: float) -> void:
	_t += delta
	if _stage == null:
		return
	var w := _stage.size.x
	var ground := _stage.size.y - 40.0
	for i in _arts.size():
		var a := _arts[i]
		if not is_instance_valid(a):
			continue
		var x := w * (0.5 + (i - (_arts.size() - 1) * 0.5) * (0.8 / maxf(_arts.size(), 1.0)))
		var bob := absf(sin(_t * 2.2 + i)) * 6.0
		a.position = Vector2(x, ground - Animal.half_height(a.species) * a.scale.y - bob) if Animal.SPECIES.has(a.species) else Vector2(x, ground - 37.0 * a.scale.y - bob)
		# alterna carinha feliz e normal para mostrar o bichinho "vivo"
		a.mood = "happy" if fmod(_t + i * 0.7, 4.0) > 3.0 else "idle"


## Fundo do palco: céu, chão e, nos pacotes de moedas/dicas, a pilha pulando.
class Stage:
	extends Control
	var owner_preview: ProductPreview
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		DrawUtil.vgradient(self, r, Color("8fd3ff"), Color("e3f6ff"))
		for i in 6:
			var a := _t * 0.4 + TAU * i / 6.0
			draw_line(size * Vector2(0.5, 0.45), size * Vector2(0.5, 0.45) + Vector2.from_angle(a) * size.x, Color(1, 1, 1, 0.18), 26.0, true)
		draw_rect(Rect2(0, size.y - 40, size.x, 40), Color("8fcf84"), true)
		draw_line(Vector2(0, size.y - 40), Vector2(size.x, size.y - 40), Palette.OUTLINE, 4.0, true)
		if owner_preview == null or owner_preview.kind != "product":
			_frame()
			return
		var cfg: Dictionary = Store.PRODUCTS[owner_preview.id]
		if cfg.has("pets") or cfg.has("effects") or cfg.has("items"):
			_frame()
			return
		# moedas, dicas ou Pata Dourada: pilha animada
		var c := Vector2(size.x * 0.5, size.y - 80.0)
		if cfg.get("vip", false):
			var s := 1.0 + 0.06 * sin(_t * 4.0)
			draw_circle(c + Vector2(0, -60), 90.0 * s, Color(1, 0.85, 0.3, 0.25), true, -1.0, true)
			DrawUtil.shape(self, DrawUtil.star_points(c + Vector2(0, -60), 70.0 * s, 32.0 * s), Palette.GOLD, Palette.OUTLINE, 4.0)
			draw_string(ThemeDB.fallback_font, c + Vector2(-30, -48), "x2", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Palette.OUTLINE)
		elif cfg.has("coins"):
			var n := clampi(int(cfg["coins"]) / 300 + 3, 3, 26)
			for i in n:
				var col := i % 6
				var row := i / 6
				var hop := absf(sin(_t * 3.0 + i * 0.6)) * 6.0
				var p := c + Vector2((col - 2.5) * 46.0 + (row % 2) * 20.0, -row * 30.0 - hop)
				DrawUtil.disc(self, p, 22.0, Palette.GOLD, Palette.OUTLINE, 3.0)
				draw_rect(Rect2(p + Vector2(-3, -10), Vector2(6, 20)), Palette.GOLD_DARK, true)
		elif cfg.has("hints"):
			var s2 := 1.0 + 0.05 * sin(_t * 5.0)
			draw_circle(c + Vector2(0, -70), 80.0 * s2, Color(1, 0.95, 0.5, 0.3), true, -1.0, true)
			DrawUtil.disc(self, c + Vector2(0, -80), 48.0 * s2, Palette.GOLD, Palette.OUTLINE, 4.0)
			draw_rect(Rect2(c + Vector2(-22, -36), Vector2(44, 30)), Palette.OUTLINE, true)
		_frame()

	func _frame() -> void:
		var b := StyleBoxFlat.new()
		b.draw_center = false
		b.set_corner_radius_all(22)
		b.set_border_width_all(4)
		b.border_color = Palette.OUTLINE
		draw_style_box(b, Rect2(Vector2.ZERO, size))
