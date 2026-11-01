class_name LegalScreen
extends Control
## Termos de Uso, Política de Privacidade, Seus direitos (LGPD) e guia para responsáveis.
## Abas no topo; texto rolável por arraste; o quadro "Guardado neste aparelho" é ao vivo.
signal go(screen: String, arg: Variant)

const INK := Color("635d70")
const MUTED := Color("847e8d")
const TABS := {"terms": "Termos", "privacy": "Privacidade", "rights": "Seus direitos", "parents": "Responsáveis"}
const TINTS := {"terms": Color("f6e3d6"), "privacy": Color("dde9ef"), "rights": Color("ddece6"), "parents": Color("e8e0ef")}

## Documento aberto e tela para onde o "voltar" leva.
var doc_id := "terms"
var back_to := "settings"

var _header: Control
var _back: HomeObject
var _title: Label
var _tabs: GridContainer
var _tab_buttons: Dictionary = {}
var _scroll: ScrollContainer
var _content: VBoxContainer
var _small := false


func setup(arg: Variant) -> void:
	if arg is String and Legal.ORDER.has(arg):
		doc_id = arg
	elif arg is Dictionary:
		if Legal.ORDER.has(str(arg.get("doc", ""))):
			doc_id = str(arg["doc"])
		back_to = str(arg.get("back", back_to))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(SettingsScreen.Backdrop.new())
	_small = size.x < 500 if size.x > 0 else false
	_header = Control.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)
	_back = HomeObject.new()
	_back.kind = "back"
	_back.dock = true
	_back.tooltip_text = tr("Voltar")
	_back.pressed.connect(on_back_pressed)
	_header.add_child(_back)
	_title = _label("Termos e privacidade", 38, INK)
	_header.add_child(_title)
	_tabs = GridContainer.new()
	_tabs.columns = 4
	_tabs.add_theme_constant_override("h_separation", 8)
	_tabs.add_theme_constant_override("v_separation", 8)
	add_child(_tabs)
	for id in Legal.ORDER:
		var b := _chip(TABS[id], id)
		_tabs.add_child(b)
		_tab_buttons[id] = b
	_scroll = ScrollContainer.new()
	DragScroll.attach(_scroll)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	resized.connect(_layout)
	show_doc(doc_id)


func _label(value: String, font_size: int, color: Color = INK, wrap: bool = false) -> Label:
	var l := UiKit.label(value, font_size, color, 0, Color.WHITE, wrap)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _style(color: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0, margin: int = 0) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = color
	st.set_corner_radius_all(radius)
	st.border_color = border
	st.set_border_width_all(width)
	st.content_margin_left = margin
	st.content_margin_right = margin
	st.content_margin_top = margin * 0.6
	st.content_margin_bottom = margin * 0.6
	return st


func _chip(text: String, id: String) -> Button:
	var b := Button.new()
	b.text = tr(text)
	b.toggle_mode = true
	b.custom_minimum_size.y = 56
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	b.add_theme_font_override("font", UiKit.font())
	b.add_theme_font_size_override("font_size", UiKit.fs(21))
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, INK)
	b.add_theme_stylebox_override("normal", _style(Color("fffdf9"), 18, Color("e2dbd8"), 1, 18))
	b.add_theme_stylebox_override("hover", _style(Color("f6f1ec"), 18, Color("c0b6c9"), 1, 18))
	b.add_theme_stylebox_override("pressed", _style(TINTS[id], 18, Color("a99bb6"), 2, 18))
	b.add_theme_stylebox_override("hover_pressed", _style(TINTS[id], 18, Color("a99bb6"), 2, 18))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, 18, Color("9e8eaf"), 2))
	b.pressed.connect(func(): show_doc(id))
	return b


## Troca o documento mostrado.
func show_doc(id: String) -> void:
	doc_id = id
	for key in _tab_buttons:
		(_tab_buttons[key] as Button).set_pressed_no_signal(key == id)
	if _content != null:
		_scroll.remove_child(_content)
		_content.queue_free()
	_content = UiKit.vbox(16)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)
	var d := Legal.doc(id)
	var heading := _label(Legal.text(d.get("title", {})), 32, INK, true)
	_content.add_child(heading)
	# resumo em destaque
	var sum_panel := PanelContainer.new()
	sum_panel.add_theme_stylebox_override("panel", _style(TINTS.get(id, Color("eeeeee")), 22, Color.TRANSPARENT, 0, 22))
	sum_panel.add_child(_label(Legal.text(d.get("summary", {})), 23, INK, true))
	_content.add_child(sum_panel)
	if bool(d.get("live", false)):
		_content.add_child(_stored_box())
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color("fffdf9"), 25, Color("e7e1df"), 1, 18 if _small else 24))
	_content.add_child(card)
	var rows := UiKit.vbox(10)
	card.add_child(rows)
	for s in d.get("sections", []):
		var h := _label(Legal.text(s.get("h", {})), 25, INK, true)
		h.add_theme_constant_override("line_spacing", 2)
		rows.add_child(h)
		for p in s.get("p", []):
			var body := _label(Legal.text(p), 21, Color("5c5669"), true)
			body.add_theme_constant_override("line_spacing", 3)
			rows.add_child(body)
		var gap := Control.new()
		gap.custom_minimum_size.y = 6
		rows.add_child(gap)
	if id == "rights" or id == "privacy":
		var erase := _button("Ir para Apagar progresso")
		erase.pressed.connect(func(): go.emit("settings", "reset"))
		_content.add_child(erase)
	var foot := _label("%s\n%s · %s · %s" % [Legal.updated_line(), Legal.by_line(), str(Legal.data().get("site", "")), Legal.email()], 18, MUTED, true)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(foot)
	var pad := Control.new()
	pad.custom_minimum_size.y = 20
	_content.add_child(pad)
	_scroll.set_deferred("scroll_vertical", 0)
	_layout()


func _stored_box() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("fffdf9"), 22, Color("c9ddd4"), 2, 22))
	var col := UiKit.vbox(6)
	panel.add_child(col)
	col.add_child(_label("Guardado neste aparelho agora", 24, Color("4f7d70"), true))
	for item in Legal.stored_summary():
		var row := UiKit.hbox(10)
		col.add_child(row)
		var k := _label(item[0], 21, INK, true)
		row.add_child(k)
		var v := _label(item[1], 21, Color("4f7d70"))
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(v)
	col.add_child(_label("Nada disso é enviado para servidores.", 19, MUTED, true))
	return panel


func _button(title: String) -> Button:
	var b := Button.new()
	b.text = tr(title)
	b.custom_minimum_size.y = 60
	b.add_theme_font_override("font", UiKit.font())
	b.add_theme_font_size_override("font_size", UiKit.fs(22))
	for st in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(st, Color("a46a66"))
	b.add_theme_stylebox_override("normal", _style(Color("fff5f0"), 16, Color("d5b7b1"), 1, 12))
	b.add_theme_stylebox_override("hover", _style(Color("fbede7"), 16, Color("a46a66"), 1, 12))
	b.add_theme_stylebox_override("pressed", _style(Color("f5e4dd"), 16, Color("a46a66"), 1, 12))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, 16, Color("9e8eaf"), 2))
	return b


func _layout() -> void:
	if size.x <= 0 or _header == null:
		return
	var ins := UiKit.safe_insets(self)
	var area := Rect2(Vector2(ins.x + 18, ins.y + 14), size - Vector2(ins.x + ins.z + 36, ins.y + ins.w + 14 + UiKit.GESTURE_GAP))
	var width := minf(area.size.x, 860)
	var left := area.get_center().x - width / 2
	_header.position = Vector2(left, area.position.y)
	_header.size = Vector2(width, 80)
	_back.position = Vector2(0, 8)
	_back.size = Vector2(60, 60)
	_title.position = Vector2(78, 10)
	_title.size = Vector2(width - 80, 56)
	_tabs.columns = 4 if width >= 760 else 2
	_tabs.position = Vector2(left, area.position.y + 84)
	_tabs.size = Vector2(width, _tabs.get_combined_minimum_size().y)
	var top := _tabs.position.y + _tabs.size.y + 14
	_scroll.position = Vector2(left, top)
	_scroll.size = Vector2(width, maxf(100, area.end.y - top))


func on_back_pressed() -> void:
	go.emit(back_to, null)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		on_back_pressed()
		get_viewport().set_input_as_handled()
