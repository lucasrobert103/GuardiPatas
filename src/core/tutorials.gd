class_name Tutorials
## Tutorial jogável dos poderes: na primeira fase em que um inseto aparece, um cartão mostra
## uma DEMONSTRAÇÃO ao vivo (o mesmo motor de física, numa janelinha) e oferece um TREINO
## curtinho antes da fase de verdade.

## A abelha é o primeiro inseto do jogo (a fase 1 já ensina).
const SKIP := ["bee"]
const SEA := ["jellyfish", "puffer", "drillfish"]
const GROUND := 1000.0


## Insetos desta fase que o jogador ainda não conhece (nem viu em fase já vencida).
static func new_kinds(data: Dictionary) -> Array:
	var out: Array = []
	var kinds: Array = []
	for n in data.get("nests", []):
		kinds.append(str(n.get("insect", "")))
	for b in data.get("bosses", []):
		if str(b.get("kind", "")) == "termite_queen":
			kinds.append("termite_queen")
	for k in kinds:
		if k == "" or SKIP.has(k) or out.has(k) or Game.data["seen_insects"].has(k):
			continue
		if _seen_in_completed(k):
			continue
		out.append(k)
	return out


static func _seen_in_completed(kind: String) -> bool:
	for i in LevelDB.count():
		var lv := LevelDB.get_level(i)
		if not Game.is_completed(str(lv["id"])):
			continue
		for n in lv.get("nests", []):
			if str(n.get("insect", "")) == kind:
				return true
	return false


static func mark_seen(kinds: Array) -> void:
	for k in kinds:
		if not Game.data["seen_insects"].has(k):
			Game.data["seen_insects"].append(k)
	Game.save()


## Arco simples sobre a capivara (o mesmo desenho dos abrigos da campanha).
static func dome(cx: float, half_w: float, top: float, pad: float = 24.0, apex_gap: float = 30.0) -> Array:
	var hw := half_w + pad
	var y_leg := GROUND - 12.0
	var y_top := top - apex_gap
	var ry := maxf(minf(hw, (y_leg - y_top) * 0.75), 20.0)
	var y_c := y_top + ry
	var pts: Array = [[cx - hw, y_leg]]
	if y_c < y_leg - 4:
		pts.append([cx - hw, roundf(y_c)])
	for i in range(1, 14):
		var a := PI + PI * i / 14.0
		pts.append([roundf(cx + cos(a) * hw), roundf(y_c + sin(a) * ry)])
	if y_c < y_leg - 4:
		pts.append([cx + hw, roundf(y_c)])
	pts.append([cx + hw, y_leg])
	return pts


static func _nest_for(kind: String, count: int) -> Dictionary:
	if kind == "termite_queen":
		return {}
	var flyer := Nest.FLYERS.has(kind) or SEA.has(kind) or kind == "spider"
	if flyer:
		return {"insect": kind, "pos": [600, 420], "count": count, "interval": 1.0, "delay": 0.3}
	return {"insect": kind, "pos": [110, GROUND - 20.0], "count": count, "interval": 1.4, "delay": 0.2}


## Cena da demonstração: a Capitu com um abrigo já desenhado e o inseto agindo nele.
static func demo_level(kind: String) -> Dictionary:
	var d := _base(kind, "demo")
	d["solution"] = [dome(360, 56, 939)]
	d["survive"] = 7.0
	d["ink"] = 99999
	if kind == "termite_queen":
		d["bosses"] = [{"kind": "termite_queen", "pos": [620, 1000], "tunnels": [[200, 1.5], [520, 3.0]], "insect": "termite", "count": 3, "interval": 0.5}]
	return d


## Treino: a mesma cena, agora o jogador desenha, com tinta de sobra e poucos insetos.
static func practice_level(kind: String, return_index: int) -> Dictionary:
	var d := _base(kind, "practice")
	d["survive"] = 7.0
	d["ink"] = 1400
	d["return_index"] = return_index
	d["tip"] = "Treino: %s" % UiKit.tr_text(str(Cast.INSECTS.get(kind, {}).get("desc", "")))
	d["name"] = UiKit.tr_text("Treino: %s") % UiKit.tr_text(str(Cast.INSECTS.get(kind, {}).get("name", kind)))
	if kind == "termite_queen":
		d["bosses"] = [{"kind": "termite_queen", "pos": [620, 1000], "tunnels": [[274, 2.0], [446, 3.5]], "insect": "termite", "count": 3, "interval": 0.6}]
	return d


static func _base(kind: String, mode: String) -> Dictionary:
	var nests: Array = []
	var n := _nest_for(kind, 2 if kind in ["wasp", "beetle", "mantis", "rollbug", "bombardier", "cicada", "dragonfly"] else 3)
	if not n.is_empty():
		nests.append(n)
	var static_ink := kind == "ghost"
	return {
		"id": "tutorial-" + kind, "mode": mode, "world": 1, "name": str(Cast.INSECTS.get(kind, {}).get("name", kind)),
		"tip": str(Cast.INSECTS.get(kind, {}).get("desc", "")), "ink": 1400, "survive": 7.0, "stars": [0.6, 0.8], "strokes": 1,
		"terrain": [{"poly": [[-400, GROUND], [1120, GROUND], [1120, 1800], [-400, 1800]], "style": "ground"}],
		"rocks": [], "props": [], "nodraw": [], "bosses": [],
		"animals": [{"type": "capi", "pos": [360, 969], "flip": false}], "nests": nests, "solution": [],
		"ink_mode": "static" if static_ink else "normal", "underwater": SEA.has(kind),
	}
