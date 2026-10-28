extends Node
## Executor de testes headless (sem dependências externas).
##
##   godot --headless --fixed-fps 60 res://tests/test_runner.tscn
##   godot --headless --fixed-fps 60 res://tests/test_runner.tscn -- --level=1-4
##
## Suítes:
##   1. Unitários: LineMath, Scoring, salvamento/progresso.
##   2. Validação do desenho: pontos dentro de obstáculos/zonas proibidas são recusados.
##   3. Fases: cada fase DEVE ser vencida pela solução registrada (mesma validação do
##      dedo + física real) e DEVE ser perdida sem nenhuma linha (não é trivial).
## Sai com código 1 se algo falhar.

var failures := 0
var passed := 0
var only_level := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			only_level = a.substr(8)
	Game.persist = false
	Game.load_save()
	await get_tree().process_frame
	if only_level == "":
		_unit_line_math()
		_unit_scoring()
		_unit_progress()
		await _test_draw_validation()
	await _test_levels()
	print("")
	print("==== RESULTADO: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	if cond:
		passed += 1
	else:
		failures += 1
		print("  FALHOU: ", what)


# ------------------------------------------------------------------ unitários
func _unit_line_math() -> void:
	print("[LineMath]")
	var straight := PackedVector2Array()
	for i in 21:
		straight.append(Vector2(i * 10, 0))
	var s := LineMath.simplify(straight, 1.0)
	check(s.size() == 2, "simplify reduz linha reta a 2 pontos (veio %d)" % s.size())
	check(s[0] == straight[0] and s[1] == straight[20], "simplify preserva as pontas")
	check(is_equal_approx(LineMath.length(straight), 200.0), "length de 200 px")
	var clipped := LineMath.clip_to_length(straight, 55.0)
	check(is_equal_approx(LineMath.length(clipped), 55.0), "clip_to_length respeita o orçamento")
	var zig := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(30, 0)])
	var merged := LineMath.merge_close(zig, 10.0)
	check(merged.size() == 2, "merge_close remove pontos colados (veio %d)" % merged.size())
	var wiggly := PackedVector2Array()
	for i in 400:
		wiggly.append(Vector2(i * 3.0, sin(i * 0.3) * 40.0))
	var prepared := LineMath.prepare_stroke(wiggly, 40)
	check(prepared.size() - 1 <= 40, "prepare_stroke limita a 40 segmentos (veio %d)" % (prepared.size() - 1))
	check(prepared[0] == wiggly[0] and prepared[prepared.size() - 1] == wiggly[wiggly.size() - 1], "prepare_stroke preserva as pontas")
	var c := LineMath.centroid(PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]))
	check(c.is_equal_approx(Vector2(50, 0)), "centroid no meio")


func _unit_scoring() -> void:
	print("[Scoring]")
	check(Scoring.stars_for(0.3, [0.4, 0.7]) == 3, "3 estrelas com pouca tinta")
	check(Scoring.stars_for(0.5, [0.4, 0.7]) == 2, "2 estrelas")
	check(Scoring.stars_for(0.95, [0.4, 0.7]) == 1, "vencer sempre dá 1 estrela")
	check(Scoring.coins_for(0, 3) > Scoring.coins_for(3, 3), "repetir fase dá menos moedas que a primeira vez")
	check(Scoring.coins_for(3, 3) == Scoring.COINS_PER_WIN, "repetir fase dá só o bônus de vitória")


func _unit_progress() -> void:
	print("[Progresso]")
	Game.data = Game._default_data()
	check(Game.is_unlocked(0), "primeira fase liberada")
	check(not Game.is_unlocked(1), "segunda fase trancada no início")
	var first := str(LevelDB.get_level(0)["id"])
	var info := Game.complete_level(first, 2, 0.5, ["capi"])
	check(Game.is_unlocked(1), "vencer libera a próxima")
	check(Game.stars_of(first) == 2, "estrelas registradas")
	check(int(info["coins"]) > 0 and Game.coins() == int(info["coins"]), "moedas creditadas")
	Game.complete_level(first, 1, 0.9, ["capi"])
	check(Game.stars_of(first) == 2, "pior resultado não apaga o melhor")
	check(Game.data["achievements"].has("first_win"), "conquista de primeira vitória")
	check(not Game.buy_item("coroa"), "não compra sem moedas suficientes")
	Game.data["coins"] = 999
	check(Game.buy_item("coroa") and Game.owns("coroa"), "compra cosmético")
	Game.equip("capi", "coroa")
	check(Game.equipped("capi") == "coroa", "equipa cosmético")
	Game.data = Game._default_data()


func _test_draw_validation() -> void:
	print("[Validação do desenho]")
	var data := LevelDB.get_level(LevelDB.index_of("2-6"))
	var lv := Level.new()
	lv.setup(0, data, false)
	add_child(lv)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var d := lv.drawer
	var animal_pos := lv.animals[0].global_position
	check(not d._is_free(Vector2(360, 1100)), "ponto dentro do chão é recusado")
	check(not d._is_free(animal_pos), "ponto em cima do bichinho é recusado")
	check(not d._is_free(Vector2(360, 700)), "ponto na zona proibida é recusado")
	check(d._is_free(Vector2(600, 700)), "ponto livre é aceito")
	# traço que atravessa o bichinho deve parar antes dele
	var through := PackedVector2Array([Vector2(200, animal_pos.y), Vector2(520, animal_pos.y)])
	var ink_before := d.ink_left
	d.feed_stroke(through)
	await get_tree().physics_frame
	if lv.lines.size() > 0:
		var line := lv.lines[0]
		var max_x := -INF
		for p in line.points_local:
			max_x = maxf(max_x, (p + line.position).x)
		check(max_x < animal_pos.x - 20.0, "traço para ao encostar no bichinho (max_x=%.0f)" % max_x)
	else:
		check(false, "traço válido até o obstáculo deveria virar linha")
	check(d.ink_left < ink_before, "tinta é consumida")
	lv.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------ fases
func _test_levels() -> void:
	print("[Fases]")
	for i in LevelDB.count():
		var data := LevelDB.get_level(i)
		var id := str(data["id"])
		if only_level != "" and id != only_level:
			continue
		check(not data.get("solution", []).is_empty(), "%s tem solução registrada" % id)
		var won := await _run_level(i, data, true)
		check(won["state"] == Level.State.WON, "%s: solução vence (estado=%s motivo=%s t=%.1fs linhas=%d)" % [id, won["state_name"], won["reason"], won["time"], won["lines"]])
		var lost := await _run_level(i, data, false)
		check(lost["state"] == Level.State.LOST, "%s: sem linha, perde (estado=%s t=%.1fs)" % [id, lost["state_name"], lost["time"]])
		print("  %s %-22s solução=%s (%.1fs, tinta %.0f%%, %d★)  sem-linha=%s (%.1fs, %s)" % [id, data["name"], won["state_name"], won["time"], won["ink"] * 100.0, won["stars"], lost["state_name"], lost["time"], lost["reason"]])


func _run_level(index: int, data: Dictionary, with_solution: bool) -> Dictionary:
	Game.data = Game._default_data()
	var lv := Level.new()
	lv.setup(index, data, false)
	add_child(lv)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if with_solution:
		for stroke in lv.solution_strokes():
			if lv.state != Level.State.DRAWING:
				break
			lv.drawer.feed_stroke(stroke)
			await get_tree().physics_frame
	if lv.state == Level.State.DRAWING:
		lv.start_simulation()
	var limit := lv.survive + 4.0
	while lv.state == Level.State.RUNNING and lv._sim_time < limit:
		await get_tree().physics_frame
	var names := {Level.State.DRAWING: "DESENHANDO", Level.State.RUNNING: "RODANDO", Level.State.WON: "VENCEU", Level.State.LOST: "PERDEU"}
	var out := {
		"state": lv.state, "state_name": names[lv.state], "reason": lv.lose_reason,
		"time": lv._sim_time, "lines": lv.lines.size(), "ink": lv.ink_used(),
		"stars": int(lv.last_result.get("stars", 0)),
	}
	lv.queue_free()
	await get_tree().process_frame
	return out
