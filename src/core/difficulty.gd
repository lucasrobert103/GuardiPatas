class_name Difficulty
## Dificuldade da campanha (Ajustes e mapa): mais insetos, saindo mais rápido e correndo mais.
## Cada fase só sobe até o nível em que a solução registrada AINDA vence — o teste
## `test_runner.tscn -- --difficulty=N` confere todas as fases; as exceções ficam em CAPS.
## Desafio do Dia, editor e Modo Livre não mudam.

const NAMES := ["Normal", "Difícil", "Extremo"]
const DEFAULT := 1
## [mais insetos por ninho, intervalo entre saídas, velocidade]
const PARAMS := [[1.0, 1.0, 1.0], [1.3, 0.85, 1.15], [1.6, 0.75, 1.3]]
## Moedas por vitória (recompensa pelo risco).
const COIN_BONUS := [1.0, 1.25, 1.5]
## População simultânea suportada (Level.MAX_INSECTS = 45), com folga.
const MAX_TOTAL := 44
## Fase -> nível máximo em que a solução registrada vence (achado pelo teste).
const CAPS := {"10-2": 0, "9-9": 1, "10-7": 1}


static func current() -> int:
	return clampi(int(Game.setting("difficulty")), 0, NAMES.size() - 1)


static func cap(id: String) -> int:
	return int(CAPS.get(id, NAMES.size() - 1))


static func effective(id: String, wanted: int = -1) -> int:
	return mini(current() if wanted < 0 else wanted, cap(id))


## Cópia da fase com a dificuldade aplicada (a original do LevelDB não muda).
static func apply(data: Dictionary, wanted: int = -1) -> Dictionary:
	var lv := effective(str(data.get("id", "")), wanted)
	if lv <= 0 or data.is_empty():
		return data
	var d := data.duplicate(true)
	var p: Array = PARAMS[lv]
	var total := 0
	for n in d.get("nests", []):
		n["count"] = int(ceil(float(n.get("count", 6)) * float(p[0])))
		n["interval"] = maxf(0.18, float(n.get("interval", 0.3)) * float(p[1]))
		total += int(n["count"])
	# não passar do limite de insetos ao mesmo tempo: corta dos ninhos maiores
	while total > MAX_TOTAL:
		var big: Dictionary = d["nests"][0]
		for n in d["nests"]:
			if int(n["count"]) > int(big["count"]):
				big = n
		big["count"] = int(big["count"]) - 1
		total -= 1
	d["insect_speed"] = float(d.get("insect_speed", 1.0)) * float(p[2])
	d["difficulty"] = lv
	return d
