class_name InsectIntro
extends SubViewportContainer
## Janelinha com a física rodando de verdade: a Capitu num abrigo e o inseto novo usando o
## poder nele. Recomeça sozinha quando a cena termina (demonstração em loop).

var kind := "bee"
var _view: SubViewport
var _lv: Level
var _busy := false


func _ready() -> void:
	stretch = true
	custom_minimum_size = Vector2(480, 330)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view = SubViewport.new()
	_view.handle_input_locally = false
	_view.physics_object_picking = false
	_view.gui_disable_input = true
	add_child(_view)
	_restart()


func _restart() -> void:
	if _busy or not is_inside_tree():
		return
	_busy = true
	if _lv != null and is_instance_valid(_lv):
		_lv.queue_free()
		await get_tree().process_frame
	_lv = Level.new()
	_lv.setup(-1, Tutorials.demo_level(kind), false)
	_lv.set_process_unhandled_input(false)
	_view.add_child(_lv)
	_lv.camera.position = Vector2(360, 820)
	_lv.camera.zoom = Vector2(0.78, 0.78)
	_lv.drawer.enabled = false
	_lv.result_ready.connect(func(_won: bool, _info: Dictionary):
		get_tree().create_timer(1.0, true).timeout.connect(_restart))
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(_lv):
		_busy = false
		return
	for st in _lv.solution_strokes():
		_lv.drawer.feed_stroke(st)
		await get_tree().physics_frame
	if is_instance_valid(_lv) and _lv.state == Level.State.DRAWING:
		_lv.start_simulation()
	_busy = false


func _exit_tree() -> void:
	if _lv != null and is_instance_valid(_lv):
		_lv.queue_free()
