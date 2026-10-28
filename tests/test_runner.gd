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
var only_world := 0
var trace := false
var trace_step := 1.0
var variants := false
var daily_all := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			only_level = a.substr(8)
		if a.begins_with("--world="):
			only_world = int(a.substr(8))
		if a.begins_with("--trace-step="):
			trace_step = float(a.substr(13))
		if a == "--trace":
			trace = true
		if a == "--variants":
			variants = true
		if a == "--daily-all":
			daily_all = true
	Game.persist = false
	Game.load_save()
	await get_tree().process_frame
	if daily_all:
		await _test_daily_all()
		print("")
		print("==== RESULTADO: %d ok, %d falhas ====" % [passed, failures])
		get_tree().quit(1 if failures > 0 else 0)
		return
	if only_level == "" and only_world == 0:
		_unit_medals_daily()
		_unit_line_math()
		_unit_scoring()
		_unit_progress()
		_unit_audio()
		await _test_draw_validation()
	await _test_levels()
	if only_level == "" and only_world == 0:
		await _test_daily()
	print("")
	print("==== RESULTADO: %d ok, %d falhas ====" % [passed, failures])
	await get_tree().process_frame
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


func _unit_audio() -> void:
	print("[Áudio]")
	for s in Sfx.SOUNDS:
		check(ResourceLoader.exists(Sfx.SFX_DIR + s + ".wav"), "som %s importado" % s)
	var loops := ["draw_loop", "buzz_bee", "buzz_mosquito", "moth_flutter", "music_menu", "music_boss"]
	loops.append_array(Sfx.WORLD_MUSIC.values())
	for s in loops:
		var st: AudioStreamWAV = load(Sfx.SFX_DIR + s + ".wav")
		check(st != null and st.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s vem com loop do WAV" % s)
	for w in range(1, 9):
		var lv := LevelDB.get_level(LevelDB.index_of("%d-1" % w))
		check(Sfx.level_track(lv) == Sfx.WORLD_MUSIC[w], "mundo %d tem trilha própria" % w)
	check(Sfx.level_track(LevelDB.get_level(LevelDB.index_of("5-6"))) == "music_boss", "fase de chefão usa a trilha de chefão")


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
		if only_world != 0 and int(data["world"]) != only_world:
			continue
		check(not data.get("solution", []).is_empty(), "%s tem solução registrada" % id)
		var won := await _run_level(i, data, true)
		check(won["state"] == Level.State.WON, "%s: solução vence (estado=%s motivo=%s t=%.1fs linhas=%d)" % [id, won["state_name"], won["reason"], won["time"], won["lines"]])
		check(won["paw"], "%s: a solução passa pela pegada dourada" % id)
		var lost := await _run_level(i, data, false)
		check(lost["state"] == Level.State.LOST, "%s: sem linha, perde (estado=%s t=%.1fs)" % [id, lost["state_name"], lost["time"]])
		var naive_txt := ""
		if not data.get("naive", []).is_empty():
			if trace:
				print("    --- ingênuo ---")
			var nv := await _run_level(i, data, true, Level._to_poly_list(data["naive"]))
			check(nv["state"] == Level.State.LOST, "%s: o 'círculo ingênuo' NÃO pode vencer (estado=%s motivo=%s)" % [id, nv["state_name"], nv["reason"]])
			naive_txt = "  ingênuo=%s(%s)" % [nv["state_name"], nv["reason"]]
		if variants:
			await _run_variants(i, data)
		print("  %s %-22s solução=%s (%.1fs, tinta %.0f%%, %d★)  sem-linha=%s (%.1fs, %s)%s" % [id, data["name"], won["state_name"], won["time"], won["ink"] * 100.0, won["stars"], lost["state_name"], lost["time"], lost["reason"], naive_txt])


## Desafio do Dia: 14 dias seguidos a partir de uma data fixa — a solução da fase base tem
## que continuar vencendo com a regra do dia.
func _test_daily() -> void:
	print("[Desafio do Dia]")
	var pool := Daily.pool(true)
	var key := "2026-11-01"
	var seen := {}
	for k in 14:
		var p := Daily.pick(key, pool)
		var d := Daily.build(key, int(p["index"]), str(p["mod"]["id"]))
		seen[str(p["mod"]["id"])] = true
		var r := await _run_level(-1, d, true)
		check(r["state"] == Level.State.WON, "desafio %s (%s + %s) vence com a solução (motivo=%s)" % [key, d["base_id"], d["daily_mod"], r["reason"]])
		print("  %s  %-5s %-11s %s" % [key, d["base_id"], d["daily_mod"], r["state_name"]])
		key = _next_key(key)
	check(seen.size() >= 3, "o desafio varia as regras ao longo dos dias (%d regras)" % seen.size())


func _next_key(key: String) -> String:
	var t := Time.get_unix_time_from_datetime_string(key + "T12:00:00")
	return Time.get_date_string_from_unix_time(t + 86400)


## Varredura completa (opcional, --daily-all): toda fase elegível × toda regra.
func _test_daily_all() -> void:
	print("[Desafio do Dia — todas as combinações]")
	for i in Daily.pool(true):
		for m in Daily.mods_for(i):
			var d := Daily.build("2026-01-01", i, str(m["id"]))
			var r := await _run_level(-1, d, true)
			check(r["state"] == Level.State.WON, "%s + %s (motivo=%s)" % [d["base_id"], m["id"], r["reason"]])


func _unit_medals_daily() -> void:
	print("[Medalhas e Desafio do Dia]")
	Game.data = Game._default_data()
	var id := str(LevelDB.get_level(0)["id"])
	check(Game.never_failed(id), "fase nova não tem derrotas")
	Game.record_loss(id)
	check(not Game.never_failed(id), "derrota fica registrada na fase")
	check(not Game.is_completed(id), "registrar derrota não conta como fase vencida")
	var info := Game.complete_level(id, 3, 0.5, ["capi"], "", {"paw": true, "first": false, "quick": true})
	check(info["new_medals"] == ["paw", "quick"], "medalhas novas são informadas (%s)" % [info["new_medals"]])
	check(Game.has_medal(id, "paw") and not Game.has_medal(id, "first"), "medalhas ficam salvas por fase")
	var again := Game.complete_level(id, 3, 0.5, ["capi"], "", {"paw": true})
	check(again["new_medals"].is_empty(), "medalha repetida não dá prêmio de novo")
	check(Daily.previous_key("2026-03-01") == "2026-02-28", "dia anterior atravessa o mês")
	var c0 := Game.coins()
	var d1 := Game.complete_daily("2026-03-01")
	check(d1["streak"] == 1 and Game.coins() == c0 + Daily.reward(1), "primeiro desafio dá prêmio")
	var d1b := Game.complete_daily("2026-03-01")
	check(d1b["repeat"] and d1b["coins"] == 0, "repetir no mesmo dia não dá prêmio")
	var d2 := Game.complete_daily("2026-03-02")
	check(d2["streak"] == 2, "dias seguidos aumentam a sequência")
	var d4 := Game.complete_daily("2026-03-04")
	check(d4["streak"] == 1, "pular um dia zera a sequência")
	check(Game.data["achievements"].has("daily_1"), "conquista do primeiro desafio")
	var a := Daily.pick("2026-05-05", Daily.pool(true))
	var b := Daily.pick("2026-05-05", Daily.pool(true))
	check(a["index"] == b["index"] and a["mod"]["id"] == b["mod"]["id"], "mesmo dia = mesmo desafio")
	Game.data = Game._default_data()


## Relatório (não obrigatório): traços "parecidos" com a solução ainda vencem?
func _run_variants(index: int, data: Dictionary) -> void:
	var specs := [["mais largo", Vector2(1.15, 1.0), Vector2.ZERO], ["mais alto", Vector2(1.0, 1.15), Vector2(0, -8)], ["deslocado", Vector2.ONE, Vector2(12, -6)], ["apertado", Vector2(0.94, 0.95), Vector2.ZERO]]
	var line := "    variações %s:" % data["id"]
	for sp in specs:
		var strokes: Array = []
		for st in Level.new()._to_poly_list(data.get("solution", [])):
			var pts: PackedVector2Array = st
			var c := LineMath.centroid(pts)
			var bottom := -INF
			for p in pts:
				bottom = maxf(bottom, p.y)
			var out := PackedVector2Array()
			for p in pts:
				var q: Vector2 = Vector2(c.x + (p.x - c.x) * sp[1].x, bottom + (p.y - bottom) * sp[1].y) + sp[2]
				out.append(q)
			strokes.append(out)
		if trace:
			print("    variante ", sp[0])
		var r := await _run_level(index, data, true, strokes)
		line += "  %s=%s" % [sp[0], "ok" if r["state"] == Level.State.WON else "x(%s)" % r["state_name"]]
	print(line)


func _trace(lv: Level, with_solution: bool) -> void:
	var parts: Array = []
	for i in lv.insects:
		if is_instance_valid(i):
			parts.append("%s(%.0f,%.0f v%.0f,%.0f)" % [i.kind, i.global_position.x, i.global_position.y, i.linear_velocity.x, i.linear_velocity.y])
	for c in lv.props:
		if is_instance_valid(c):
			parts.append("caixa(%.0f,%.0f hp%.1f)" % [c.global_position.x, c.global_position.y, c.hp])
	for l in lv.lines:
		var xs := Vector2(INF, -INF)
		for q in l.points_local:
			xs = Vector2(minf(xs.x, q.x + l.position.x), maxf(xs.y, q.x + l.position.x))
		parts.append("linha(%.0f,%.0f rot%.2f pts%d x%.0f..%.0f)" % [l.global_position.x, l.global_position.y, l.rotation, l.points_local.size(), xs.x, xs.y])
	for a in lv.animals:
		parts.append("%s(%.0f,%.0f)" % [a.species, a.global_position.x, a.global_position.y])
	print("    [%s t=%.0f] %s" % ["sol" if with_solution else "nada", lv._sim_time, ", ".join(parts)])


func _run_level(index: int, data: Dictionary, with_solution: bool, custom: Array = []) -> Dictionary:
	Game.data = Game._default_data()
	var lv := Level.new()
	lv.setup(index, data, false)
	add_child(lv)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if with_solution:
		var strokes := custom if not custom.is_empty() else lv.solution_strokes()
		lv.drawer.debug_log = trace
		for stroke in strokes:
			if lv.state != Level.State.DRAWING:
				break
			lv.drawer.feed_stroke(stroke)
			await get_tree().physics_frame
	if lv.state == Level.State.DRAWING:
		lv.start_simulation()
	var limit := lv.survive + 4.0
	var next_trace := 0.0
	while lv.state == Level.State.RUNNING and lv._sim_time < limit:
		await get_tree().physics_frame
		if trace and lv._sim_time >= next_trace:
			next_trace += trace_step
			_trace(lv, with_solution)
	var names := {Level.State.DRAWING: "DESENHANDO", Level.State.RUNNING: "RODANDO", Level.State.WON: "VENCEU", Level.State.LOST: "PERDEU"}
	var out := {
		"state": lv.state, "state_name": names[lv.state], "reason": lv.lose_reason,
		"time": lv._sim_time, "lines": lv.lines.size(), "ink": lv.ink_used(),
		"stars": int(lv.last_result.get("stars", 0)),
		"paw": lv.paw_got,
	}
	lv.queue_free()
	await get_tree().process_frame
	return out
