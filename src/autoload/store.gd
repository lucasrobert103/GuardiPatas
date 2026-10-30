extends Node
## Adaptador de teste. Nenhum SDK, cartão, token ou cobrança real.
## Release falha fechado: integrar Play Billing + backend antes de vender.
signal changed

const PETS := {
	"amora": {"name": "Amora", "species": "Gatinha", "bio": "Uma exploradora de novelos que adora carinho e cochilos ao sol."},
	"bambu": {"name": "Bambu", "species": "Panda", "bio": "Coleciona folhas e distribui abraços na Casinha."},
	"gotinha": {"name": "Gotinha", "species": "Lontra", "bio": "Guarda pedrinhas favoritas e inventa brincadeiras para a turma."},
}
# Valores ilustrativos em BRL. Em produção, preço/moeda vêm de ProductDetails.
const PRODUCTS := {
	"coins_300": {"name": "Bolsa de moedas", "description": "300 moedas para acessórios e dicas.", "price": "R$ 4,90", "coins": 300, "repeatable": true},
	"coins_900": {"name": "Cofrinho de moedas", "description": "900 moedas para acessórios e dicas.", "price": "R$ 9,90", "coins": 900, "repeatable": true},
	"coins_2000": {"name": "Baú de moedas", "description": "2.000 moedas para acessórios e dicas.", "price": "R$ 19,90", "coins": 2000, "repeatable": true},
	"pet_amora": {"name": "Amora, a gatinha", "description": "Companheira permanente da Casinha. Sem vantagem nas fases.", "price": "R$ 6,90", "pets": ["amora"]},
	"pet_bambu": {"name": "Bambu, o panda", "description": "Companheiro permanente da Casinha. Sem vantagem nas fases.", "price": "R$ 6,90", "pets": ["bambu"]},
	"pet_gotinha": {"name": "Gotinha, a lontra", "description": "Companheira permanente da Casinha. Sem vantagem nas fases.", "price": "R$ 6,90", "pets": ["gotinha"]},
	"welcome": {"name": "Kit Boas-vindas", "description": "500 moedas, 5 dicas, Tiara da Lua e Cartola. Uma vez por save de teste.", "price": "R$ 9,90", "coins": 500, "hints": 5, "items": ["tiara_lua", "cartola"]},
}
var _sequence := 0
var _busy := false


func test_mode() -> bool:
	return OS.is_debug_build() and not OS.has_feature("release") and not OS.get_cmdline_user_args().has("--store-production")


func new_order_id() -> String:
	_sequence += 1
	return "test-%s-%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), _sequence]


func owned(product: String) -> bool:
	return Game.data.get("store", {}).get("owned", []).has(product)


func has_pet(pet: String) -> bool:
	return PETS.has(pet) and owned("pet_" + pet)


func companions() -> Array:
	return PETS.keys().filter(func(pet): return has_pet(pet))


func checkout(product: String, order_id: String) -> Dictionary:
	if not test_mode():
		return {"ok": false, "message": "Compras indisponíveis. Nenhuma cobrança foi feita."}
	if _busy or not PRODUCTS.has(product) or order_id.is_empty() or order_id.length() > 160:
		return {"ok": false, "message": "Pedido inválido ou em andamento."}
	var state: Dictionary = Game.data["store"]
	if state["receipts"].has(order_id):
		return {"ok": false, "message": "Este pedido já foi entregue."}
	var cfg: Dictionary = PRODUCTS[product]
	if owned(product) and not cfg.get("repeatable", false):
		return {"ok": false, "message": "Você já possui este conteúdo."}
	if state["receipts"].size() >= 10000:
		return {"ok": false, "message": "Limite de pedidos de teste atingido."}
	_busy = true
	var before := Game.data.duplicate(true)
	Game.data["coins"] = mini(10000000, Game.coins() + int(cfg.get("coins", 0)))
	Game.data["hints"] = mini(100000, Game.hints() + int(cfg.get("hints", 0)))
	for item in cfg.get("items", []):
		if not Game.owns(item):
			Game.data["owned"].append(item)
	if not cfg.get("repeatable", false):
		state["owned"].append(product)
	state["receipts"].append(order_id)
	if not Game.save():
		Game.data = before
		_busy = false
		return {"ok": false, "message": "Não foi possível salvar. Nada foi entregue; tente novamente."}
	_busy = false
	Game.coins_changed.emit(Game.coins())
	Game.hints_changed.emit(Game.hints())
	changed.emit()
	return {"ok": true, "message": "Compra de teste realizada com sucesso! Conteúdo liberado. Nenhuma cobrança foi feita."}
