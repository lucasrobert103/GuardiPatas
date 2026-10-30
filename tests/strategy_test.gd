extends Node
## Tenta soluções genéricas pela mesma validação do desenho do jogador.
var audit := false
var only_world := 0
var failures := 0
var passed := 0
var shortcuts := 0
var levels_checked := 0


func _ready() -> void:
	Game.persist = false
	for arg in OS.get_cmdline_user_args():
		if arg == "--audit":
			audit = true
		if arg.begins_with("--world="):
			only_world = int(arg.trim_prefix("--world="))
	for index in LevelDB.count():
		var data := LevelDB.get_level(index)
		if only_world > 0 and int(data["world"]) != only_world:
			continue
		levels_checked += 1
		var wins: Array = []
		for probe in probes(data):
			var result := await run_probe(index, data, probe["strokes"])
			if result:
				wins.append(probe["name"])
			if not audit and bool(data.get("strategy_required", false)) and probe["name"] != "circulos_individuais":
				if result:
					failures += 1
				else:
					passed += 1
		if not wins.is_empty():
			shortcuts += 1
		print("ESTRATEGIA %s: %s" % [data["id"], "sem atalho" if wins.is_empty() else ", ".join(wins)])
	if levels_checked == 0:
		failures += 1
		print("FALHOU: nenhuma fase selecionada")
	print("==== ESTRATEGIA: %d ok, %d falhas, %d fases com atalho ====" % [passed, failures, shortcuts])
	get_tree().quit(1 if failures else 0)


func animal_bounds(animal: Dictionary) -> Rect2:
	var cfg: Dictionary = Animal.SPECIES[animal["type"]]
	var half := Vector2(float(cfg["r"]), Animal.half_height(animal["type"]))
	if cfg["shape"] == "hcapsule":
		half.x = float(cfg["h"]) / 2.0
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


func probes(data: Dictionary) -> Array:
	var bounds := animal_bounds(data["animals"][0])
	for animal in data["animals"]:
		bounds = bounds.merge(animal_bounds(animal))
	var result: Array = []
	for pad in [16.0, 42.0, 80.0]:
		result.append({"name": "circulo_%d" % pad, "strokes": [ellipse(bounds, pad)]})
	# Arco genérico apoiado no chão: representa também o círculo cortado pelo terreno.
	for pad in [22.0, 50.0]:
		var radius: float = bounds.size.x / 2.0 + pad
		var floor_y := bounds.end.y + 1.0
		var top_y := bounds.position.y - 30.0
		var ry := maxf(minf(radius, (floor_y - 12.0 - top_y) * 0.75), 20.0)
		var cy := top_y + ry
		var cx := bounds.get_center().x
		var arch := PackedVector2Array([Vector2(cx - radius, floor_y - 12)])
		if cy < floor_y - 16:
			arch.append(Vector2(cx - radius, roundf(cy)))
		for i in range(1, 14):
			var angle := PI + PI * i / 14.0
			arch.append(Vector2(roundf(cx + cos(angle) * radius), roundf(cy + sin(angle) * ry)))
		if cy < floor_y - 16:
			arch.append(Vector2(cx + radius, roundf(cy)))
		arch.append(Vector2(cx + radius, floor_y - 12))
		result.append({"name": "arco_%d" % pad, "strokes": [arch]})
	var separate: Array = []
	for animal in data["animals"]:
		separate.append(ellipse(animal_bounds(animal), 22.0))
	result.append({"name": "circulos_individuais", "strokes": separate})
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
		if level.state != Level.State.DRAWING:
			break
		level.drawer.feed_stroke(stroke)
		await get_tree().physics_frame
	if level.state == Level.State.DRAWING:
		level.start_simulation()
	while level.state == Level.State.RUNNING and level._sim_time < level.survive + 4:
		await get_tree().physics_frame
	var won := level.state == Level.State.WON
	level.queue_free()
	await get_tree().process_frame
	return won
