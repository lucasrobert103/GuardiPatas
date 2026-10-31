class_name PlayBilling
extends Node
## Ponte com o plugin Android "GodotGooglePlayBilling" (API 1.x/2.x: startConnection,
## querySkuDetails, purchase, acknowledgePurchase, consumePurchase). Criado pela Store só
## em builds de produção quando o plugin existe.
##
## Segurança (docs/16): o app NUNCA entrega conteúdo só porque o Google Play disse
## "comprado" no aparelho. O token vai para o SEU servidor (`guardipatas/billing/verify_url`),
## que confere a compra na Google Play Developer API e responde {"ok": true}. Só então o
## conteúdo é entregue e a compra é consumida (moedas) ou reconhecida (direitos).
## Sem URL configurada, ready_to_sell() é falso e a loja mostra "indisponível".
##
## ATENÇÃO: este fluxo ainda NÃO foi testado num aparelho Android com produtos reais.

signal delivered(product: String, order_id: String)
signal failed(product: String, message: String)

const SINGLETON := "GodotGooglePlayBilling"
const VERIFY_SETTING := "guardipatas/billing/verify_url"
const PURCHASED := 1

var _plugin: Object
var _connected := false
var _prices: Dictionary = {}
var _tokens: Dictionary = {}     # order_id -> purchase_token
var _http: HTTPRequest
var _queue: Array = []           # compras esperando verificação
var _verifying: Dictionary = {}


static func plugin_available() -> bool:
	return Engine.has_singleton(SINGLETON)


static func verify_url() -> String:
	return str(ProjectSettings.get_setting(VERIFY_SETTING, ""))


func _ready() -> void:
	_plugin = Engine.get_singleton(SINGLETON)
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	_http.request_completed.connect(_on_verified)
	add_child(_http)
	_plugin.connect("connected", _on_connected)
	_plugin.connect("disconnected", func(): _connected = false)
	_plugin.connect("connect_error", func(_code, _msg): _connected = false)
	_plugin.connect("sku_details_query_completed", _on_details)
	_plugin.connect("purchases_updated", _on_purchases)
	_plugin.connect("purchase_error", func(_code, msg): failed.emit("", "Compra não concluída: %s" % msg))
	_plugin.connect("query_purchases_response", _on_query_purchases)
	_plugin.startConnection()


func ready_to_sell() -> bool:
	return _connected and not verify_url().is_empty() and not _prices.is_empty()


func price_of(product: String) -> String:
	return str(_prices.get(product, ""))


func purchase(product: String) -> void:
	if not ready_to_sell():
		failed.emit(product, "Loja indisponível no momento. Nenhuma cobrança foi feita.")
		return
	var r: Variant = _plugin.purchase(product)
	if r is Dictionary and int(r.get("status", 0)) != OK:
		failed.emit(product, "Não foi possível abrir o Google Play.")


## Depois da entrega durável: consome (moedas, para poder recomprar) ou reconhece (direitos).
func finish(_product: String, order_id: String, consumable: bool) -> void:
	var token := str(_tokens.get(order_id, ""))
	if token.is_empty():
		return
	if consumable:
		_plugin.consumePurchase(token)
	else:
		_plugin.acknowledgePurchase(token)


func _on_connected() -> void:
	_connected = true
	_plugin.querySkuDetails(Store.PRODUCTS.keys(), "inapp")
	# compras feitas e ainda não finalizadas (app fechado no meio, reinstalação de direitos)
	_plugin.queryPurchases("inapp")


func _on_details(details: Array) -> void:
	for d in details:
		if d is Dictionary and Store.PRODUCTS.has(str(d.get("sku", ""))):
			_prices[str(d["sku"])] = str(d.get("price", ""))


func _on_query_purchases(result: Dictionary) -> void:
	if int(result.get("status", 1)) == OK:
		_on_purchases(result.get("purchases", []))


func _on_purchases(purchases: Array) -> void:
	for p in purchases:
		if not p is Dictionary or int(p.get("purchase_state", 0)) != PURCHASED:
			continue  # pendente/cancelada: não entregar
		var sku := str(p.get("sku", ""))
		if sku.is_empty() and p.get("skus", []) is Array and not (p["skus"] as Array).is_empty():
			sku = str(p["skus"][0])
		var order := str(p.get("order_id", ""))
		var token := str(p.get("purchase_token", ""))
		if not Store.PRODUCTS.has(sku) or token.is_empty() or order.is_empty() or _verifying.has(order):
			continue
		_tokens[order] = token
		_verifying[order] = true
		_queue.append({"product": sku, "order_id": order, "token": token})
	_next()


func _next() -> void:
	if _queue.is_empty() or _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var job: Dictionary = _queue[0]
	var body := JSON.stringify({"product": job["product"], "token": job["token"], "order_id": job["order_id"]})
	var err := _http.request(verify_url(), ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		_queue.pop_front()
		_verifying.erase(job["order_id"])
		failed.emit(str(job["product"]), "Não foi possível confirmar a compra. Ela será conferida de novo depois.")


func _on_verified(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _queue.is_empty():
		return
	var job: Dictionary = _queue.pop_front()
	_verifying.erase(job["order_id"])
	var reply: Variant = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS and code == 200 else null
	if reply is Dictionary and bool(reply.get("ok", false)) and str(reply.get("product", "")) == str(job["product"]):
		delivered.emit(str(job["product"]), str(job["order_id"]))
	else:
		# não confirmada: nada é entregue nem consumido; o Google Play reembolsa
		# automaticamente compras não reconhecidas em 3 dias
		failed.emit(str(job["product"]), "A compra não foi confirmada. Nada foi entregue.")
	_next()
