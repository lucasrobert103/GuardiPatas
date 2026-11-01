class_name Missions
## Missões extras de cada fase da campanha (3 por fase), para rejogar:
##   tinta: usar até X% da tinta (X sai da solução registrada, então é sempre possível);
##   dificuldade: vencer no Difícil ou no Extremo (só quando a fase aguenta, ver Difficulty.CAPS);
##   sem dica / de primeira.
## Cada missão cumprida dá +10 moedas uma única vez.

const KINDS := ["ink", "hard", "extreme", "nohint", "first"]
const REWARD := 10


static func for_level(id: String) -> Array:
	var idx := LevelDB.index_of(id)
	if idx < 0:
		return []
	var base := LevelDB.get_level(idx)
	var sol := 0.0
	for st in Level._to_poly_list(base.get("solution", [])):
		sol += LineMath.length(st)
	var ratio := sol / maxf(float(base.get("ink", 800)), 1.0)
	var goal := mini(99, int(ceil(ratio * 100.0)) + 5)
	var out: Array = [{"kind": "ink", "goal": goal, "text": UiKit.tr_text("Use até %d%% da tinta") % goal}]
	var cap := Difficulty.cap(id)
	if cap >= 2 and int(base.get("world", 1)) >= 6:
		out.append({"kind": "extreme", "text": UiKit.tr_text("Vença no Extremo")})
	elif cap >= 1:
		out.append({"kind": "hard", "text": UiKit.tr_text("Vença no Difícil ou no Extremo")})
	else:
		out.append({"kind": "first", "text": UiKit.tr_text("Vença de primeira")})
	out.append({"kind": "nohint", "text": UiKit.tr_text("Vença sem pedir dica")})
	return out


static func done(id: String) -> Array:
	return Game.data["missions"].get(id, [])


static func done_count(id: String) -> int:
	return done(id).size()


static func total_done() -> int:
	var n := 0
	for k in Game.data["missions"]:
		n += (Game.data["missions"][k] as Array).size()
	return n


static func total_possible() -> int:
	return LevelDB.count() * 3


## Confere as missões depois de uma vitória na campanha. Devolve as recém-cumpridas.
static func evaluate(level: Level, info: Dictionary) -> Array:
	var id := str(level.data.get("id", ""))
	var have: Array = done(id).duplicate()
	var fresh: Array = []
	var used := float(info.get("ink_used", 1.0)) * 100.0
	var diff := int(level.data.get("difficulty", 0))
	for m in for_level(id):
		var k: String = m["kind"]
		if have.has(k):
			continue
		var ok := false
		match k:
			"ink": ok = used <= float(m["goal"]) + 0.5
			"hard": ok = diff >= 1
			"extreme": ok = diff >= 2
			"nohint": ok = not level.hint_shown
			"first": ok = level.first_try
		if ok:
			have.append(k)
			fresh.append(k)
	if not fresh.is_empty():
		Game.data["missions"][id] = have
		Game.data["coins"] = Game.coins() + REWARD * fresh.size()
		Game.coins_changed.emit(Game.coins())
	return fresh
