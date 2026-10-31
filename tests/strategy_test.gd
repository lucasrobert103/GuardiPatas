extends Node
## Tenta soluções genéricas pela mesma validação do desenho do jogador.
## --level=6-5 / --world=6 filtram o teste; --audit só relata resultados.
## --extended acrescenta paredes, teto curto e arcos largos aos padrões obrigatórios.
## --omissions remove um traço da solução por vez. Só os índices declarados em
## critical_strokes são negativos obrigatórios; outras omissões são diagnósticas.
var audit := false
var extended := false
var omissions := false
var only_world := 0
var only_level := ""
var failures := 0
var passed := 0
var shortcuts := 0
var levels_checked := 0
var _last_probe_info: Dictionary = {}


func _ready() -> void:
	Game.persist = false
	for arg in OS.get_cmdline_user_args():
		if arg == "--audit": audit = true
		if arg == "--extended": extended = true
		if arg == "--omissions": omissions = true
		if arg.begins_with("--world="): only_world = int(arg.trim_prefix("--world="))
		if arg.begins_with("--level="): only_level = arg.trim_prefix("--level=")
	for index in LevelDB.count():
		var data := LevelDB.get_level(index)
		if only_world > 0 and int(data["world"]) != only_world: continue
		if not only_level.is_empty() and str(data["id"]) != only_level: continue
		levels_checked += 1
		var wins: Array[String] = []
		for probe in probes(data):
			var result := await run_probe(index, data, probe["strokes"])
			if result: wins.append(probe["name"])
			if not audit and bool(probe.get("required", false)):
				if result:
					failures += 1
					print("FALHOU: %s · %s venceu (traços=%d, tinta=%.0f%%, t=%.1fs)" % [data["id"], probe["name"], _last_probe_info["lines"], _last_probe_info["ink"] * 100, _last_probe_info["time"]])
				else:
					passed += 1
		if not wins.is_empty(): shortcuts += 1
		print("ESTRATEGIA %s: %s" % [data["id"], "sem atalho" if wins.is_empty() else ", ".join(wins)])
	if levels_checked == 0:
		failures += 1
		print("FALHOU: nenhuma fase selecionada")
	print("==== ESTRATEGIA: %d ok, %d falhas, %d fases com atalho ====" % [passed, failures, shortcuts])
	get_tree().quit(1 if failures else 0)


func animal_bounds(animal: Dictionary) -> Rect2:
	var cfg: Dictionary = Animal.SPECIES[animal["type"]]
	var half := Vector2(float(cfg["r"]), Animal.half_height(animal["type"]))
	if cfg["shape"] == "hcapsule": half.x = float(cfg["h"]) / 2.0
	var position := Vector2(animal["pos"][0], animal["pos"][1])
	return Rect2(position - half, half * 2)


func ellipse(bounds: Rect2, pad: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var center := bounds.get_center()
	var radius := bounds.size / 2.0 + Vector2.ONE * pad
	for i in 49:
		var angle := -PI / 2.0 + TAU * i / 48.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func arch(bounds: Rect2, pad: float) -> PackedVector2Array:
	var radius: float = bounds.size.x / 2.0 + pad
	var floor_y := bounds.end.y + 1.0
	var top_y := bounds.position.y - 30.0
	var ry := maxf(minf(radius, (floor_y - 12.0 - top_y) * 0.75), 20.0)
	var cy := top_y + ry
	var cx := bounds.get_center().x
	var points := PackedVector2Array([Vector2(cx - radius, floor_y - 12)])
	if cy < floor_y - 16: points.append(Vector2(cx - radius, roundf(cy)))
	for i in range(1, 14):
		var angle := PI + PI * i / 14.0
		points.append(Vector2(roundf(cx + cos(angle) * radius), roundf(cy + sin(angle) * ry)))
	if cy < floor_y - 16: points.append(Vector2(cx + radius, roundf(cy)))
	points.append(Vector2(cx + radius, floor_y - 12))
	return points


func probes(data: Dictionary) -> Array:
	var bounds := animal_bounds(data["animals"][0])
	for animal in data["animals"]: bounds = bounds.merge(animal_bounds(animal))
	var required := bool(data.get("strategy_required", false))
	var result: Array = []
	for pad in [16.0, 42.0, 80.0]:
		result.append({"name": "circulo_%d" % pad, "strokes": [ellipse(bounds, pad)], "required": required})
	for pad in [22.0, 50.0]:
		result.append({"name": "arco_%d" % pad, "strokes": [arch(bounds, pad)], "required": required})
	var separate: Array = []
	for animal in data["animals"]: separate.append(ellipse(animal_bounds(animal), 22.0))
	result.append({"name": "circulos_individuais", "strokes": separate, "required": bool(data.get("reject_individual_circles", false))})
	if extended or bool(data.get("reject_double_arches", false)):
		for probe in extended_probes(bounds):
			if bool(data.get("reject_double_arches", false)) and str(probe["name"]).begins_with("arcos_duplos_"):
				probe["required"] = true
			if extended or bool(probe.get("required", false)): result.append(probe)
	if omissions or not data.get("critical_strokes", []).is_empty():
		result.append_array(omission_probes(data))
	return result


func extended_probes(bounds: Rect2) -> Array:
	# Diagnóstico: um teto curto/paredinha pode ser uma alternativa válida numa
	# fase de apoio. Não reprovar desenhos legítimos só por terem forma simples.
	var result: Array = []
	for pad in [120.0, 160.0]:
		result.append({"name": "arco_%d" % pad, "strokes": [arch(bounds, pad)]})
		result.append({"name": "arcos_duplos_%d" % pad, "strokes": [arch(bounds, 22), arch(bounds, pad)]})
	var left := bounds.position.x - 28
	var right := bounds.end.x + 28
	var top := bounds.position.y - 26
	var floor_y := bounds.end.y - 10
	result.append({"name": "teto_curto", "strokes": [PackedVector2Array([Vector2(left, top), Vector2(right, top)])]})
	result.append({"name": "parede_esquerda", "strokes": [PackedVector2Array([Vector2(left, top), Vector2(left, floor_y)])]})
	result.append({"name": "parede_direita", "strokes": [PackedVector2Array([Vector2(right, top), Vector2(right, floor_y)])]})
	return result


func omission_probes(data: Dictionary) -> Array:
	var solution: Array = Level._to_poly_list(data.get("solution", []))
	var critical: Array = data.get("critical_strokes", [])
	for entry in critical:
		if not (entry is int or entry is float) or int(entry) < 0 or int(entry) >= solution.size() or float(entry) != float(int(entry)):
			failures += 1
			print("FALHOU: %s critical_strokes contém índice inválido: %s" % [data["id"], entry])
	var result: Array = []
	for removed in solution.size():
		var strokes: Array = []
		for i in solution.size():
			if i != removed: strokes.append(solution[i])
		var required := false
		for entry in critical:
			if (entry is int or entry is float) and int(entry) == removed: required = true
		result.append({"name": "sem_traco_%d" % (removed + 1), "strokes": strokes, "required": required})
	return result


func run_probe(index: int, data: Dictionary, strokes: Array) -> bool:
	seed(44199 + index)
	Game.data = Game._default_data()
	var level := Level.new()
	level.setup(index, data, false)
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for stroke in strokes:
		if level.state != Level.State.DRAWING: break
		level.drawer.feed_stroke(stroke)
		await get_tree().physics_frame
	if level.state == Level.State.DRAWING: level.start_simulation()
	while level.state == Level.State.RUNNING and level._sim_time < level.survive + 4:
		await get_tree().physics_frame
	var won := level.state == Level.State.WON
	_last_probe_info = {"lines": level.lines.size(), "ink": level.ink_used(), "time": level._sim_time}
	level.queue_free()
	await get_tree().process_frame
	return won
