class_name Infinite
## Modo Infinito: fases geradas sem parar a partir de uma semente, cada vez mais difíceis.
## Cada fase sai de um MOLDE da campanha (arco, buracos ao lado, gruta com tampa, abrigo
## travado em pedras, dois amigos) junto com a solução que o molde garante. Antes de
## aparecer, a fase é SIMULADA escondida (InfiniteValidator): a solução tem que vencer e,
## sem linha, tem que perder. Se falhar, outra variação é sorteada.
## Três corações por corrida; perder custa um coração e repete a fase.

const GROUND := 1000.0
const HEARTS := 3
const FLYERS_BY_STAGE := [
	[1, ["bee", "mosquito"]],
	[4, ["wasp", "fly", "ladybug", "moth"]],
	[8, ["firefly", "ninja", "dragonfly"]],
	[12, ["broca", "cicada", "aphid"]],
]
const WALKERS_BY_STAGE := [
	[1, ["ant"]],
	[5, ["termite", "cricket", "crab"]],
	[9, ["leafcutter", "beetle"]],
	[14, ["rollbug", "mantis", "bombardier"]],
]
const ANIMALS := ["capi", "brasa", "pingo", "nino", "tuca", "gelinho", "nuvem", "kiko", "tata", "pompom", "patinha", "fofa",
	"zeca", "mel", "fiapo", "bolota", "plim", "duda", "nhoque"]

## Corrida em andamento (só na memória; o recorde fica no save).
static var run := {}


static func start_run() -> void:
	run = {"seed": int(Time.get_unix_time_from_system()) % 1000003, "stage": 1, "hearts": HEARTS, "coins": 0, "variant": 0}
	Game.data["infinite"]["runs"] = int(Game.data["infinite"]["runs"]) + 1
	Game.save()


static func active() -> bool:
	return not run.is_empty() and int(run.get("hearts", 0)) > 0


static func best() -> int:
	return int(Game.data["infinite"].get("best", 0))


## Fase vencida: soma, sobe o recorde, dá moedas (e um baú a cada 5 fases).
static func cleared() -> Dictionary:
	var stage := int(run["stage"])
	var coins := 4 + mini(stage, 30)
	var chest := stage % 5 == 0
	if chest:
		coins += 40
		Treats.grant(Treats.ORDER[(stage / 5) % Treats.ORDER.size()], 2)
	Game.data["coins"] = Game.coins() + coins
	run["coins"] = int(run["coins"]) + coins
	var record := stage > best()
	if record:
		Game.data["infinite"]["best"] = stage
	Game.data["infinite"]["cleared"] = int(Game.data["infinite"]["cleared"]) + 1
	run["stage"] = stage + 1
	run["variant"] = 0
	Game._check_achievements(0, 1.0)
	Game.save()
	Game.coins_changed.emit(Game.coins())
	return {"coins": coins, "chest": chest, "record": record, "stage": stage}


static func failed() -> int:
	run["hearts"] = int(run["hearts"]) - 1
	return int(run["hearts"])


# ------------------------------------------------------------------ gerador
static func _rng(stage: int, variant: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash("guardipatas-infinito-%d-%d-%d" % [int(run.get("seed", 1)), stage, variant])
	return r


static func _pool(table: Array, stage: int) -> Array:
	var out: Array = []
	for row in table:
		if stage >= int(row[0]):
			out.append_array(row[1])
	return out


static func half_w(sp: String) -> float:
	var cfg: Dictionary = Animal.SPECIES[sp]
	if str(cfg["shape"]) == "hcapsule":
		return float(cfg["h"]) * 0.5
	return float(cfg["r"])


static func animal(sp: String, x: float, floor_y: float = GROUND) -> Dictionary:
	return {"type": sp, "pos": [x, floor_y - Animal.half_height(sp) - 1.0], "flip": x > 360.0}


static func dome_over(sp: String, x: float, floor_y: float = GROUND, pad: float = 24.0, apex_gap: float = 30.0) -> Array:
	var top := floor_y - 1.0 - 2.0 * Animal.half_height(sp)
	var d := Tutorials.dome(x, half_w(sp), top, pad, apex_gap)
	if floor_y != GROUND:
		for p in d:
			if p[1] == GROUND - 12.0:
				p[1] = floor_y - 12.0
	return d


static func _len(stroke: Array) -> float:
	var t := 0.0
	for i in range(1, stroke.size()):
		t += Vector2(stroke[i][0], stroke[i][1]).distance_to(Vector2(stroke[i - 1][0], stroke[i - 1][1]))
	return t


## Pezinhos nas pontas que caem em cima de buracos (cobre os dois lados da boca).
static func _cover(solution: Array, holes: Array, animals: Array) -> void:
	for st in solution:
		for end in [0, -1]:
			var p: Array = st[end]
			for h in holes:
				if Vector2(p[0], p[1]).distance_to(Vector2(h[0], h[1] - 8.0)) < 18.0:
					var friend: Dictionary = animals[0]
					for a in animals:
						if absf(float(a["pos"][0]) - float(h[0])) < absf(float(friend["pos"][0]) - float(h[0])):
							friend = a
					var outward := -1.0 if float(h[0]) < float(friend["pos"][0]) else 1.0
					var outside := [float(h[0]) + outward * 18.0, p[1]]
					var inside := [float(h[0]) - outward * 8.0, p[1]]
					if end == 0:
						st.remove_at(0)
						st.insert(0, inside)
						st.insert(0, outside)
					else:
						st.remove_at(st.size() - 1)
						st.append(inside)
						st.append(outside)
					break


static func _hive(kind: String, x: float, y: float, count: int, interval: float, delay: float) -> Dictionary:
	return {"insect": kind, "pos": [x, y], "count": count, "interval": interval, "delay": delay}


static func _mound(kind: String, x: float, count: int, interval: float, delay: float) -> Dictionary:
	return {"insect": kind, "pos": [x, GROUND - 20.0], "count": count, "interval": interval, "delay": delay}


static func _hole(kind: String, x: float, count: int, interval: float, delay: float) -> Dictionary:
	return {"insect": kind, "pos": [x, GROUND], "count": count, "interval": interval, "delay": delay, "hole": true}


## Gera a fase `stage` (variação `variant` quando a anterior não passou na validação).
static func generate(stage: int, variant: int = 0) -> Dictionary:
	var r := _rng(stage, variant)
	var flyers := _pool(FLYERS_BY_STAGE, stage)
	var walkers := _pool(WALKERS_BY_STAGE, stage)
	var power := minf(1.0, stage / 30.0)            # 0 → 1 ao longo de 30 fases
	var count_k := 1.0 + power * 0.9
	var gap_k := 1.0 - power * 0.35
	var templates := ["dome", "dome"]
	if stage >= 3: templates.append("holes")
	if stage >= 5: templates.append("pocket")
	if stage >= 7: templates.append("braced")
	if stage >= 6: templates.append("two")
	if stage >= 10: templates.append("holes")
	var t: String = templates[r.randi_range(0, templates.size() - 1)]
	var animals: Array = []
	var nests: Array = []
	var solution: Array = []
	var terrain: Array = [{"poly": [[-400, GROUND], [1120, GROUND], [1120, 1800], [-400, 1800]], "style": "ground"}]
	var rocks: Array = []
	var strokes := 1
	var ink_mode := "normal"
	var sp: String = ANIMALS[r.randi_range(0, ANIMALS.size() - 1)]
	var x := float(r.randi_range(250, 470))
	var side := 1.0 if r.randf() < 0.5 else -1.0
	var tall := sp == "plim"
	var apex := 96.0 if tall else 34.0
	match t:
		"dome", "braced":
			animals.append(animal(sp, x))
			solution.append(dome_over(sp, x, GROUND, 30.0, apex))
			if t == "braced":
				var st: Array = solution[0]
				var off := 18.0 + 7.0 + 22.0 + 3.0
				rocks = [{"pos": [float(st[0][0]) - off, GROUND - 22.0], "r": 22}, {"pos": [float(st[-1][0]) + off, GROUND - 22.0], "r": 22}]
				var heavy: Array = ["beetle", "cicada", "mantis", "rollbug"].filter(func(k): return walkers.has(k) or flyers.has(k))
				if not heavy.is_empty():
					var hk: String = heavy[r.randi_range(0, heavy.size() - 1)]
					nests.append(_hive(hk, 360.0 - side * 260.0, 330.0, 2, 2.0, 0.6) if Nest.FLYERS.has(hk) else _mound(hk, 360.0 - side * 300.0, 2, 2.0, 0.6))
		"holes":
			animals.append(animal(sp, x))
			var hw := half_w(sp)
			var wk: String = walkers[r.randi_range(0, walkers.size() - 1)]
			if wk in ["beetle", "rollbug", "mantis", "bombardier"]:
				wk = "ant"
			for hx in [x - hw - 30.0, x + hw + 30.0]:
				nests.append(_hole(wk, hx, int(3 + power * 3), 0.8 * gap_k, 0.4))
			solution.append(dome_over(sp, x, GROUND, 30.0, apex))
		"pocket":
			var pw := half_w(sp) * 2.0 + 18.0
			var x0 := x - pw * 0.5
			var x1 := x + pw * 0.5
			var top := GROUND - 2.0 * Animal.half_height(sp) - 40.0
			terrain.append({"poly": [[x0 - 60, top], [x0, top], [x0, GROUND], [x0 - 60, GROUND]], "style": "stone"})
			terrain.append({"poly": [[x1, top], [x1 + 60, top], [x1 + 60, GROUND], [x1, GROUND]], "style": "stone"})
			animals.append(animal(sp, x))
			solution.append([[x0 - 14, top - 14], [roundf(x), top - 14], [x1 + 14, top - 14]])
			ink_mode = "static" if r.randf() < 0.5 else "normal"
		"two":
			var sp2: String = ANIMALS[r.randi_range(0, ANIMALS.size() - 1)]
			animals.append(animal(sp, 190.0))
			animals.append(animal(sp2, 530.0))
			solution.append(dome_over(sp, 190.0, GROUND, 30.0, 96.0 if sp == "plim" else 34.0))
			solution.append(dome_over(sp2, 530.0, GROUND, 30.0, 96.0 if sp2 == "plim" else 34.0))
			strokes = 2
	# enxame principal (voadores) + reforços conforme a fase
	var base_count := int(round((4 + mini(stage, 10) * 0.4) * count_k))
	var fk: String = flyers[r.randi_range(0, flyers.size() - 1)]
	nests.append(_hive(fk, 360.0 + side * 250.0, 330.0, base_count, 0.42 * gap_k, 0.4))
	if stage >= 4:
		var fk2: String = flyers[r.randi_range(0, flyers.size() - 1)]
		nests.append(_hive(fk2, 360.0 - side * 250.0, 330.0, int(base_count * 0.6), 0.5 * gap_k, 1.2))
	if stage >= 8 and t != "pocket" and r.randf() < 0.6:
		nests.append(_mound("ant", 360.0 - side * 320.0, int(3 + power * 4), 0.7 * gap_k, 0.8))
	var total := 0
	for n in nests:
		total += int(n["count"])
	while total > 40:
		for n in nests:
			if int(n["count"]) > 2 and total > 40:
				n["count"] = int(n["count"]) - 1
				total -= 1
	var holes: Array = []
	for n in nests:
		if n.get("hole", false):
			holes.append(n["pos"])
	if not holes.is_empty():
		_cover(solution, holes, animals)
	var length := 0.0
	for st in solution:
		length += _len(st)
	var ratio := 0.6 + power * 0.28
	var world := 1 + (int((stage - 1) / 5) % 14)
	return {
		"id": "infinito-%d" % stage, "mode": "infinite", "stage": stage, "world": world,
		"name": UiKit.tr_text("Infinito · Fase %d") % stage, "tip": UiKit.tr_text("Quantas você consegue passar seguidas?"),
		"ink": int(ceil(length / ratio / 5.0) * 5.0), "survive": 8.0 + minf(stage * 0.15, 4.0), "stars": [0.6, 0.8], "strokes": strokes,
		"terrain": terrain, "rocks": rocks, "props": [], "nodraw": [], "bosses": [],
		"animals": animals, "nests": nests, "solution": solution, "ink_mode": ink_mode, "underwater": world == 8,
		"template": t,
	}
