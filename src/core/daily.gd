class_name Daily
## Desafio do Dia: uma fase já liberada com uma regra especial, sorteada pela data (sem internet;
## muda à meia-noite). A solução registrada da fase continua valendo com a
## regra — o teste automático confere isso (tests/test_runner.gd, "Desafio do Dia").

const MODS := [
	{"id": "curta", "name": "Tinta Curta", "desc": "Só 80% da tinta de sempre!", "icon": "ink"},
	{"id": "enxame", "name": "Enxame", "desc": "Metade a mais de insetos, saindo mais rápido!", "icon": "heart"},
	{"id": "hora_extra", "name": "Hora Extra", "desc": "Aguente 4 segundos a mais!", "icon": "timer"},
	{"id": "firme", "name": "Tinta Firme", "desc": "A linha não cai: fica parada onde você desenhar!", "icon": "pencil"},
	{"id": "pressa", "name": "Pressa", "desc": "Os insetos estão 30% mais rápidos!", "icon": "bolt"},
]
## Combinações que deixariam a fase impossível com a solução registrada (achadas pelo teste --daily-all).
const AVOID := {"hora_extra": ["6-6"]}


static func today_key() -> String:
	return Time.get_date_string_from_system()


static func previous_key(key: String) -> String:
	var t := Time.get_unix_time_from_datetime_string(key + "T12:00:00")
	return Time.get_date_string_from_unix_time(t - 86400)


static func reward(streak: int) -> int:
	return 30 + 5 * mini(maxi(streak - 1, 0), 6)


## Fases que podem virar desafio: sem toca de destino e sem chefão.
static func eligible(index: int) -> bool:
	var lv := LevelDB.get_level(index)
	return not lv.is_empty() and not lv.has("goal") and (lv.get("bosses", []) as Array).is_empty() \
		and not (lv.get("solution", []) as Array).is_empty()


## Fases já liberadas pelo jogador (pelo menos as 6 primeiras), para o desafio usar mecânicas conhecidas.
static func pool(all_levels: bool = false) -> Array:
	var out: Array = []
	for i in LevelDB.count():
		if eligible(i) and (all_levels or i < 6 or Game.is_unlocked(i)):
			out.append(i)
	return out


static func mods_for(index: int) -> Array:
	var lv := LevelDB.get_level(index)
	var id := str(lv.get("id", ""))
	var out: Array = []
	for m in MODS:
		# Não sortear redução de tinta quando ela corta a solução válida da fase.
		if m["id"] == "curta":
			var required := 0.0
			for stroke in Level._to_poly_list(lv.get("solution", [])):
				required += LineMath.length(stroke)
			if required > float(lv["ink"]) * 0.8 * 0.97:
				continue
		if m["id"] == "hora_extra" and str(lv.get("strategy", "")) == "double_layer":
			continue
		if m["id"] == "firme" and str(lv.get("ink_mode", "normal")) == "static":
			continue
		# a Tinta Firme não acompanha plataformas móveis
		if m["id"] == "firme" and (lv.get("props", []) as Array).any(func(p): return p.get("type", "") == "platform"):
			continue
		if (AVOID.get(m["id"], []) as Array).has(id):
			continue
		out.append(m)
	return out


static func pick(key: String, levels: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("guardipatas-" + key)
	var index: int = levels[rng.randi_range(0, levels.size() - 1)]
	var mods := mods_for(index)
	var mod: Dictionary = mods[rng.randi_range(0, mods.size() - 1)]
	return {"index": index, "mod": mod}


static func mod_info(id: String) -> Dictionary:
	for m in MODS:
		if m["id"] == id:
			return m
	return MODS[0]


## Monta os dados da fase do dia (cópia da fase original com a regra aplicada).
static func build(key: String, index: int, mod_id: String) -> Dictionary:
	var d: Dictionary = LevelDB.get_level(index).duplicate(true)
	d["base_id"] = d["id"]
	d["base_name"] = d["name"]
	d["id"] = "daily"
	d["mode"] = "daily"
	d["daily_key"] = key
	d["daily_mod"] = mod_id
	var m := mod_info(mod_id)
	d["name"] = UiKit.tr_text("Desafio: %s") % UiKit.tr_text(m["name"])
	d["objective"] = "%s  %s" % [UiKit.tr_text(m["desc"]), UiKit.tr_text(str(d.get("objective", d.get("tip", ""))))]
	d["tip"] = "%s  %s" % [UiKit.tr_text(m["desc"]), UiKit.tr_text(str(d.get("tip", "")))]
	match mod_id:
		"curta":
			d["ink"] = int(float(d["ink"]) * 0.8)
		"enxame":
			for n in d["nests"]:
				n["count"] = int(ceil(float(n.get("count", 6)) * 1.5))
				n["interval"] = float(n.get("interval", 0.3)) * 0.8
		"hora_extra":
			d["survive"] = float(d["survive"]) + 4.0
		"firme":
			d["ink_mode"] = "static"
		"pressa":
			d["insect_speed"] = 1.3
	return d


static func today(levels: Array = []) -> Dictionary:
	var key := today_key()
	var p := pick(key, levels if not levels.is_empty() else pool())
	return build(key, int(p["index"]), str(p["mod"]["id"]))
