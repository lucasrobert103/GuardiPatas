class_name Treats
## Petiscos ganhos nas fases (e no Modo Infinito), guardados para dar na Casinha.
## Cada petisco enche mais a barriguinha e o carinho do que a comida comum.

const KINDS := {
	"biscoito": {"name": "Biscoito de Patinha", "food": 18.0, "love": 16.0, "color": "e0a860"},
	"morango": {"name": "Morango Doce", "food": 14.0, "love": 20.0, "color": "ff6b6b"},
	"picole": {"name": "Picolé de Fruta", "food": 10.0, "love": 26.0, "color": "8fd3ff"},
	"bolinho": {"name": "Bolinho de Mel", "food": 24.0, "love": 14.0, "color": "ffd23f"},
}
const ORDER := ["biscoito", "morango", "picole", "bolinho"]


static func count(kind: String) -> int:
	return int(Game.data["treats"].get(kind, 0))


static func total() -> int:
	var n := 0
	for k in ORDER:
		n += count(k)
	return n


## Ganha petiscos (sem salvar: quem chama já salva junto do resto).
static func grant(kind: String, n: int = 1) -> void:
	if KINDS.has(kind):
		Game.data["treats"][kind] = clampi(count(kind) + n, 0, 999)


## Sorteio estável pelo nome da fase + estrelas (mais estrelas, mais petiscos).
static func reward_for(id: String, stars: int) -> Dictionary:
	var out := {}
	var h := absi(hash(id + str(stars) + str(Game.stat("wins"))))
	for i in clampi(stars, 1, 3):
		var k: String = ORDER[(h + i * 7) % ORDER.size()]
		out[k] = int(out.get(k, 0)) + 1
	return out


static func use(kind: String, pet: String) -> bool:
	if count(kind) <= 0 or not KINDS.has(kind):
		return false
	var needs := PetCare.state(pet)
	needs["food"] = minf(100.0, float(needs["food"]) + float(KINDS[kind]["food"]))
	needs["love"] = minf(100.0, float(needs["love"]) + float(KINDS[kind]["love"]))
	Game.data["treats"][kind] = count(kind) - 1
	Game.add_stat("treats_given", 1, false)
	return Game.save()
