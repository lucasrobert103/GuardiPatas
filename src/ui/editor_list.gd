class_name EditorList
extends Control
## "Criar": lista das fases feitas pelo jogador (até Game.CUSTOM_MAX), com jogar/editar/apagar.

signal go(screen: String, arg: Variant)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := MenuBg.new()
	bg.world_id = 2
	add_child(bg)
	var col := UiKit.vbox(16)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 20
	col.offset_right = -20
	col.offset_top = 24
	col.offset_bottom = -24
	add_child(col)
	var top := UiKit.hbox(14)
	col.add_child(top)
	var back := UiKit.icon_button("back")
	back.pressed.connect(func(): go.emit("title", null))
	top.add_child(back)
	var t := UiKit.label("Criar Fases", 44, Palette.WHITE, 12, Palette.OUTLINE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var list: Array = Game.custom_levels()
	var info := UiKit.panel(Palette.CREAM)
	col.add_child(info)
	var il := UiKit.label("Monte a sua fase: coloque bichinhos, ninhos, pedras e blocos. Depois teste — quando você vencer, ela ganha o selo de testada!", 22, Palette.UI_TEXT, 0, Palette.WHITE, true)
	il.custom_minimum_size = Vector2(620, 0)
	info.add_child(il)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var box := UiKit.vbox(14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	for i in list.size():
		box.add_child(_card(i, list[i]))
	var new_btn := UiKit.button("Nova fase", Palette.UI_GOOD, "pencil", 420, 110)
	new_btn.add_theme_font_size_override("font_size", 36)
	new_btn.disabled = list.size() >= Game.CUSTOM_MAX
	new_btn.pressed.connect(func(): go.emit("edit", -1))
	col.add_child(new_btn)
	new_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Sfx.music("music_menu")


func _card(i: int, d: Dictionary) -> Control:
	var p := UiKit.panel(Palette.world(int(d.get("world", 1)))["sky_bottom"])
	var row := UiKit.hbox(12)
	p.add_child(row)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(90, 90)
	var animals: Array = d.get("animals", [])
	if not animals.is_empty():
		var art := AnimalArt.new()
		art.species = str(animals[0]["type"])
		art.preview = true
		art.position = Vector2(45, 60)
		art.scale = Vector2(0.7, 0.7)
		holder.add_child(art)
	row.add_child(holder)
	var txt := UiKit.vbox(2)
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.add_child(UiKit.label(str(d.get("name", "Minha fase")), 28))
	var ok := bool(d.get("verified", false))
	txt.add_child(UiKit.label("Testada: você venceu!" if ok else "Ainda não testada", 20, Palette.UI_GOOD if ok else Color(Palette.UI_TEXT, 0.6)))
	row.add_child(txt)
	var play := UiKit.icon_button("play", Palette.UI_GOOD, 84)
	play.pressed.connect(func(): go.emit("level", EditorScreen.playable(d, i)))
	row.add_child(play)
	var ed := UiKit.icon_button("pencil", Palette.UI_PANEL, 84)
	ed.pressed.connect(func(): go.emit("edit", i))
	row.add_child(ed)
	var del := UiKit.icon_button("close", Palette.DANGER, 84)
	del.pressed.connect(func():
		Game.delete_custom(i)
		go.emit("editor", null))
	row.add_child(del)
	return p
