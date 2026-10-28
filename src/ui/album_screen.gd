class_name AlbumScreen
extends Control
## Álbum de fotos das vitórias (guardadas só neste aparelho). Toque numa foto para ver grande.

signal go(screen: String, arg: Variant)

var _grid: GridContainer
var _viewer: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBg.new())
	var col := UiKit.vbox(14)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 20
	col.offset_right = -20
	col.offset_top = 24
	col.offset_bottom = -24
	add_child(col)
	var top := UiKit.hbox(14)
	col.add_child(top)
	var back := UiKit.icon_button("back")
	back.pressed.connect(func(): go.emit("home", null))
	top.add_child(back)
	var t := UiKit.label("Álbum de Fotos", 44, Palette.WHITE, 12, Palette.OUTLINE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var album: Array = Game.data["album"]
	if album.is_empty():
		var p := UiKit.panel()
		col.add_child(p)
		var l := UiKit.label("Ainda não tem fotos.\nNa tela de vitória, toque na câmera para guardar o momento!", 28, Palette.UI_TEXT, 0, Palette.WHITE, true)
		l.custom_minimum_size = Vector2(600, 0)
		p.add_child(l)
		return
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)
	for i in range(album.size() - 1, -1, -1):
		_grid.add_child(_thumb(i, album[i]))


func _texture(entry: Dictionary) -> Texture2D:
	var img := Image.load_from_file(str(entry.get("file", "")))
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


func _thumb(i: int, entry: Dictionary) -> Control:
	var b := UiKit.button("", Palette.WHITE, "", 210, 330)
	var tex := _texture(entry)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 12
		tr.offset_top = 12
		tr.offset_right = -12
		tr.offset_bottom = -52
		b.add_child(tr)
	var l := UiKit.label(str(entry.get("caption", "")), 16)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.clip_text = true
	l.anchor_right = 1.0
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.offset_left = 8
	l.offset_right = -8
	l.offset_top = -50
	l.offset_bottom = -14
	b.add_child(l)
	b.pressed.connect(func(): _open(i))
	return b


func _open(i: int) -> void:
	var entry: Dictionary = Game.data["album"][i]
	_viewer = Control.new()
	_viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_viewer)
	_viewer.add_child(UiKit.dim(0.7))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewer.add_child(center)
	var panel := UiKit.panel(Palette.WHITE)
	center.add_child(panel)
	var box := UiKit.vbox(12)
	panel.add_child(box)
	var tr := TextureRect.new()
	tr.texture = _texture(entry)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(540, 860)
	box.add_child(tr)
	box.add_child(UiKit.label("%s · %s" % [entry.get("caption", ""), _date(str(entry.get("date", "")))], 24))
	var row := UiKit.hbox(16)
	box.add_child(row)
	var del := UiKit.button("Apagar", Palette.DANGER, "close", 220, 84)
	del.pressed.connect(func():
		Game.remove_photo(i)
		go.emit("album", null))
	row.add_child(del)
	var close := UiKit.button("Fechar", Palette.UI_GOOD, "check", 220, 84)
	close.pressed.connect(func():
		_viewer.queue_free()
		_viewer = null)
	row.add_child(close)
	UiKit.pop_in(panel)


static func _date(iso: String) -> String:
	var p := iso.split("-")
	return "%s/%s/%s" % [p[2], p[1], p[0]] if p.size() == 3 else iso
