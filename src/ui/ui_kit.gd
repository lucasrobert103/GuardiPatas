class_name UiKit
## Fábrica de componentes de interface no estilo do jogo: botões gordinhos, painéis
## arredondados e textos com contorno — legíveis em telas pequenas.

const BUTTON_H := 96
const FONT_SIZE := 30

static var _font: FontVariation


static func font() -> Font:
	if _font == null:
		_font = FontVariation.new()
		_font.base_font = ThemeDB.fallback_font
		_font.variation_embolden = 0.65
	return _font


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = FONT_SIZE
	t.set_color("font_color", "Label", Palette.UI_TEXT)
	t.set_color("font_color", "Button", Palette.UI_TEXT)
	t.set_color("font_hover_color", "Button", Palette.UI_TEXT)
	t.set_color("font_pressed_color", "Button", Palette.UI_TEXT)
	t.set_color("font_focus_color", "Button", Palette.UI_TEXT)
	t.set_stylebox("panel", "PanelContainer", panel_style(Palette.UI_PANEL))
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Palette.UI_SECONDARY
	grabber.set_corner_radius_all(12)
	var slider := StyleBoxFlat.new()
	slider.bg_color = Palette.UI_MUTED
	slider.set_corner_radius_all(12)
	slider.content_margin_top = 10
	slider.content_margin_bottom = 10
	t.set_stylebox("slider", "HSlider", slider)
	t.set_stylebox("grabber_area", "HSlider", grabber)
	t.set_stylebox("grabber_area_highlight", "HSlider", grabber)
	return t


static func panel_style(color: Color, radius: int = 36) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(5)
	s.border_color = Palette.OUTLINE
	s.shadow_color = Color(0, 0, 0, 0.18)
	s.shadow_size = 0
	s.shadow_offset = Vector2(0, 8)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 24
	s.content_margin_bottom = 24
	return s


static func btn_style(color: Color, pressed: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color.darkened(0.12) if pressed else color
	s.set_corner_radius_all(30)
	s.set_border_width_all(5)
	s.border_color = Palette.OUTLINE
	s.border_width_bottom = 5 if pressed else 11
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 10 if not pressed else 16
	s.content_margin_bottom = 10
	return s


## Botão com texto (e ícone opcional desenhado em vetor).
static func button(text: String, color: Color = Palette.UI_PRIMARY, icon: String = "", min_w: int = 0, height: int = BUTTON_H) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, height)
	b.add_theme_stylebox_override("normal", btn_style(color, false))
	b.add_theme_stylebox_override("hover", btn_style(color.lightened(0.06), false))
	b.add_theme_stylebox_override("pressed", btn_style(color, true))
	b.add_theme_stylebox_override("disabled", btn_style(Palette.UI_MUTED, false))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	b.add_theme_color_override("font_color", Palette.OUTLINE)
	b.add_theme_color_override("font_hover_color", Palette.OUTLINE)
	b.add_theme_color_override("font_pressed_color", Palette.OUTLINE)
	b.add_theme_color_override("font_disabled_color", Color(Palette.OUTLINE, 0.5))
	if icon != "":
		# o ícone ocupa um retângulo ancorado no botão (centro ou lado esquerdo) e
		# se desenha centralizado nele; a borda inferior grossa do botão é compensada
		var ic := UiIcon.new()
		ic.icon = icon
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pad := height * 0.24
		ic.anchor_top = 0.0
		ic.anchor_bottom = 1.0
		ic.offset_top = pad
		ic.offset_bottom = -pad - 4.0
		if text == "":
			ic.anchor_left = 0.0
			ic.anchor_right = 1.0
			ic.offset_left = pad
			ic.offset_right = -pad
			b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, height)
		else:
			ic.anchor_left = 0.0
			ic.anchor_right = 0.0
			ic.offset_left = 16.0
			ic.offset_right = 16.0 + height * 0.52
			b.add_theme_constant_override("h_separation", 0)
			b.text = "     " + text
		b.add_child(ic)
	b.pressed.connect(func(): Sfx.play("ui_click", -2.0, 1.0, 0.05))
	return b


static func icon_button(icon: String, color: Color = Palette.UI_PANEL, size: int = 84) -> Button:
	return button("", color, icon, size, size)


## `wrap = true` para textos longos (quebra em palavras dentro da largura do contêiner).
static func label(text: String, size: int = FONT_SIZE, color: Color = Palette.UI_TEXT, outline: int = 0, outline_color: Color = Palette.WHITE, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font = font()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = outline
	ls.outline_color = outline_color
	l.label_settings = ls
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	return l


static func title(text: String, size: int = 64) -> Label:
	return label(text, size, Palette.WHITE, 18, Palette.OUTLINE)


static func panel(color: Color = Palette.UI_PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(color))
	return p


static func vbox(sep: int = 18) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	return v


static func hbox(sep: int = 18) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	return h


## Fundo escurecido que bloqueia toques atrás de um diálogo.
static func dim(alpha: float = 0.45) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.15, 0.1, 0.2, alpha)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	return c


## Animação de "pulo" ao aparecer.
static func pop_in(c: Control, delay: float = 0.0) -> void:
	c.scale = Vector2(0.6, 0.6)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): c.pivot_offset = c.size * 0.5)
	tw.tween_property(c, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(c, "modulate:a", 1.0, 0.2)
