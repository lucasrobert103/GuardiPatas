class_name SettingsScreen
extends Control
## Ajustes: volumes, vibração, acessibilidade e privacidade.

signal go(screen: String, arg: Variant)

var _confirm: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBg.new())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var box := UiKit.vbox(16)
	panel.add_child(box)
	box.add_child(UiKit.label("Ajustes", 52))
	box.add_child(_slider("Música", "music"))
	box.add_child(_slider("Efeitos sonoros", "sfx"))
	box.add_child(_toggle("Vibração", "vibration"))
	box.add_child(_toggle("Reduzir movimento", "reduce_motion"))
	box.add_child(_toggle("Destacar insetos (alto contraste)", "high_contrast"))
	var priv := UiKit.label("Privacidade: o GuardiPatas não coleta dados pessoais. Seu progresso fica salvo só neste aparelho.", 22, Color(Palette.UI_TEXT, 0.8), 0, Palette.WHITE, true)
	priv.custom_minimum_size = Vector2(560, 0)
	box.add_child(priv)
	var row := UiKit.hbox(16)
	box.add_child(row)
	var reset := UiKit.button("Apagar progresso", Palette.DANGER, "", 0, 80)
	reset.pressed.connect(_ask_reset)
	row.add_child(reset)
	var back := UiKit.button("Voltar", Palette.UI_GOOD, "back", 0, 80)
	back.pressed.connect(func(): go.emit("title", null))
	row.add_child(back)
	box.add_child(UiKit.label("Versão %s" % ProjectSettings.get_setting("application/config/version", "dev"), 20, Color(Palette.UI_TEXT, 0.6)))
	UiKit.pop_in(panel)


func _slider(text: String, key: String) -> Control:
	var v := UiKit.vbox(4)
	v.add_child(UiKit.label(text, 28))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Game.setting(key))
	s.custom_minimum_size = Vector2(520, 48)
	s.value_changed.connect(func(val: float):
		Game.set_setting(key, val)
		if key == "sfx":
			Sfx.play("ui_click"))
	v.add_child(s)
	return v


func _toggle(text: String, key: String) -> Control:
	var on: bool = Game.setting(key)
	var b := UiKit.button(("[x]  " if on else "[  ]  ") + text, Palette.UI_SECONDARY if on else Palette.UI_MUTED, "", 560, 76)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(func():
		var now: bool = not bool(Game.setting(key))
		Game.set_setting(key, now)
		b.text = ("[x]  " if now else "[  ]  ") + text
		b.add_theme_stylebox_override("normal", UiKit.btn_style(Palette.UI_SECONDARY if now else Palette.UI_MUTED, false)))
	return b


func _ask_reset() -> void:
	if _confirm != null:
		return
	_confirm = Control.new()
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_confirm)
	_confirm.add_child(UiKit.dim())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(center)
	var p := UiKit.panel()
	center.add_child(p)
	var box := UiKit.vbox(18)
	p.add_child(box)
	var warn := UiKit.label("Apagar todo o progresso?\nEstrelas, moedas e acessórios serão perdidos.", 28, Palette.UI_TEXT, 0, Palette.WHITE, true)
	warn.custom_minimum_size = Vector2(480, 0)
	box.add_child(warn)
	var row := UiKit.hbox(16)
	box.add_child(row)
	var no := UiKit.button("Cancelar", Palette.UI_GOOD)
	no.pressed.connect(func():
		_confirm.queue_free()
		_confirm = null)
	row.add_child(no)
	var yes := UiKit.button("Apagar", Palette.DANGER)
	yes.pressed.connect(func():
		Game.reset_progress()
		_confirm.queue_free()
		_confirm = null
		go.emit("title", null))
	row.add_child(yes)
	UiKit.pop_in(p)
