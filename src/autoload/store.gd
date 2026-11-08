extends Node
## Loja do GuardiPatas: catálogo, entrega de direitos e adaptador de pagamento.
##
## Três modos:
##  * Grátis para testadores (FREE_FOR_TESTERS, builds de release): nada é cobrado e os
##    produtos saem de graça. O pagamento real fica DESLIGADO (ver bloco abaixo).
##  * Teste (builds de debug): compra SIMULADA, sem cobrança, com save separado.
##  * Real (Android + plugin Google Play Billing + servidor de verificação): a compra é
##    feita pelo Google Play e o conteúdo só é entregue depois que o SEU servidor confirma
##    o token de compra (ver PlayBilling e docs/16). Sem plugin ou sem servidor, falha fechado:
##    nada é cobrado nem entregue.
signal changed
signal purchase_finished(product: String, ok: bool, message: String)

const PETS := {
	"amora": {"name": "Amora", "species": "Gatinha", "bio": "Uma exploradora de novelos que adora carinho e cochilos ao sol."},
	"bambu": {"name": "Bambu", "species": "Panda", "bio": "Coleciona folhas e distribui abraços na Casinha."},
	"gotinha": {"name": "Gotinha", "species": "Lontra", "bio": "Guarda pedrinhas favoritas e inventa brincadeiras para a turma."},
	# bichinhos mágicos: já vêm com um efeito especial próprio
	"faisca": {"name": "Faísca", "species": "Dragãozinho", "bio": "Solta faíscas quentinhas (que não queimam) quando ri. Ama marshmallow.", "effect": "fogo", "magic": true},
	"lumi": {"name": "Lumi", "species": "Unicórnio", "bio": "Deixa um rastro de arco-íris por onde passa e acredita em todo mundo.", "effect": "arco_iris", "magic": true},
	"cometa": {"name": "Cometa", "species": "Gatinho Galáctico", "bio": "Caiu do céu numa noite de estrelas cadentes e nunca mais quis ir embora.", "effect": "estrelas", "magic": true},
	"pipoca": {"name": "Pipoca", "species": "Hamster Dourado", "bio": "Brilha como ouro e guarda sementes nas bochechas para dividir com a turma.", "effect": "brilho", "magic": true},
}
const MAGIC_PETS := ["faisca", "lumi", "cometa", "pipoca"]

# Valores ilustrativos em BRL. No modo real, preço e moeda vêm do Google Play (ProductDetails).
# category: destaque | moedas | bichinhos | efeitos (uma aba da loja cada)
const PRODUCTS := {
	"welcome": {"name": "Kit Boas-vindas", "description": "500 moedas, 5 dicas, Tiara da Lua e Cartola. Uma vez por jogador.", "price": "R$ 9,90", "coins": 500, "hints": 5, "items": ["tiara_lua", "cartola"], "category": "destaque", "tag": "Oferta"},
	"bundle_magic": {"name": "Turma Mágica", "description": "Os 4 bichinhos mágicos (Faísca, Lumi, Cometa e Pipoca) + 1.000 moedas.", "price": "R$ 29,90", "pets": ["faisca", "lumi", "cometa", "pipoca"], "coins": 1000, "category": "destaque", "tag": "Mais vendido"},
	"bundle_supreme": {"name": "Baú Supremo", "description": "TODOS os bichinhos da loja, todos os efeitos especiais, 5.000 moedas e 20 dicas.", "price": "R$ 59,90", "pets": ["amora", "bambu", "gotinha", "faisca", "lumi", "cometa", "pipoca"], "effects": ["folhas", "neve", "bolhas", "coracoes", "brilho", "estrelas", "fogo", "arco_iris"], "coins": 5000, "hints": 20, "category": "destaque", "tag": "Tudo!"},
	"vip_coins": {"name": "Pata Dourada", "description": "Para sempre: o DOBRO de moedas em cada fase vencida.", "price": "R$ 14,90", "vip": true, "category": "destaque"},
	"coins_300": {"name": "Bolsa de moedas", "description": "300 moedas para acessórios, efeitos e dicas.", "price": "R$ 4,90", "coins": 300, "repeatable": true, "category": "moedas"},
	"coins_900": {"name": "Cofrinho de moedas", "description": "900 moedas para acessórios, efeitos e dicas.", "price": "R$ 9,90", "coins": 900, "repeatable": true, "category": "moedas"},
	"coins_2000": {"name": "Baú de moedas", "description": "2.000 moedas para acessórios, efeitos e dicas.", "price": "R$ 19,90", "coins": 2000, "repeatable": true, "category": "moedas"},
	"coins_5000": {"name": "Montanha de moedas", "description": "5.000 moedas para acessórios, efeitos e dicas.", "price": "R$ 39,90", "coins": 5000, "repeatable": true, "category": "moedas", "tag": "+25%"},
	"coins_12000": {"name": "Tesouro do Dragão", "description": "12.000 moedas para comprar tudo o que quiser.", "price": "R$ 79,90", "coins": 12000, "repeatable": true, "category": "moedas", "tag": "+50%"},
	"hints_10": {"name": "Lâmpada de Dicas", "description": "10 dicas para as fases mais difíceis.", "price": "R$ 3,90", "hints": 10, "repeatable": true, "category": "moedas"},
	"effects_all": {"name": "Pacote de Efeitos", "description": "Libera os 8 efeitos especiais para usar em qualquer bichinho.", "price": "R$ 7,90", "effects": ["folhas", "neve", "bolhas", "coracoes", "brilho", "estrelas", "fogo", "arco_iris"], "category": "efeitos"},
	"pet_faisca": {"name": "Faísca, o dragãozinho", "description": "Bichinho MÁGICO com Chama Mágica. Mora na Casinha.", "price": "R$ 9,90", "pets": ["faisca"], "category": "bichinhos"},
	"pet_lumi": {"name": "Lumi, a unicórnio", "description": "Bichinho MÁGICO com rastro de Arco-íris. Mora na Casinha.", "price": "R$ 9,90", "pets": ["lumi"], "category": "bichinhos"},
	"pet_cometa": {"name": "Cometa, o gatinho galáctico", "description": "Bichinho MÁGICO com Poeira de Estrelas. Mora na Casinha.", "price": "R$ 9,90", "pets": ["cometa"], "category": "bichinhos"},
	"pet_pipoca": {"name": "Pipoca, a hamster dourada", "description": "Bichinho MÁGICO com Brilho Dourado. Mora na Casinha.", "price": "R$ 9,90", "pets": ["pipoca"], "category": "bichinhos"},
	"pet_amora": {"name": "Amora, a gatinha", "description": "Companheira permanente da Casinha. Sem vantagem nas fases.", "price": "R$ 6,90", "pets": ["amora"], "category": "bichinhos"},
	"pet_bambu": {"name": "Bambu, o panda", "description": "Companheiro permanente da Casinha. Sem vantagem nas fases.", "price": "R$ 6,90", "pets": ["bambu"], "category": "bichinhos"},
	"pet_gotinha": {"name": "Gotinha, a lontra", "description": "Companheira permanente da Casinha. Sem vantagem nas fases.", "price": "R$ 6,90", "pets": ["gotinha"], "category": "bichinhos"},
}
const CATEGORIES := [["destaque", "Destaques"], ["moedas", "Moedas"], ["bichinhos", "Bichinhos"], ["efeitos", "Efeitos"]]

## ====================================================================== VERSÃO DE TESTADORES
## true  = versão para testadores da Play Store: TUDO GRÁTIS, nenhuma cobrança, sem Google Play
##         Billing (o APK/AAB nem pede a permissão de compra).
## false = versão paga: ligue o bloco "INTEGRAÇÃO DE PAGAMENTO" em _ready() — instale o plugin
##         GodotGooglePlayBilling, configure guardipatas/billing/verify_url (servidor que confere o
##         token com a Google Play Developer API) e crie os produtos na Play Console (docs/16, docs/29).
const FREE_FOR_TESTERS := true

var _sequence := 0
var _busy := false
var billing: PlayBilling


func _ready() -> void:
	# ------------------------------------------------------------------ INTEGRAÇÃO DE PAGAMENTO
	# Desligada enquanto FREE_FOR_TESTERS = true. Quando a integração estiver pronta, basta
	# FREE_FOR_TESTERS = false: este bloco conecta o Google Play Billing (PlayBilling) e as
	# compras passam a ser cobradas pelo Google Play e entregues só depois que o servidor confirma.
	if free_mode():
		return
	if not test_mode() and PlayBilling.plugin_available():
		billing = PlayBilling.new()
		billing.delivered.connect(_on_real_delivery)
		billing.failed.connect(func(product: String, message: String): purchase_finished.emit(product, false, message))
		add_child(billing)


## Versão de testadores: tudo grátis (só em builds de release; o debug continua simulando).
func free_mode() -> bool:
	return FREE_FOR_TESTERS and not test_mode()


func test_mode() -> bool:
	return OS.is_debug_build() and not OS.has_feature("release") and not OS.get_cmdline_user_args().has("--store-production")


## Compras com dinheiro de verdade disponíveis (plugin conectado + servidor configurado).
func real_mode() -> bool:
	return billing != null and billing.ready_to_sell()


func can_buy() -> bool:
	return free_mode() or test_mode() or real_mode()


## Preço mostrado: o do Google Play no modo real; o ilustrativo nos testes.
func price_of(product: String) -> String:
	if free_mode():
		return UiKit.tr_text("Grátis")
	if real_mode():
		var p := billing.price_of(product)
		if p != "":
			return p
	return str(PRODUCTS.get(product, {}).get("price", ""))


func new_order_id() -> String:
	_sequence += 1
	return "test-%s-%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), _sequence]


func owned(product: String) -> bool:
	return Game.data.get("store", {}).get("owned", []).has(product)


func has_pet(pet: String) -> bool:
	if not PETS.has(pet):
		return false
	if owned("pet_" + pet):
		return true
	for id in PRODUCTS:
		if owned(id) and (PRODUCTS[id].get("pets", []) as Array).has(pet):
			return true
	return false


func has_vip() -> bool:
	return owned("vip_coins") or owned("bundle_supreme")


func companions() -> Array:
	return PETS.keys().filter(func(pet): return has_pet(pet))


func products_in(category: String) -> Array:
	return PRODUCTS.keys().filter(func(id): return str(PRODUCTS[id].get("category", "")) == category)


## Já tem tudo o que o produto entrega (pacotes com bichinhos já adotados ficam "Adquirido").
func fully_owned(product: String) -> bool:
	var cfg: Dictionary = PRODUCTS.get(product, {})
	if cfg.is_empty() or cfg.get("repeatable", false):
		return false
	if owned(product):
		return true
	# bichinho avulso que já veio num pacote
	var only_pets := cfg.has("pets") and not (cfg.has("coins") or cfg.has("hints") or cfg.has("effects") or cfg.has("items"))
	return only_pets and (cfg["pets"] as Array).all(func(pet): return has_pet(pet))


## Ponto de entrada da interface: no modo teste entrega na hora; no modo real abre o
## fluxo do Google Play e responde depois pelo sinal purchase_finished.
func buy(product: String) -> Dictionary:
	if free_mode():
		if not PRODUCTS.has(product) or fully_owned(product):
			return {"ok": false, "message": "Você já possui este conteúdo."}
		_sequence += 1
		var r := _deliver(product, "gratis-%s-%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), _sequence],
			"Liberado de graça na versão de testes!")
		purchase_finished.emit(product, r["ok"], r["message"])
		return r
	if test_mode():
		var r := checkout(product, new_order_id())
		purchase_finished.emit(product, r["ok"], r["message"])
		return r
	if real_mode():
		if not PRODUCTS.has(product) or fully_owned(product):
			return {"ok": false, "message": "Você já possui este conteúdo."}
		billing.purchase(product)
		return {"ok": true, "pending": true, "message": "Abrindo o Google Play…"}
	return {"ok": false, "message": "Compras indisponíveis neste aparelho. Nenhuma cobrança foi feita."}


## Simulação (somente builds de teste).
func checkout(product: String, order_id: String) -> Dictionary:
	if not test_mode():
		return {"ok": false, "message": "Compras indisponíveis. Nenhuma cobrança foi feita."}
	return _deliver(product, order_id, "Compra de teste realizada com sucesso! Conteúdo liberado. Nenhuma cobrança foi feita.")


## Compra real já VERIFICADA pelo servidor (chamado pelo PlayBilling).
func _on_real_delivery(product: String, order_id: String) -> void:
	var r := _deliver(product, order_id, "Compra concluída! Obrigado por apoiar o GuardiPatas.")
	if r["ok"] or str(r["message"]).contains("já foi entregue"):
		billing.finish(product, order_id, PRODUCTS[product].get("repeatable", false))
	purchase_finished.emit(product, r["ok"], r["message"])


func _deliver(product: String, order_id: String, success: String) -> Dictionary:
	if _busy or not PRODUCTS.has(product) or order_id.is_empty() or order_id.length() > 160:
		return {"ok": false, "message": "Pedido inválido ou em andamento."}
	var state: Dictionary = Game.data["store"]
	if state["receipts"].has(order_id):
		return {"ok": false, "message": "Este pedido já foi entregue."}
	var cfg: Dictionary = PRODUCTS[product]
	if owned(product) and not cfg.get("repeatable", false):
		return {"ok": false, "message": "Você já possui este conteúdo."}
	if state["receipts"].size() >= 10000:
		return {"ok": false, "message": "Limite de pedidos atingido."}
	_busy = true
	var before := Game.data.duplicate(true)
	Game.data["coins"] = mini(10000000, Game.coins() + int(cfg.get("coins", 0)))
	Game.data["hints"] = mini(100000, Game.hints() + int(cfg.get("hints", 0)))
	for item in cfg.get("items", []):
		if not Game.owns(item):
			Game.data["owned"].append(item)
	for fx in cfg.get("effects", []):
		if not Game.owns_effect(fx):
			Game.data["fx_owned"].append(fx)
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
	return {"ok": true, "message": success}
