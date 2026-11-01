class_name TreatPicker
extends Control
## Janela do pote de petiscos: mostra os ganhos nas fases e dá um ao bichinho.

signal used(kind: String)

var pet := "capi"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 60
	var dim := UiKit.dim(0.5)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			queue_free())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := UiKit.panel(Palette.CREAM)
	panel.theme = UiKit.make_theme()
	center.add_child(panel)
	var col := UiKit.vbox(12)
	panel.add_child(col)
	col.add_child(UiKit.label("Petiscos", 36))
	if Treats.total() == 0:
		col.add_child(UiKit.label("Vença fases para ganhar petiscos!\nMais estrelas, mais petiscos.", 22, Palette.UI_TEXT, 0, Palette.WHITE, true))
	for k in Treats.ORDER:
		var row := UiKit.hbox(12)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		var ic := Hud.TreatIcon.new()
		ic.kind = k
		ic.custom_minimum_size = Vector2(56, 56)
		row.add_child(ic)
		var l := UiKit.label("%s  ×%d" % [tr(str(Treats.KINDS[k]["name"])), Treats.count(k)], 24)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(l)
		var give := UiKit.button("Dar", Palette.UI_GOOD, "heart", 140, 66)
		give.disabled = Treats.count(k) <= 0
		var kind: String = k
		give.pressed.connect(func():
			if Treats.use(kind, pet):
				Sfx.play("coin", -4.0, 1.4)
				used.emit(kind)
				queue_free())
		row.add_child(give)
		col.add_child(row)
	var close := UiKit.button("Fechar", Palette.UI_SECONDARY, "close", 0, 66)
	close.pressed.connect(queue_free)
	col.add_child(close)
