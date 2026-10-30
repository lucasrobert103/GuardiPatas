extends Node
var failures := 0
var passed := 0


func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)


func make_level(id: String, with_hud: bool = true) -> Level:
	var level := Level.new()
	level.setup(LevelDB.index_of(id), LevelDB.get_level(LevelDB.index_of(id)), with_hud)
	add_child(level)
	return level


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.persist = false
	Game.load_save()
	Game.set_setting("lang", "pt_BR")
	var original_ticks := Engine.physics_ticks_per_second
	var original_scale := Engine.time_scale
	var level := make_level("1-1")
	await get_tree().process_frame
	await get_tree().process_frame
	check(not level.hud.speed_btn.visible, "não acelera durante desenho")
	check(not level.set_simulation_speed(2), "modelo recusa aceleração durante desenho")
	level.start_simulation()
	check(level.hud.speed_btn.visible, "botão disponível após desenho")
	check(not level.set_simulation_speed(3), "recusa velocidade não suportada")
	# Entrada real na GUI, em coordenadas locais do viewport.
	var point := level.hud.speed_btn.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	check(level.simulation_speed == 2 and Engine.time_scale == original_scale * 2, "toque ativa 2x")
	check(Engine.physics_ticks_per_second == original_ticks * 2, "frequência aumenta para manter o passo físico")
	check(level.hud.speed_btn.text.contains("2×"), "botão indica velocidade ativa")
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(is_equal_approx(level.get_physics_process_delta_time(), original_scale / original_ticks), "delta da física preservado em 2x")
	level.hud._open_pause()
	check(Engine.time_scale == original_scale and level.simulation_speed == 1, "pausa restaura velocidade")
	check(not level.set_simulation_speed(2), "não acelera pausado")
	level.hud._close_overlay()
	level.set_simulation_speed(2)
	level.lose("sting")
	check(Engine.time_scale == original_scale and Engine.physics_ticks_per_second == original_ticks, "derrota restaura relógio e física")
	check(not level.hud.speed_btn.visible and not level.set_simulation_speed(2), "resultado não permite acelerar")
	level.queue_free()
	await get_tree().process_frame
	level = make_level("1-1", true)
	level.start_simulation()
	level.set_simulation_speed(2)
	remove_child(level)
	check(Engine.time_scale == original_scale and Engine.physics_ticks_per_second == original_ticks, "sair ou reiniciar restaura velocidade")
	level.queue_free()
	await get_tree().process_frame

	# Soluções reais com gravidade, formigas e ambiente submarino em ambos os ritmos.
	for id in ["1-1", "1-4", "8-7"]:
		var results: Array = []
		for speed in [1, 2]:
			level = make_level(id, false)
			for stroke in level.solution_strokes():
				level.drawer.feed_stroke(stroke)
				await get_tree().physics_frame
			check(level.state == Level.State.RUNNING, "desenho inicia " + id)
			level.set_simulation_speed(speed)
			var frame_limit := 2400
			while level.state == Level.State.RUNNING and frame_limit > 0:
				await get_tree().physics_frame
				frame_limit -= 1
			check(level.state == Level.State.WON, "solução vence %s em %dx" % [id, speed])
			check(Engine.time_scale == original_scale and Engine.physics_ticks_per_second == original_ticks, "vitória restaura velocidade " + id)
			results.append({"state": level.state, "stars": level.last_result.get("stars"), "ink": level.ink_used(), "duration": level._sim_time})
			level.queue_free()
			await get_tree().process_frame
		check(results[0]["state"] == results[1]["state"] and results[0]["stars"] == results[1]["stars"] and is_equal_approx(results[0]["ink"], results[1]["ink"]), "resultado e recompensa iguais em " + id)
		check(absf(results[0]["duration"] - results[1]["duration"]) < 0.04, "cronômetro simulado consistente em " + id)
	print("==== VELOCIDADE: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)
