extends Node
## Rolagem por arraste (DragScroll): arrastar em cima de um botão rola e NÃO aperta o botão;
## um toque curto continua sendo clique; telas reais (Loja, Ajustes) rolam por arraste.
##   godot --headless --path . res://tests/scroll_test.tscn
var passed := 0
var failures := 0
var pointer := Vector2.ZERO


func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)


func frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame


func move(p: Vector2, held: bool) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	e.relative = p - pointer
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	pointer = p
	get_viewport().push_input(e, true)
	await get_tree().process_frame


func button(down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.position = pointer
	e.global_position = pointer
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	get_viewport().push_input(e, true)
	await get_tree().process_frame


func drag(a: Vector2, b: Vector2) -> void:
	await move(a, false)
	await button(true)
	for i in range(1, 13):
		await move(a.lerp(b, i / 12.0), true)
	await button(false)


func tap(p: Vector2) -> void:
	await move(p, false)
	await button(true)
	await button(false)


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.size = Vector2i(720, 1280)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.make_theme()
	add_child(root)
	var sc := ScrollContainer.new()
	DragScroll.attach(sc)
	sc.position = Vector2(60, 100)
	sc.size = Vector2(600, 800)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(sc)
	var col := UiKit.vbox(10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(col)
	var presses := {}
	var buttons: Array[Button] = []
	for i in 30:
		var b := UiKit.button("Item %d" % i, Palette.UI_PANEL, "", 0, 90)
		var k := i
		b.pressed.connect(func(): presses[k] = int(presses.get(k, 0)) + 1)
		col.add_child(b)
		buttons.append(b)
	await frames(3)
	check(sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER, "barra de rolagem escondida")
	var start := buttons[3].get_global_rect().get_center()
	await drag(start, start + Vector2(0, -400))
	await frames(2)
	check(sc.scroll_vertical >= 350, "arrastar em cima de um botão rola a lista (rolou %d)" % sc.scroll_vertical)
	check(presses.is_empty(), "arrastar não aperta o botão (%s)" % str(presses))
	var before := sc.scroll_vertical
	await frames(20)
	check(sc.scroll_vertical >= before, "inércia continua a rolagem ou para suavemente")
	var target := buttons[8]
	sc.ensure_control_visible(target)
	await frames(3)
	await tap(target.get_global_rect().get_center())
	await frames(2)
	check(int(presses.get(8, 0)) == 1, "toque curto continua sendo clique (%s)" % str(presses))
	var top := sc.scroll_vertical
	await drag(Vector2(360, 300), Vector2(360, 700))
	await frames(2)
	check(sc.scroll_vertical < top, "arrastar para baixo volta a lista")
	root.queue_free()
	await frames(2)
	# telas reais
	var store := StoreScreen.new()
	store.theme = UiKit.make_theme()
	add_child(store)
	store._tab = "bichinhos"
	store._refresh()
	await frames(4)
	var scroll: ScrollContainer = store._content.get_parent()
	var p := scroll.get_global_rect().get_center()
	await drag(p, p + Vector2(0, -300))
	await frames(2)
	check(scroll.scroll_vertical > 100, "Loja rola arrastando em qualquer lugar (%d)" % scroll.scroll_vertical)
	check(store._modal == null, "arrastar na Loja não abre compra")
	store.queue_free()
	await frames(2)
	var settings := SettingsScreen.new()
	settings.theme = UiKit.make_theme()
	add_child(settings)
	await frames(4)
	var ss: ScrollContainer = settings._scroll
	var q := ss.get_global_rect().get_center()
	await drag(q, q + Vector2(0, -300))
	await frames(2)
	check(ss.scroll_vertical > 100, "Ajustes rolam arrastando (%d)" % ss.scroll_vertical)
	settings.queue_free()
	print("==== ROLAGEM: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)
