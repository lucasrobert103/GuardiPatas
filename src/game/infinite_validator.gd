class_name InfiniteValidator
extends Node
## Simula uma fase gerada ESCONDIDA (num mundo de física separado, sem desenhar na tela):
## a solução tem que vencer e, sem linha, a fase tem que ser perdida. Roda as duas
## simulações ao mesmo tempo, enquanto o jogador está jogando a fase anterior.

signal done(data: Dictionary, ok: bool)

var data: Dictionary
var _results := {}
var _views: Array[SubViewport] = []
var _levels: Array[Level] = []
var _limit := 1.0


## Quanto das duas simulações já andou (0..1), para a barra de carregamento.
func fraction() -> float:
	if _levels.is_empty():
		return 0.0
	var total := 0.0
	for lv in _levels:
		if not is_instance_valid(lv) or lv.state == Level.State.WON or lv.state == Level.State.LOST:
			total += 1.0
		else:
			total += clampf(lv._sim_time / maxf(_limit, 0.1), 0.0, 1.0)
	return total / _levels.size()


func check(p_data: Dictionary) -> void:
	data = p_data
	_results.clear()
	for with_solution in [true, false]:
		_simulate(with_solution)


func _simulate(with_solution: bool) -> void:
	var view := SubViewport.new()
	view.size = Vector2i(8, 8)
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	view.disable_3d = true
	add_child(view)
	_views.append(view)
	var d := data.duplicate(true)
	d["mode"] = "demo"   # sem recompensas nem estatísticas
	var lv := Level.new()
	lv.setup(-1, d, false)
	lv.set_process_unhandled_input(false)
	view.add_child(lv)
	_levels.append(lv)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if with_solution:
		for st in lv.solution_strokes():
			if lv.state != Level.State.DRAWING:
				break
			lv.drawer.feed_stroke(st)
			await get_tree().physics_frame
	if lv.state == Level.State.DRAWING:
		lv.start_simulation()
	var limit := lv.survive + 2.0
	_limit = limit
	while is_instance_valid(lv) and lv.state == Level.State.RUNNING and lv._sim_time < limit:
		await get_tree().physics_frame
	var won := is_instance_valid(lv) and lv.state == Level.State.WON
	_results[with_solution] = won
	view.queue_free()
	if _results.size() == 2:
		done.emit(data, bool(_results[true]) and not bool(_results[false]))
