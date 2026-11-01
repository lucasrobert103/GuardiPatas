class_name PaintScreen
extends Control
## Ateliê: desenhar e pintar à vontade. Lápis, pincel, giz de cera, arco-íris, brilho,
## neon, spray, balde de tinta e borracha; adesivos (formas fofas, todos os bichinhos e
## insetos); modelos para colorir e cenários; desfazer/refazer; salvar no Álbum.
##
## Camadas (de baixo para cima): fundo do modelo · pintura · linhas do modelo (ficam por
## cima, como num livro de colorir) · adesivos. A pintura é uma SubViewport com os traços
## como nós; de tempos em tempos eles são "achatados" numa imagem para continuar leve.

signal go(screen: String, arg: Variant)

const CANVAS := Vector2i(688, 800)
const TOOLS := [["pencil", "Lápis"], ["brush", "Pincel"], ["crayon", "Giz"], ["rainbow", "Arco-íris"], ["glitter", "Brilho"],
	["neon", "Neon"], ["spray", "Spray"], ["fill", "Balde"], ["eraser", "Borracha"], ["sticker", "Adesivos"]]
const COLORS := ["1f1b2e", "ffffff", "ff5d73", "ff8fb1", "ffc2d4", "ff9f43", "ffd23f", "fff3a3", "7ed957", "2fbf71",
	"b8f2c9", "6bc4ff", "3b82f6", "b9e3ff", "b18cff", "7c4dff", "e0c3ff", "c98a4a", "8a5a39", "f2d2b6", "9aa0a6", "5c5470"]
const SIZES := [5.0, 12.0, 24.0, 44.0]
const STICKER_SCALE := [0.55, 0.85, 1.2, 1.7]
const MAX_LIVE := 40
const MAX_HISTORY := 5

## Pintura guardada durante a sessão (voltar ao Ateliê continua de onde parou).
static var _session: Dictionary = {}

var tool := "brush"
var color := Color("ff5d73")
var size_index := 1
var template := "blank"
var sticker := "shape:heart"
var dirty := false

var _view: SubViewport
var _paint: SubViewport
var _bg: TemplateLayer
var _lines: TemplateLayer
var _base: Sprite2D
var _paint_sprite: Sprite2D
var _stickers: Node2D
var _display: TextureRect
var _frame: PanelContainer
var _ui: Control
var _top: HBoxContainer
var _dock: PanelContainer
var _tool_row: HBoxContainer
var _color_scroll: ScrollContainer
var _sticker_scroll: ScrollContainer
var _sticker_row: HBoxContainer
var _size_row: HBoxContainer
var _cat_row: HBoxContainer
var _sel_bar: HBoxContainer
var _tool_btns: Dictionary = {}
var _swatches: Array[Swatch] = []
var _size_btns: Array[SizeDot] = []
var _cat_btns: Dictionary = {}
var _sticker_cat := "shapes"
var _undo_btn: Button
var _redo_btn: Button
var _modal: Control
var _toast: Label
var _toast_t := 0.0

var _actions: Array = []      # {"kind": "paint"|"sticker", "node": Node}
var _redo: Array = []
var _history: Array[Image] = []
var _stroke: Stroke
var _drag: Sticker
var _selected: Sticker
var _drag_offset := Vector2.ZERO
var _flattening := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := MenuBg.new()
	bg.world_id = 4
	add_child(bg)
	_build_canvas()
	_build_ui()
	_restore_session()
	resized.connect(_layout)
	_layout()
	_select_tool("brush")
	Sfx.music("music_menu")


# ------------------------------------------------------------------ camadas
func _build_canvas() -> void:
	_paint = SubViewport.new()
	_paint.size = CANVAS
	_paint.transparent_bg = true
	_paint.disable_3d = true
	_paint.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_paint)
	_base = Sprite2D.new()
	_base.centered = false
	_paint.add_child(_base)

	_view = SubViewport.new()
	_view.size = CANVAS
	_view.disable_3d = true
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	_bg = TemplateLayer.new()
	_bg.layer = "bg"
	_view.add_child(_bg)
	_paint_sprite = Sprite2D.new()
	_paint_sprite.centered = false
	_paint_sprite.texture = _paint.get_texture()
	_view.add_child(_paint_sprite)
	_lines = TemplateLayer.new()
	_lines.layer = "lines"
	_view.add_child(_lines)
	_stickers = Node2D.new()
	_view.add_child(_stickers)
	_set_template(template)


func _set_template(id: String) -> void:
	template = id
	_bg.template = id
	_lines.template = id
	_bg.queue_redraw()
	_lines.queue_redraw()


# ------------------------------------------------------------------ interface
func _build_ui() -> void:
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)
	_top = UiKit.hbox(8)
	_ui.add_child(_top)
	var back := UiKit.icon_button("back", Palette.UI_PANEL, 72)
	back.pressed.connect(on_back_pressed)
	_top.add_child(back)
	var tpl := UiKit.button("Modelos", Color("ffd6e7"), "", 0, 72)
	tpl.add_theme_font_size_override("font_size", UiKit.fs(24))
	tpl.pressed.connect(_open_templates)
	_top.add_child(tpl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_child(sp)
	_undo_btn = UiKit.icon_button("restart", Palette.UI_PANEL, 72)
	_undo_btn.tooltip_text = tr("Desfazer")
	_undo_btn.pressed.connect(undo)
	_top.add_child(_undo_btn)
	_redo_btn = UiKit.icon_button("next", Palette.UI_PANEL, 72)
	_redo_btn.tooltip_text = tr("Refazer")
	_redo_btn.pressed.connect(redo)
	_top.add_child(_redo_btn)
	var clear := UiKit.icon_button("close", Palette.DANGER, 72)
	clear.tooltip_text = tr("Apagar tudo")
	clear.pressed.connect(_ask_clear)
	_top.add_child(clear)
	var save := UiKit.icon_button("camera", Palette.UI_GOOD, 72)
	save.tooltip_text = tr("Salvar no Álbum")
	save.pressed.connect(save_to_album)
	_top.add_child(save)

	_frame = PanelContainer.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Palette.OUTLINE
	fs.set_corner_radius_all(22)
	fs.set_content_margin_all(5)
	_frame.add_theme_stylebox_override("panel", fs)
	_ui.add_child(_frame)
	_display = TextureRect.new()
	_display.texture = _view.get_texture()
	_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display.stretch_mode = TextureRect.STRETCH_SCALE
	_display.mouse_filter = Control.MOUSE_FILTER_STOP
	_display.gui_input.connect(_on_canvas_input)
	_frame.add_child(_display)
	_sel_bar = UiKit.hbox(8)
	_sel_bar.visible = false
	_ui.add_child(_sel_bar)
	for spec in [["−", "smaller"], ["+", "bigger"], ["↔", "flip"], ["⟳", "turn"], ["✕", "delete"]]:
		var b := UiKit.button(spec[0], Palette.UI_PANEL if spec[1] != "delete" else Palette.DANGER, "", 64, 60)
		b.add_theme_font_size_override("font_size", UiKit.fs(30))
		var act: String = spec[1]
		b.pressed.connect(func(): _sticker_action(act))
		_sel_bar.add_child(b)

	_dock = PanelContainer.new()
	var st := UiKit.panel_style(Color(Palette.UI_PANEL, 0.96), 28)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	_dock.add_theme_stylebox_override("panel", st)
	_ui.add_child(_dock)
	var col := UiKit.vbox(8)
	_dock.add_child(col)
	_tool_row = UiKit.hbox(4)
	col.add_child(_tool_row)
	for spec in TOOLS:
		var b := ToolButton.new()
		b.tool = spec[0]
		b.label_text = tr(spec[1])
		b.tooltip_text = tr(spec[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 78)
		b.screen = self
		var id: String = spec[0]
		b.pressed.connect(func(): _select_tool(id))
		_tool_row.add_child(b)
		_tool_btns[id] = b
	# cores
	_color_scroll = ScrollContainer.new()
	DragScroll.attach(_color_scroll)
	_color_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_color_scroll.custom_minimum_size = Vector2(0, 62)
	col.add_child(_color_scroll)
	var crow := UiKit.hbox(6)
	crow.alignment = BoxContainer.ALIGNMENT_BEGIN
	_color_scroll.add_child(crow)
	for hex in COLORS:
		var sw := Swatch.new()
		sw.color = Color(hex)
		sw.custom_minimum_size = Vector2(56, 56)
		sw.pressed.connect(func(): _pick_color(sw.color))
		crow.add_child(sw)
		_swatches.append(sw)
	# adesivos
	_sticker_scroll = ScrollContainer.new()
	DragScroll.attach(_sticker_scroll)
	_sticker_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sticker_scroll.custom_minimum_size = Vector2(0, 80)
	_sticker_scroll.visible = false
	col.add_child(_sticker_scroll)
	_sticker_row = UiKit.hbox(6)
	_sticker_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_sticker_scroll.add_child(_sticker_row)
	# tamanhos + categorias de adesivo
	var bottom := UiKit.hbox(10)
	col.add_child(bottom)
	_size_row = UiKit.hbox(6)
	bottom.add_child(_size_row)
	for i in SIZES.size():
		var d := SizeDot.new()
		d.radius = 5.0 + i * 5.0
		d.custom_minimum_size = Vector2(54, 50)
		var idx := i
		d.pressed.connect(func(): _pick_size(idx))
		_size_row.add_child(d)
		_size_btns.append(d)
	_cat_row = UiKit.hbox(6)
	_cat_row.visible = false
	bottom.add_child(_cat_row)
	for spec in [["shapes", "Formas"], ["animals", "Bichinhos"], ["insects", "Insetos"]]:
		var b := UiKit.button(spec[1], Palette.UI_PANEL, "", 0, 50)
		b.add_theme_font_size_override("font_size", UiKit.fs(19))
		var cat: String = spec[0]
		b.pressed.connect(func(): _show_stickers(cat))
		_cat_row.add_child(b)
		_cat_btns[cat] = b
	_toast = UiKit.label("", 28, Palette.WHITE, 8, Palette.OUTLINE, true)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	_ui.add_child(_toast)
	_pick_color(color)
	_pick_size(size_index)
	_refresh_undo()


func _layout() -> void:
	if size.x <= 0 or _top == null:
		return
	var ins := UiKit.safe_insets(self)
	var area := Rect2(Vector2(ins.x + 10, ins.y + UiKit.TOP_GAP), size - Vector2(ins.x + ins.z + 20, ins.y + ins.w + UiKit.TOP_GAP + UiKit.GESTURE_GAP - 8))
	_top.position = area.position
	_top.size = Vector2(area.size.x, 76)
	_dock.size = Vector2(area.size.x, 0)
	var dock_h := _dock.get_combined_minimum_size().y
	_dock.position = Vector2(area.position.x, area.end.y - dock_h)
	_dock.size = Vector2(area.size.x, dock_h)
	var room := Rect2(area.position.x, area.position.y + 84, area.size.x, _dock.position.y - area.position.y - 84 - 8)
	var k := minf(room.size.x / CANVAS.x, room.size.y / CANVAS.y)
	var disp := Vector2(CANVAS) * k
	_frame.position = Vector2(room.get_center().x - disp.x / 2 - 5, room.position.y + (room.size.y - disp.y) / 2 - 5)
	_frame.size = disp + Vector2(10, 10)
	_sel_bar.size = _sel_bar.get_combined_minimum_size()
	_sel_bar.position = Vector2(_frame.get_rect().end.x - _sel_bar.size.x - 10, _frame.position.y + 12)
	_toast.size = Vector2(area.size.x, 60)
	_toast.position = Vector2(area.position.x, _frame.get_rect().get_center().y - 30)


func _canvas_point(local: Vector2) -> Vector2:
	var k := Vector2(CANVAS) / maxf(_display.size.x, 1.0)
	return local * k.x


# ------------------------------------------------------------------ escolhas
func _select_tool(id: String) -> void:
	tool = id
	for k in _tool_btns:
		(_tool_btns[k] as ToolButton).active = k == id
		(_tool_btns[k] as ToolButton).queue_redraw()
	var stick := id == "sticker"
	_sticker_scroll.visible = stick
	_cat_row.visible = stick
	_color_scroll.visible = not stick or _sticker_cat == "shapes"
	if stick:
		_show_stickers(_sticker_cat)
	else:
		_select_sticker(null)
	_layout.call_deferred()


func _pick_color(c: Color) -> void:
	color = c
	for sw in _swatches:
		sw.active = sw.color == c
		sw.queue_redraw()
	for k in _tool_btns:
		(_tool_btns[k] as ToolButton).queue_redraw()
	if _selected != null and _selected.kind.begins_with("shape:"):
		_selected.tint = c
		_selected.queue_redraw()
		dirty = true
	if tool == "sticker" and _sticker_cat == "shapes":
		for cell in _sticker_row.get_children():
			cell.queue_redraw()


func _pick_size(i: int) -> void:
	size_index = i
	for j in _size_btns.size():
		_size_btns[j].active = j == i
		_size_btns[j].queue_redraw()
	if _selected != null:
		_selected.scale = Vector2(signf(_selected.scale.x), 1.0) * STICKER_SCALE[i]
		dirty = true


func _show_stickers(cat: String) -> void:
	_sticker_cat = cat
	for k in _cat_btns:
		var b: Button = _cat_btns[k]
		var c := Palette.GOLD if k == cat else Palette.UI_PANEL
		b.add_theme_stylebox_override("normal", UiKit.btn_style(c, false))
		b.add_theme_stylebox_override("hover", UiKit.btn_style(c.lightened(0.06), false))
	_color_scroll.visible = cat == "shapes"
	for c in _sticker_row.get_children():
		c.queue_free()
	var ids: Array = []
	match cat:
		"shapes":
			for s in PaintArt.SHAPES: ids.append("shape:" + s)
		"animals":
			for s in Animal.SPECIES.keys(): ids.append("animal:" + s)
		"insects":
			for s in Nest.KINDS: ids.append("insect:" + s)
	for id in ids:
		var cell := StickerCell.new()
		cell.kind = id
		cell.screen = self
		cell.custom_minimum_size = Vector2(76, 76)
		var kid: String = id
		cell.pressed.connect(func():
			sticker = kid
			for c in _sticker_row.get_children(): c.queue_redraw()
			Sfx.play("pop", -6.0, 1.3))
		_sticker_row.add_child(cell)
	if not sticker.begins_with({"shapes": "shape:", "animals": "animal:", "insects": "insect:"}[cat]):
		sticker = ids[0]
	_layout.call_deferred()


# ------------------------------------------------------------------ toque na tela
func _on_canvas_input(event: InputEvent) -> void:
	if _modal != null:
		return
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		var p := _canvas_point(mb.position)
		if mb.pressed:
			_press(p)
		else:
			_release()
		_display.accept_event()
		return
	var mm := event as InputEventMouseMotion
	if mm != null and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_move(_canvas_point(mm.position))
		_display.accept_event()


func _press(p: Vector2) -> void:
	match tool:
		"sticker":
			var hit := _sticker_at(p)
			if hit != null:
				_select_sticker(hit)
				_drag = hit
				_drag_offset = hit.position - p
			else:
				var s := add_sticker(sticker, p)
				_select_sticker(s)
				_drag = s
				_drag_offset = Vector2.ZERO
		"fill":
			fill_at(p)
		_:
			_select_sticker(null)
			begin_stroke(p)


func _move(p: Vector2) -> void:
	if _drag != null:
		_drag.position = (p + _drag_offset).clamp(Vector2.ZERO, Vector2(CANVAS))
		dirty = true
	elif _stroke != null:
		_stroke.add_point(p)


func _release() -> void:
	_drag = null
	end_stroke()


# ------------------------------------------------------------------ traços
func begin_stroke(p: Vector2) -> void:
	end_stroke()
	_stroke = Stroke.new()
	_stroke.kind = tool
	_stroke.color = color
	_stroke.width = SIZES[size_index] * (0.45 if tool == "pencil" else 1.0)
	_stroke.seed_value = randi()
	if tool == "eraser":
		_stroke.material = _erase_material()
		_stroke.width = SIZES[size_index] * 1.4
	_paint.add_child(_stroke)
	_stroke.add_point(p)
	Sfx.loop("paint", "draw_loop", -14.0, 1.1)


func end_stroke() -> void:
	Sfx.stop_loop("paint")
	if _stroke == null:
		return
	var s := _stroke
	_stroke = null
	if s.points.is_empty():
		s.queue_free()
		return
	_push_action({"kind": "paint", "node": s})


static var _erase_mat: ShaderMaterial
static func _erase_material() -> ShaderMaterial:
	if _erase_mat == null:
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nrender_mode blend_disabled;\nvoid fragment() { COLOR = vec4(0.0); }\n"
		_erase_mat = ShaderMaterial.new()
		_erase_mat.shader = sh
	return _erase_mat


# ------------------------------------------------------------------ balde de tinta
## Pinta a região da mesma cor ao redor do toque (respeita as linhas do modelo e os traços).
func fill_at(p: Vector2) -> void:
	await RenderingServer.frame_post_draw
	var img := _view.get_texture().get_image()
	if img == null or img.is_empty():
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := CANVAS.x / 2
	var h := CANVAS.y / 2
	img.resize(w, h, Image.INTERPOLATE_NEAREST)
	var sx := clampi(int(p.x / 2.0), 0, w - 1)
	var sy := clampi(int(p.y / 2.0), 0, h - 1)
	var src := img.get_data()
	var mask := PackedByteArray()
	mask.resize(w * h)
	var i0 := (sy * w + sx) * 4
	var r0 := src[i0]
	var g0 := src[i0 + 1]
	var b0 := src[i0 + 2]
	var tol := 46
	var stack: Array[int] = [sy * w + sx]
	var filled := 0
	while not stack.is_empty():
		var idx: int = stack.pop_back()
		var y := idx / w
		var x := idx % w
		# anda até a borda esquerda da faixa
		while x > 0 and mask[y * w + x - 1] == 0 and _similar(src, (y * w + x - 1) * 4, r0, g0, b0, tol):
			x -= 1
		var up := false
		var down := false
		while x < w and mask[y * w + x] == 0 and _similar(src, (y * w + x) * 4, r0, g0, b0, tol):
			mask[y * w + x] = 1
			filled += 1
			if y > 0:
				var u := (y - 1) * w + x
				var su := mask[u] == 0 and _similar(src, u * 4, r0, g0, b0, tol)
				if su and not up:
					stack.append(u)
				up = su
			if y < h - 1:
				var d := (y + 1) * w + x
				var sd := mask[d] == 0 and _similar(src, d * 4, r0, g0, b0, tol)
				if sd and not down:
					stack.append(d)
				down = sd
			x += 1
	if filled == 0:
		return
	# imagem do preenchimento (com 1 pixel a mais nas bordas para não deixar frestas)
	var out := PackedByteArray()
	out.resize(w * h * 4)
	var c8 := [int(color.r8), int(color.g8), int(color.b8)]
	for y in h:
		for x in w:
			var m := mask[y * w + x] == 1
			if not m:
				m = (x > 0 and mask[y * w + x - 1] == 1) or (x < w - 1 and mask[y * w + x + 1] == 1) \
					or (y > 0 and mask[(y - 1) * w + x] == 1) or (y < h - 1 and mask[(y + 1) * w + x] == 1)
			if m:
				var o := (y * w + x) * 4
				out[o] = c8[0]
				out[o + 1] = c8[1]
				out[o + 2] = c8[2]
				out[o + 3] = 255
	var fill_img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, out)
	var spr := Sprite2D.new()
	spr.centered = false
	spr.scale = Vector2(2, 2)
	spr.texture = ImageTexture.create_from_image(fill_img)
	_paint.add_child(spr)
	_push_action({"kind": "paint", "node": spr})
	Sfx.play("bloop", -4.0, 1.2)


static func _similar(src: PackedByteArray, i: int, r: int, g: int, b: int, tol: int) -> bool:
	return absi(src[i] - r) + absi(src[i + 1] - g) + absi(src[i + 2] - b) <= tol


# ------------------------------------------------------------------ adesivos
func add_sticker(kind: String, p: Vector2) -> Sticker:
	var s := Sticker.new()
	s.kind = kind
	s.tint = color
	s.position = p
	s.scale = Vector2.ONE * STICKER_SCALE[size_index]
	_stickers.add_child(s)
	_push_action({"kind": "sticker", "node": s})
	Sfx.play("pop", -2.0, 1.1, 0.1)
	return s


func _sticker_at(p: Vector2) -> Sticker:
	var kids := _stickers.get_children()
	for i in range(kids.size() - 1, -1, -1):
		var s := kids[i] as Sticker
		if s != null and s.position.distance_to(p) < 52.0 * absf(s.scale.y):
			return s
	return null


func _select_sticker(s: Sticker) -> void:
	if _selected != null and is_instance_valid(_selected):
		_selected.selected = false
		_selected.queue_redraw()
	_selected = s
	if s != null:
		s.selected = true
		s.queue_redraw()
	_sel_bar.visible = s != null
	_layout.call_deferred()


func _sticker_action(act: String) -> void:
	if _selected == null or not is_instance_valid(_selected):
		return
	var s := _selected
	match act:
		"smaller":
			s.scale = s.scale * 0.85
		"bigger":
			s.scale = s.scale * 1.18 if absf(s.scale.y) < 3.0 else s.scale
		"flip":
			s.scale.x = -s.scale.x
		"turn":
			s.rotation += PI / 8.0
		"delete":
			for a in _actions:
				if a.get("node") == s:
					_actions.erase(a)
					break
			_select_sticker(null)
			s.queue_free()
			_refresh_undo()
	dirty = true
	Sfx.play("pop", -8.0, 1.4)


# ------------------------------------------------------------------ desfazer / refazer
func _push_action(a: Dictionary) -> void:
	_actions.append(a)
	_redo.clear()
	dirty = true
	_refresh_undo()
	if _paint_count() > MAX_LIVE and not _flattening:
		_flatten()


func _paint_count() -> int:
	var n := 0
	for a in _actions:
		if a["kind"] == "paint":
			n += 1
	return n


## Junta os traços numa imagem só (fica leve); guarda a imagem anterior para desfazer.
func _flatten() -> void:
	_flattening = true
	await RenderingServer.frame_post_draw
	var img := _paint.get_texture().get_image()
	if _base.texture != null:
		_history.append((_base.texture as ImageTexture).get_image())
	else:
		_history.append(Image.create_empty(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8))
	while _history.size() > MAX_HISTORY:
		_history.pop_front()
	_base.texture = ImageTexture.create_from_image(img)
	var keep: Array = []
	for a in _actions:
		if a["kind"] == "paint":
			(a["node"] as Node).queue_free()
		else:
			keep.append(a)
	keep.push_front({"kind": "flatten"})
	_actions = keep
	_redo.clear()
	_flattening = false
	_refresh_undo()


func undo() -> void:
	end_stroke()
	if _actions.is_empty():
		return
	var a: Dictionary = _actions.pop_back()
	if a["kind"] == "flatten":
		# volta à imagem anterior (desfaz um bloco de traços de uma vez)
		if not _history.is_empty():
			var prev: Image = _history.pop_back()
			_base.texture = ImageTexture.create_from_image(prev)
			if not _history.is_empty():
				_actions.push_front({"kind": "flatten"})
		_redo.clear()
	else:
		var n: Node = a["node"]
		if n == _selected:
			_select_sticker(null)
		n.get_parent().remove_child(n)
		_redo.append(a)
	dirty = true
	Sfx.play("ui_back", -6.0)
	_refresh_undo()


func redo() -> void:
	if _redo.is_empty():
		return
	var a: Dictionary = _redo.pop_back()
	var n: Node = a["node"]
	(_paint if a["kind"] == "paint" else _stickers).add_child(n)
	_actions.append(a)
	dirty = true
	Sfx.play("ui_click", -6.0)
	_refresh_undo()


func _refresh_undo() -> void:
	if _undo_btn != null:
		_undo_btn.disabled = _actions.is_empty()
		_redo_btn.disabled = _redo.is_empty()


func clear_all() -> void:
	end_stroke()
	_select_sticker(null)
	for a in _actions:
		if a.has("node") and is_instance_valid(a["node"]):
			(a["node"] as Node).queue_free()
	for a in _redo:
		if is_instance_valid(a["node"]):
			(a["node"] as Node).queue_free()
	_actions.clear()
	_redo.clear()
	_history.clear()
	_base.texture = null
	dirty = false
	_refresh_undo()


# ------------------------------------------------------------------ salvar
## Grava a pintura (com modelo e adesivos) no Álbum do jogo.
func save_to_album() -> Dictionary:
	_select_sticker(null)
	end_stroke()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := _view.get_texture().get_image()
	if img == null or img.is_empty():
		return {}
	var res := Game.add_photo(img, UiKit.tr_text("Minha pintura"), CANVAS.x)
	dirty = false
	Sfx.play("unlock")
	_show_toast(tr("Salva no Álbum!"))
	for i in 3:
		Fx.confetti(self, _frame.get_rect().get_center() + Vector2(-140 + i * 140, -120))
	return res


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast_t = 1.6


func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)


# ------------------------------------------------------------------ janelinhas
func _open_modal(title: String) -> VBoxContainer:
	_close_modal()
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_modal)
	var dim := UiKit.dim(0.5)
	_modal.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal.add_child(center)
	var card := UiKit.panel(Palette.CREAM)
	card.custom_minimum_size.x = minf(size.x - 40, 660)
	center.add_child(card)
	var box := UiKit.vbox(14)
	card.add_child(box)
	box.add_child(UiKit.title(title, 44))
	UiKit.pop_in(card)
	return box


func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null


func _open_templates() -> void:
	var box := _open_modal("Modelos")
	var scroll := ScrollContainer.new()
	DragScroll.attach(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, minf(size.y * 0.62, 820))
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for t in PaintArt.TEMPLATES:
		var b := TemplateCell.new()
		b.template = t[0]
		b.label_text = tr(t[1])
		b.active = t[0] == template
		b.custom_minimum_size = Vector2(190, 250)
		var id: String = t[0]
		b.pressed.connect(func():
			_set_template(id)
			dirty = true
			_close_modal()
			Sfx.play("pop", -2.0, 1.0))
		grid.add_child(b)
	var close := UiKit.button("Fechar", Palette.UI_SECONDARY, "", 260, 76)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_modal)
	box.add_child(close)


func _ask_clear() -> void:
	var box := _open_modal("Apagar tudo?")
	box.add_child(UiKit.label("A pintura e os adesivos somem. O modelo continua.", 24, Palette.UI_TEXT, 0, Palette.WHITE, true))
	var row := UiKit.hbox(14)
	box.add_child(row)
	var no := UiKit.button("Cancelar", Palette.UI_SECONDARY, "", 220, 80)
	no.pressed.connect(_close_modal)
	row.add_child(no)
	var yes := UiKit.button("Apagar", Palette.DANGER, "close", 220, 80)
	yes.pressed.connect(func():
		clear_all()
		_close_modal())
	row.add_child(yes)


func on_back_pressed() -> void:
	if _modal != null:
		_close_modal()
		return
	if not dirty:
		_leave()
		return
	var box := _open_modal("Salvar a pintura?")
	box.add_child(UiKit.label("Ela fica guardada no Álbum para você ver quando quiser.", 24, Palette.UI_TEXT, 0, Palette.WHITE, true))
	var save := UiKit.button("Salvar no Álbum", Palette.UI_GOOD, "camera", 420, 84)
	save.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	save.pressed.connect(func():
		_close_modal()
		await save_to_album()
		await get_tree().create_timer(0.8).timeout
		_leave())
	box.add_child(save)
	var row := UiKit.hbox(14)
	box.add_child(row)
	var stay := UiKit.button("Continuar pintando", Palette.UI_SECONDARY, "", 280, 76)
	stay.pressed.connect(_close_modal)
	row.add_child(stay)
	var out := UiKit.button("Sair", Palette.UI_PANEL, "", 160, 76)
	out.pressed.connect(_leave)
	row.add_child(out)


func _leave() -> void:
	_close_modal()
	_keep_session()
	go.emit("title", null)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		on_back_pressed()
		get_viewport().set_input_as_handled()


## Guarda a pintura na memória ao sair (voltar ao Ateliê continua de onde parou).
func _keep_session() -> void:
	var stickers: Array = []
	for s in _stickers.get_children():
		if s is Sticker and s.get_parent() == _stickers:
			stickers.append({"kind": s.kind, "tint": s.tint, "pos": s.position, "scale": s.scale, "rot": s.rotation})
	_session = {"template": template, "stickers": stickers, "dirty": dirty}
	var img := _paint.get_texture().get_image()
	if img != null and not img.is_empty():
		_session["paint"] = img


func _restore_session() -> void:
	if _session.is_empty():
		return
	_set_template(str(_session.get("template", "blank")))
	var img: Image = _session.get("paint")
	if img != null:
		_base.texture = ImageTexture.create_from_image(img)
	for d in _session.get("stickers", []):
		var s := Sticker.new()
		s.kind = d["kind"]
		s.tint = d["tint"]
		s.position = d["pos"]
		s.scale = d["scale"]
		s.rotation = d["rot"]
		_stickers.add_child(s)
		_actions.append({"kind": "sticker", "node": s})
	dirty = bool(_session.get("dirty", false))
	_refresh_undo()


# ================================================================== peças
## Um traço na camada de pintura (desenhado de acordo com a ferramenta).
class Stroke:
	extends Node2D
	var kind := "brush"
	var color := Color.BLACK
	var width := 12.0
	var seed_value := 0
	var points := PackedVector2Array()
	var _dots: Array = []        # [pos, raio, cor] para giz, spray e brilho
	var _length := 0.0
	var _rng := RandomNumberGenerator.new()

	func add_point(p: Vector2) -> void:
		if points.is_empty():
			_rng.seed = seed_value
		elif points[points.size() - 1].distance_to(p) < maxf(1.5, width * 0.12):
			return
		var prev := points[points.size() - 1] if not points.is_empty() else p
		_length += prev.distance_to(p)
		points.append(p)
		match kind:
			"crayon":
				var steps := maxi(1, int(prev.distance_to(p) / 2.0))
				for i in steps:
					var q := prev.lerp(p, float(i + 1) / steps)
					for j in 3:
						var off := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * width * 0.5
						_dots.append([q + off, _rng.randf_range(0.8, 2.2) * maxf(1.0, width / 10.0), Color(color, _rng.randf_range(0.35, 0.8))])
			"spray":
				# a quantidade de gotinhas acompanha a distância percorrida
				var step := maxf(3.0, width * 0.25)
				var steps := maxi(1, int(prev.distance_to(p) / step))
				for s in steps:
					var q := prev.lerp(p, float(s + 1) / steps)
					for i in int(clampf(width * 0.35, 3, 14)):
						var a := _rng.randf() * TAU
						var r := sqrt(_rng.randf()) * width * 1.2
						_dots.append([q + Vector2.from_angle(a) * r, _rng.randf_range(0.8, 1.9), Color(color, _rng.randf_range(0.55, 0.95))])
			"glitter":
				var gap := maxf(9.0, width * 0.7)
				var cols := [Color.WHITE, Color("ffd23f"), color.lightened(0.45), color]
				var last: Vector2 = _dots[_dots.size() - 1][0] if not _dots.is_empty() else prev - (p - prev).normalized() * gap
				var travel := last.distance_to(p)
				while travel >= gap:
					last = last.move_toward(p, gap)
					travel -= gap
					_dots.append([last + Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * width * 0.7, _rng.randf_range(0.35, 0.75) * width + 5.0, cols[_rng.randi() % cols.size()], _rng.randf() * TAU])
		queue_redraw()

	func _draw() -> void:
		if points.is_empty():
			return
		match kind:
			"eraser":
				_line(points, Color(0, 0, 0, 0), width, false)
			"pencil":
				_line(points, color, width, true)
			"brush":
				_line(points, color, width, true)
			"neon":
				_line(points, Color(color.lightened(0.35), 0.4), width * 1.9, true, false)
				_line(points, color.lightened(0.3), width, true)
				_line(points, Color.WHITE, maxf(2.0, width * 0.32), true)
			"rainbow":
				# cor muda suavemente ao longo do traço (pedacinhos de ~6 px)
				var dist := 0.0
				for i in range(1, points.size()):
					var a := points[i - 1]
					var b := points[i]
					var seg := a.distance_to(b)
					var n := maxi(1, int(seg / 6.0))
					for j in n:
						var q0 := a.lerp(b, float(j) / n)
						var q1 := a.lerp(b, float(j + 1) / n)
						var c := Color.from_hsv(fmod((dist + seg * (j + 0.5) / n) / 420.0, 1.0), 0.6, 1.0)
						draw_line(q0, q1, c, width, true)
						draw_circle(q1, width * 0.5, c, true, -1, true)
					dist += seg
				draw_circle(points[0], width * 0.5, Color.from_hsv(0, 0.6, 1.0), true, -1, true)
			"glitter":
				_line(points, color.lightened(0.35), width * 0.6, true)
				for d in _dots:
					var r: float = d[1]
					DrawUtil.shape(self, DrawUtil.star_points(d[0], r, r * 0.42, d[3]), d[2], Color(0, 0, 0, 0), 0.0)
			_:
				for d in _dots:
					draw_circle(d[0], d[1], d[2], true, -1, true)

	func _line(pts: PackedVector2Array, c: Color, w: float, aa: bool, joints: bool = true) -> void:
		if pts.size() == 1:
			draw_circle(pts[0], w * 0.5, c, true, -1, aa)
			return
		draw_polyline(pts, c, w, aa)
		if not joints:
			return
		draw_circle(pts[0], w * 0.5, c, true, -1, aa)
		draw_circle(pts[pts.size() - 1], w * 0.5, c, true, -1, aa)
		# juntas arredondadas nas curvas
		var step := maxi(1, pts.size() / 60)
		for i in range(1, pts.size() - 1, step):
			draw_circle(pts[i], w * 0.5, c, true, -1, aa)


## Adesivo: forma colorida, bichinho ou inseto (pode mover, aumentar, virar e girar).
class Sticker:
	extends Node2D
	var kind := "shape:heart"
	var tint := Color("ff5d73")
	var selected := false
	var _art: Node2D
	var _t := 0.0

	func _ready() -> void:
		var parts := kind.split(":")
		if parts[0] == "animal":
			var a := AnimalArt.new()
			a.species = parts[1]
			a.preview = true
			a.mood = "happy"
			a.accessory = Game.equipped(parts[1])
			a.scale = Vector2.ONE * EditorScreen.fit_scale(parts[1], 1.4)
			a.position = Vector2(0, 20)
			add_child(a)
			_art = a
		elif parts[0] == "insect":
			var ia := InsectArt.new()
			ia.kind = parts[1]
			ia.radius = 30.0
			add_child(ia)
			_art = ia

	func _process(delta: float) -> void:
		if selected:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var parts := kind.split(":")
		if parts[0] == "shape":
			PaintArt.draw_shape(self, parts[1], Vector2.ZERO, 48.0, tint)
		if selected:
			var r := 58.0
			var n := 24
			for i in n:
				if i % 2 == 0:
					var a0 := TAU * i / n + _t
					draw_arc(Vector2.ZERO, r, a0, a0 + TAU / n, 4, Color(1, 1, 1, 0.95), 5.0 / absf(scale.y), true)
					draw_arc(Vector2.ZERO, r, a0, a0 + TAU / n, 4, Color("b18cff"), 2.5 / absf(scale.y), true)


## Fundo ou linhas do modelo.
class TemplateLayer:
	extends Node2D
	var template := "blank"
	var layer := "bg"
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, Vector2(PaintScreen.CANVAS))
		if layer == "bg":
			PaintArt.draw_bg(self, template, rect)
		else:
			PaintArt.draw_lines(self, template, rect)


## Miniatura de um modelo na janela "Modelos".
class TemplateCell:
	extends Button
	var template := "blank"
	var label_text := ""
	var active := false
	func _ready() -> void:
		for st in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var l := UiKit.label(label_text, 18, Palette.UI_TEXT, 0, Palette.WHITE, true)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.anchor_right = 1.0
		l.anchor_top = 1.0
		l.anchor_bottom = 1.0
		l.offset_top = -58
		add_child(l)
	func _draw() -> void:
		var r := Rect2(Vector2(6, 6), Vector2(size.x - 12, size.y - 70))
		var k := minf(r.size.x / PaintArt.BASE.x, r.size.y / PaintArt.BASE.y)
		var pr := Rect2(r.get_center() - PaintArt.BASE * k / 2, PaintArt.BASE * k)
		HomeArt.box(self, pr.grow(5), Palette.GOLD if active else Palette.OUTLINE, 14)
		PaintArt.draw_bg(self, template, pr)
		PaintArt.draw_lines(self, template, pr)
		if is_hovered():
			HomeArt.box(self, pr.grow(5), Color.TRANSPARENT, 14, Color.WHITE, 3)


## Botão de ferramenta com o desenho dela e o nome embaixo.
class ToolButton:
	extends Button
	var tool := "brush"
	var label_text := ""
	var active := false
	var screen: PaintScreen
	func _ready() -> void:
		for st in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var l := UiKit.label(label_text, 14, Palette.UI_TEXT)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.clip_text = true
		l.anchor_right = 1.0
		l.anchor_top = 1.0
		l.anchor_bottom = 1.0
		l.offset_top = -22
		add_child(l)
	func _draw() -> void:
		var r := Rect2(Vector2(2, 2), Vector2(size.x - 4, size.y - 26))
		HomeArt.box(self, r, Palette.GOLD if active else Color(1, 1, 1, 0.85), 16, Palette.OUTLINE, 3)
		var c: Color = screen.color if screen != null else Color("ff5d73")
		PaintArt.draw_tool(self, tool, r.get_center(), minf(r.size.x, r.size.y) * 0.9, c)


## Bolinha de cor.
class Swatch:
	extends Button
	var color := Color.WHITE
	var active := false
	func _ready() -> void:
		for st in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())
	func _draw() -> void:
		var c := size / 2
		var r := minf(size.x, size.y) * 0.4
		if active:
			draw_circle(c, r + 6, Palette.GOLD, true, -1, true)
		draw_circle(c, r + 3, Palette.OUTLINE, true, -1, true)
		draw_circle(c, r, color, true, -1, true)
		draw_circle(c + Vector2(-r * 0.35, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.45), true, -1, true)


## Tamanho do pincel.
class SizeDot:
	extends Button
	var radius := 6.0
	var active := false
	func _ready() -> void:
		for st in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())
	func _draw() -> void:
		HomeArt.box(self, Rect2(Vector2(2, 2), size - Vector2(4, 4)), Palette.GOLD if active else Color(1, 1, 1, 0.85), 14, Palette.OUTLINE, 2)
		draw_circle(size / 2, radius, Palette.OUTLINE, true, -1, true)


## Miniatura de adesivo.
class StickerCell:
	extends Button
	var kind := "shape:heart"
	var screen: PaintScreen
	var _art: Node2D
	func _ready() -> void:
		for st in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var parts := kind.split(":")
		if parts[0] == "animal":
			var a := AnimalArt.new()
			a.species = parts[1]
			a.preview = true
			a.accessory = Game.equipped(parts[1])
			a.scale = Vector2.ONE * EditorScreen.fit_scale(parts[1], 0.85)
			a.set_process(false)
			add_child(a)
			_art = a
		elif parts[0] == "insect":
			var ia := InsectArt.new()
			ia.kind = parts[1]
			ia.radius = 17.0
			add_child(ia)
			_art = ia
		resized.connect(func(): if _art != null: _art.position = size / 2 + (Vector2(0, 10) if parts[0] == "animal" else Vector2.ZERO))
	func _draw() -> void:
		var on := screen != null and screen.sticker == kind
		HomeArt.box(self, Rect2(Vector2(2, 2), size - Vector2(4, 4)), Palette.GOLD if on else Color(1, 1, 1, 0.9), 16, Palette.OUTLINE, 2)
		var parts := kind.split(":")
		if parts[0] == "shape":
			PaintArt.draw_shape(self, parts[1], size / 2, minf(size.x, size.y) * 0.3, screen.color if screen != null else Color("ff5d73"))
