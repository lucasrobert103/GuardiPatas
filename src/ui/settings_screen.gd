class_name SettingsScreen
extends Control
## Preferências em cartões leves, com controles nativos e confirmação de exclusão.
signal go(screen: String, arg: Variant)
const INK := Color("635d70")
const MUTED := Color("847e8d")
const MINT := Color("90bdb0")
const COLOR_OPTIONS := ["Nenhum", "Protanopia (vermelho)", "Deuteranopia (verde)", "Tritanopia (azul)"]
var _confirm: Control
var _confirm_panel: PanelContainer
var _confirm_cancel: Button
var _confirm_yes: Button
var _scroll: ScrollContainer
var _content: VBoxContainer
var _header: Control
var _title: Label
var _subtitle: Label
var _back: HomeObject
var _mascot: AnimalArt
var _controls: Dictionary = {}
var _rows: Dictionary = {}
var _safe := Rect2()
var _small := false
var _rebuilding := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Backdrop.new())
	resized.connect(_on_resize)
	_build()


func _font_size(value: int) -> int:
	return int(round(value * (0.84 if _small else 1.0)))


func _label(value: String, font_size: int, color: Color = INK, wrap: bool = false) -> Label:
	var label := UiKit.label(tr(value), _font_size(font_size), color, 0, Color.WHITE, wrap)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _style(color: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0, margin: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


func _build(scroll_position: int = 0) -> void:
	_small = size.x < 500
	_controls.clear()
	_rows.clear()
	if _header != null:
		remove_child(_header)
		_header.queue_free()
	if _scroll != null:
		remove_child(_scroll)
		_scroll.queue_free()
	_header = Control.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)
	_back = HomeObject.new()
	_back.kind = "back"
	_back.tooltip_text = tr("Voltar")
	_back.dock = true
	_back.pressed.connect(on_back_pressed)
	_header.add_child(_back)
	_title = _label("Ajustes", 38 if _small else 44)
	_header.add_child(_title)
	_subtitle = _label("Do seu jeito", 22, MUTED)
	_header.add_child(_subtitle)
	_mascot = AnimalArt.new()
	_mascot.species = "capi"
	_mascot.preview = true
	_mascot.mood = "happy"
	_mascot.set_process(false)
	_header.add_child(_mascot)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.add_theme_constant_override("scrollbar_h_separation", 10)
	add_child(_scroll)
	_content = UiKit.vbox(22)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)
	var sound := _section("Som e toque", "music", Color("ddece6"))
	_slider(sound, "Música", "music")
	_separator(sound)
	_slider(sound, "Efeitos sonoros", "sfx")
	_separator(sound)
	_toggle(sound, "Vibração", "vibration")
	var access := _section("Acessibilidade", "vision", Color("e8e0ef"))
	_toggle(access, "Reduzir movimento", "reduce_motion")
	_separator(access)
	_toggle(access, "Destacar insetos (alto contraste)", "high_contrast")
	_separator(access)
	_toggle(access, "Texto grande", "big_text")
	_separator(access)
	_picker(access, "Daltonismo", "colorblind", COLOR_OPTIONS, int(Game.setting("colorblind")))
	var language := _section("Idioma", "globe", Color("f5e6d2"))
	_picker(language, "Idioma", "lang", Game.LANGS.map(func(item): return item[1]), _lang_index(), false)
	var privacy := _section("Seus dados", "shield", Color("dde9ef"))
	var note := _label("Privacidade: o GuardiPatas não coleta dados pessoais. Seu progresso fica salvo só neste aparelho.", 22, MUTED, true)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	privacy.add_child(note)
	var reset := _button("Apagar progresso", false)
	reset.tooltip_text = tr("Apagar progresso")
	reset.pressed.connect(_ask_reset)
	reset.focus_entered.connect(func(): _scroll.ensure_control_visible(reset))
	privacy.add_child(reset)
	_controls["reset"] = reset
	var footer := _label("Desenvolvido por RetroNexa · retronexa.com.br", 18, MUTED, true)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(footer)
	var version := _label(tr("Versão %s") % ProjectSettings.get_setting("application/config/version", "dev"), 17, MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(version)
	_layout()
	_scroll.set_deferred("scroll_vertical", scroll_position)
	_rebuilding = false


func _section(title: String, icon: String, tint: Color) -> VBoxContainer:
	var section := UiKit.vbox(10)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(section)
	var heading := UiKit.hbox(12)
	section.add_child(heading)
	var badge := Badge.new()
	badge.icon = icon
	badge.tint = tint
	badge.custom_minimum_size = Vector2(38, 38)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(badge)
	var label := _label(title, 25)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(label)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color("fffdf9"), 25, Color("e7e1df"), 1, 18 if _small else 24))
	section.add_child(panel)
	var rows := UiKit.vbox(12)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(rows)
	return rows


func _separator(parent: VBoxContainer) -> void:
	var line := HSeparator.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxLine.new()
	style.color = Color("efebe7")
	style.thickness = 1
	line.add_theme_stylebox_override("separator", style)
	parent.add_child(line)


func _slider(parent: VBoxContainer, title: String, key: String) -> void:
	var column := UiKit.vbox(4)
	parent.add_child(column)
	var row := UiKit.hbox(12)
	column.add_child(row)
	var label := _label(title, 25)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var percent := _label("", 23, MUTED)
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.custom_minimum_size.x = 62
	row.add_child(percent)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = float(Game.setting(key))
	slider.custom_minimum_size = Vector2(0, 42)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slider.add_theme_stylebox_override("slider", _style(Color("e7e7df"), 5, Color.TRANSPARENT, 0, 4))
	slider.add_theme_stylebox_override("grabber_area", _style(MINT, 5, Color.TRANSPARENT, 0, 4))
	slider.add_theme_stylebox_override("grabber_area_highlight", _style(Color("7daa9d"), 5, Color.TRANSPARENT, 0, 4))
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("fffdf9"), Color("fffdf9"), MINT, MINT, Color.TRANSPARENT])
	gradient.offsets = PackedFloat32Array([0, 0.65, 0.70, 0.92, 1])
	var knob := GradientTexture2D.new()
	knob.width = 30
	knob.height = 30
	knob.fill = GradientTexture2D.FILL_RADIAL
	knob.fill_from = Vector2(0.5, 0.5)
	knob.fill_to = Vector2(1, 0.5)
	knob.gradient = gradient
	for state in ["grabber", "grabber_highlight", "grabber_disabled"]: slider.add_theme_icon_override(state, knob)
	percent.text = "%d%%" % roundi(slider.value * 100)
	slider.tooltip_text = tr(title)
	slider.set_meta("settings_key", key)
	slider.value_changed.connect(func(value: float):
		percent.text = "%d%%" % roundi(value * 100)
		Game.set_setting(key, value)
		if key == "sfx": Sfx.play("ui_click"))
	slider.focus_entered.connect(func(): _scroll.ensure_control_visible(column))
	column.add_child(slider)
	_controls[key] = slider
	_rows[key] = column


func _toggle(parent: VBoxContainer, title: String, key: String) -> void:
	var row := UiKit.hbox(18)
	row.custom_minimum_size.y = 60
	parent.add_child(row)
	var label := _label(title, 24, INK, true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var toggle := Switch.new()
	toggle.toggle_mode = true
	toggle.button_pressed = bool(Game.setting(key))
	toggle.custom_minimum_size = Vector2(72, 54)
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toggle.tooltip_text = tr(title)
	toggle.set_meta("settings_key", key)
	toggle.toggled.connect(func(on: bool):
		Game.set_setting(key, on)
		if key == "big_text": _queue_rebuild())
	toggle.focus_entered.connect(func(): _scroll.ensure_control_visible(row))
	row.add_child(toggle)
	_controls[key] = toggle
	_rows[key] = row


func _picker(parent: VBoxContainer, title: String, key: String, options: Array, selected: int, with_title: bool = true) -> void:
	var column := UiKit.vbox(8)
	parent.add_child(column)
	if with_title: column.add_child(_label(title, 24))
	var selector := OptionButton.new()
	selector.custom_minimum_size.y = 58
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.clip_text = true
	selector.fit_to_longest_item = false
	selector.add_theme_font_override("font", UiKit.font())
	selector.add_theme_font_size_override("font_size", UiKit.fs(_font_size(23)))
	selector.add_theme_color_override("font_color", INK)
	selector.add_theme_color_override("font_hover_color", INK)
	selector.add_theme_color_override("font_pressed_color", INK)
	selector.add_theme_stylebox_override("normal", _style(Color("f3f0eb"), 14, Color.TRANSPARENT, 0, 14))
	selector.add_theme_stylebox_override("hover", _style(Color("eeeae5"), 14, Color("c0b6c9"), 1, 14))
	selector.add_theme_stylebox_override("pressed", _style(Color("e9e4df"), 14, Color("c0b6c9"), 1, 14))
	selector.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, 14, Color("9e8eaf"), 2))
	var popup := selector.get_popup()
	popup.add_theme_stylebox_override("panel", _style(Color("fffdf9"), 16, Color("d8d0df"), 1, 12))
	popup.add_theme_stylebox_override("hover", _style(Color("ddece6"), 10))
	popup.add_theme_color_override("font_color", INK)
	popup.add_theme_color_override("font_hover_color", INK)
	popup.add_theme_font_override("font", UiKit.font())
	popup.add_theme_font_size_override("font_size", UiKit.fs(_font_size(23)))
	for option in options: selector.add_item(tr(option))
	selector.selected = selected
	selector.tooltip_text = tr(title)
	selector.set_meta("settings_key", key)
	selector.item_selected.connect(func(index: int):
		Game.set_setting(key, Game.LANGS[index][0] if key == "lang" else index)
		if key == "lang": _queue_rebuild())
	selector.focus_entered.connect(func(): _scroll.ensure_control_visible(column))
	column.add_child(selector)
	_controls[key] = selector
	_rows[key] = column


func _lang_index() -> int:
	for i in Game.LANGS.size():
		if Game.LANGS[i][0] == Game.lang_code(): return i
	return 0


func _button(title: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = tr(title)
	button.custom_minimum_size.y = 62
	button.add_theme_font_override("font", UiKit.font())
	button.add_theme_font_size_override("font_size", UiKit.fs(_font_size(23)))
	var color := Color("dcebe3") if primary else Color("fff5f0")
	var ink := Color("506d63") if primary else Color("a46a66")
	for state in ["font_color", "font_hover_color", "font_pressed_color"]: button.add_theme_color_override(state, ink)
	button.add_theme_stylebox_override("normal", _style(color, 16, Color("d5b7b1") if not primary else Color.TRANSPARENT, 1))
	button.add_theme_stylebox_override("hover", _style(color.darkened(0.03), 16, ink, 1))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.06), 16, ink, 1))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, 16, Color("9e8eaf"), 2))
	return button


func _queue_rebuild() -> void:
	if _rebuilding: return
	_rebuilding = true
	_build.call_deferred(_scroll.scroll_vertical)


func _on_resize() -> void:
	if _header == null: return
	if (size.x < 500) != _small:
		_queue_rebuild()
	else:
		_layout()


func _layout() -> void:
	_safe = Rect2(18, 14, maxf(100, size.x - 36), maxf(100, size.y - 28))
	if OS.has_feature("Android"):
		var area := DisplayServer.get_display_safe_area()
		var window_size := Vector2(get_window().size)
		if area.size.x > 0 and window_size.x > 0 and window_size.y > 0:
			var factor := size / window_size
			_safe = _safe.intersection(Rect2(Vector2(area.position) * factor, Vector2(area.size) * factor).grow(-8))
	var width := minf(_safe.size.x, 860)
	var left := _safe.get_center().x - width / 2
	var header_h := 112.0 if _small else 132.0
	_header.position = Vector2(left, _safe.position.y)
	_header.size = Vector2(width, header_h)
	_back.position = Vector2(0, 10)
	_back.size = Vector2(60, 60)
	_title.position = Vector2(78, 3)
	_title.size = Vector2(width - 164, 56)
	_subtitle.position = Vector2(80, 60)
	_subtitle.size = Vector2(width - 164, 30)
	_mascot.position = Vector2(width - 42, 65)
	_mascot.scale = Vector2.ONE * (0.57 if _small else 0.75)
	_scroll.position = Vector2(left, _safe.position.y + header_h)
	_scroll.size = Vector2(width, maxf(100, _safe.size.y - header_h))
	if _confirm_panel != null:
		_confirm_panel.custom_minimum_size.x = minf(_safe.size.x - 24, 540)
		_confirm_panel.size.x = _confirm_panel.custom_minimum_size.x


func on_back_pressed() -> void:
	if _confirm != null:
		_close_confirm()
	else:
		go.emit("title", null)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		on_back_pressed()
		get_viewport().set_input_as_handled()


func _close_confirm() -> void:
	if _confirm == null: return
	_confirm.queue_free()
	_confirm = null
	_confirm_panel = null
	_controls["reset"].grab_focus()


func _ask_reset() -> void:
	if _confirm != null: return
	_confirm = Control.new()
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_confirm)
	var dim := ColorRect.new()
	dim.color = Color("514b6180")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(center)
	_confirm_panel = PanelContainer.new()
	_confirm_panel.add_theme_stylebox_override("panel", _style(Color("fffaf3"), 30, Color("e5d9d6"), 1, 24))
	center.add_child(_confirm_panel)
	var column := UiKit.vbox(18)
	_confirm_panel.add_child(column)
	var icon := Badge.new()
	icon.icon = "shield"
	icon.tint = Color("f4e1d7")
	icon.custom_minimum_size = Vector2(50, 50)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var warning := _label("Apagar todo o progresso?\nEstrelas, moedas e acessórios serão perdidos.", 25, INK, true)
	warning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning.custom_minimum_size.y = 90
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(warning)
	_confirm_cancel = _button("Cancelar", true)
	_confirm_cancel.pressed.connect(_close_confirm)
	column.add_child(_confirm_cancel)
	_confirm_yes = _button("Apagar", false)
	_confirm_yes.pressed.connect(func():
		Game.reset_progress()
		_close_confirm()
		go.emit("title", null))
	column.add_child(_confirm_yes)
	_layout()
	_confirm_cancel.focus_next = _confirm_cancel.get_path_to(_confirm_yes)
	_confirm_cancel.focus_previous = _confirm_cancel.get_path_to(_confirm_yes)
	_confirm_cancel.focus_neighbor_bottom = _confirm_cancel.get_path_to(_confirm_yes)
	_confirm_cancel.focus_neighbor_top = _confirm_cancel.get_path_to(_confirm_yes)
	_confirm_yes.focus_next = _confirm_yes.get_path_to(_confirm_cancel)
	_confirm_yes.focus_previous = _confirm_yes.get_path_to(_confirm_cancel)
	_confirm_yes.focus_neighbor_bottom = _confirm_yes.get_path_to(_confirm_cancel)
	_confirm_yes.focus_neighbor_top = _confirm_yes.get_path_to(_confirm_cancel)
	_confirm_cancel.grab_focus()


class Switch:
	extends Button
	func _ready() -> void:
		toggle_mode = true
		text = ""
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "disabled", "focus"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
		toggled.connect(func(_on): queue_redraw())
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
	func _draw() -> void:
		var center := size / 2
		var rect := Rect2(center - Vector2(34, 20), Vector2(68, 40))
		HomeArt.box(self, rect, MINT if button_pressed else Color("d7d5dc"), 20)
		if has_focus() or is_hovered(): HomeArt.box(self, rect.grow(3), Color.TRANSPARENT, 23, Color("9e8eaf"), 2)
		var point := center + Vector2(14 if button_pressed else -14, 0)
		draw_circle(point + Vector2(0, 2), 16, Color("70657918"), true, -1, true)
		draw_circle(point, 16, Color("fffdf9"), true, -1, true)
		if button_pressed:
			draw_polyline(PackedVector2Array([point + Vector2(-6, 0), point + Vector2(-1, 5), point + Vector2(7, -5)]), Color("6b9a8c"), 2, true)
		else: draw_line(point + Vector2(-5, 0), point + Vector2(5, 0), Color("aaa2b2"), 2, true)


class Badge:
	extends Control
	var icon := "music"
	var tint := Color("ddece6")
	func _draw() -> void:
		HomeArt.box(self, Rect2(Vector2.ZERO, size), tint, 12)
		var center := size / 2
		var ink := INK
		match icon:
			"music":
				draw_polyline(PackedVector2Array([center + Vector2(-5, 6), center + Vector2(-5, -9), center + Vector2(8, -12), center + Vector2(8, 3)]), ink, 2, true)
				draw_circle(center + Vector2(-9, 7), 4, ink, true, -1, true)
				draw_circle(center + Vector2(4, 4), 4, ink, true, -1, true)
			"vision":
				HomeArt.oval(self, center, Vector2(13, 8), Color.TRANSPARENT, ink, 2)
				draw_circle(center, 4, ink, true, -1, true)
			"globe":
				draw_circle(center, 12, ink, false, 2, true)
				HomeArt.oval(self, center, Vector2(5, 12), Color.TRANSPARENT, ink, 1)
				draw_line(center + Vector2(-10, 0), center + Vector2(10, 0), ink, 1, true)
			"shield":
				DrawUtil.shape(self, PackedVector2Array([center + Vector2(-11, -10), center + Vector2(11, -10), center + Vector2(10, 4), center + Vector2(0, 13), center + Vector2(-10, 4)]), Color("fffaf3"), ink, 1.5)
				HomeArt.heart(self, center, 0.34, ink)


class Backdrop:
	extends Control
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)
	func _draw() -> void:
		DrawUtil.vgradient(self, Rect2(Vector2.ZERO, size), Color("f6f0e8"), Color("e8eee6"))
		HomeArt.oval(self, Vector2(size.x * 0.87, 70), Vector2(140, 150), Color("eadfef70"))
		HomeArt.oval(self, Vector2(size.x * 0.1, size.y * 0.8), Vector2(150, 220), Color("d6e7db60"))
