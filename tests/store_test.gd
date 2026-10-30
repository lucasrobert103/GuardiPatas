extends Node
var failures := 0
var passed := 0


func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	if not Store.test_mode():
		var before := Game.data.duplicate(true)
		check(not Store.checkout("coins_300", "release-order")["ok"], "produção rejeita compra simulada")
		check(before == Game.data, "produção não entrega moedas nem direitos")
		check(Game.save_path() == Game.SAVE_PATH, "produção usa save original")
		_finish()
		return
	check(Game.save_path() != Game.SAVE_PATH, "save de teste isolado")
	check(Game.album_dir() != Game.ALBUM_DIR, "álbum de teste isolado")
	check(not Store.checkout("unknown", "bad")["ok"], "produto inválido")
	check(not Store.checkout("coins_300", "")["ok"], "pedido vazio")
	check(Store.checkout("coins_300", "order-1")["ok"], "compra de moedas")
	check(Game.coins() == 300, "entrega exata de moedas")
	check(not Store.checkout("coins_300", "order-1")["ok"], "replay bloqueado")
	check(Game.coins() == 300, "replay não duplica moedas")
	check(Store.checkout("coins_300", "order-2")["ok"], "consumível pode ser recomprado")
	check(Game.coins() == 600, "segunda entrega")
	check(Store.checkout("welcome", "welcome-1")["ok"], "kit entregue")
	check(Game.coins() == 1100 and Game.hints() == 8, "moedas e dicas do kit")
	check(Game.owns("tiara_lua") and Game.owns("cartola"), "cosméticos do kit")
	check(not Store.checkout("welcome", "welcome-2")["ok"], "kit não repete")
	for pet in Store.PETS:
		check(Store.checkout("pet_" + pet, "order-" + pet)["ok"], "adoção " + pet)
		check(Store.has_pet(pet), "direito de companheiro " + pet)
		check(not Store.checkout("pet_" + pet, "repeat-" + pet)["ok"], "companheiro não repete")
	check(Store.companions().size() == 3, "três companheiros")
	for item in ["pirata", "fones", "gravata", "halo"]:
		check(Game.buy_item(item), "compra cosmético " + item)
		Game.equip("amora", item)
		check(Game.equipped("amora") == item, "equipa em novo animal")
	check(not Game.buy_item("pirata"), "cosmético não cobra duas vezes")
	check(not Game.safe_album_path("user://album-store-test/../save.json"), "recusa traversal")
	check(not Game.safe_album_path(Game.save_path()), "não remove save como foto")
	check(Game.safe_album_path(Game.album_dir() + "/test.png"), "aceita foto interna")

	# Interação real com confirmação: cancelar, errar, pagar e toque repetido.
	var screen := StoreScreen.new()
	add_child(screen)
	await get_tree().process_frame
	var balance := Game.coins()
	screen._ask("coins_300")
	screen._cancel()
	check(Game.coins() == balance, "cancelar não entrega")
	screen._ask("coins_300")
	screen._entry.text = "0"
	screen._pay()
	check(Game.coins() == balance and screen._modal != null, "resposta incorreta bloqueada")
	screen._entry.text = str(screen._answer)
	screen._pay()
	screen._pay()
	check(Game.coins() == balance + 300, "pagar confirma uma única entrega")
	check(screen._status.text.contains("sucesso"), "confirmação visível")
	screen.queue_free()
	var home := HomeScreen.new()
	add_child(home)
	await get_tree().process_frame
	check(home._pets.size() == 3, "novos animais aparecem na Casinha")
	home.queue_free()
	# Persistência e falha de disco usam diretório XDG separado no comando de teste.
	if not OS.get_cmdline_user_args().has("--test-io") or not OS.get_environment("XDG_DATA_HOME").ends_with("/guardipatas-store-tests"):
		print("Persistência: não executada; use XDG_DATA_HOME isolado terminando em /guardipatas-store-tests e --test-io.")
		_finish()
		return
	Game.persist = true
	Game.set_setting("colorblind", 2)
	check(Game.save(), "save atômico")
	Game.load_save()
	check(Game.coins() == balance + 300 and Store.companions().size() == 3, "recarga preserva moedas e direitos")
	check(int(Game.setting("colorblind")) == 2, "configuração numérica preservada no JSON")
	check(not Store.checkout("coins_300", "order-1")["ok"], "replay rejeitado após recarga")
	DirAccess.make_dir_absolute(Game.save_path() + ".tmp")
	balance = Game.coins()
	check(not Store.checkout("coins_300", "disk-failure")["ok"], "falha de gravação rejeita compra")
	check(Game.coins() == balance and not Game.data["store"]["receipts"].has("disk-failure"), "rollback integral na falha de gravação")
	DirAccess.remove_absolute(Game.save_path() + ".tmp")
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	var photo := Game.add_photo(image, "teste")
	var path: String = photo["entry"]["file"]
	check(FileAccess.file_exists(path), "foto criada")
	Game.reset_progress()
	check(not FileAccess.file_exists(path), "apagar progresso remove foto")
	check(Game.coins() == 0 and Store.companions().is_empty(), "reset limpa compras de teste")
	var corrupt := FileAccess.open(Game.save_path(), FileAccess.WRITE)
	corrupt.store_string(JSON.stringify({"coins": -90, "hints": [], "settings": {"music": [], "lang": {}}, "store": {"owned": {}, "receipts": false}, "met": ["invalid", {}], "album": [{"file": "user://save.json"}]}))
	corrupt.close()
	Game.load_save()
	check(Game.coins() == 0 and Game.hints() == Game.START_HINTS, "save inválido usa padrões seguros")
	check(Store.companions().is_empty() and Game.data["met"].is_empty() and Game.data["album"].is_empty(), "recusa conteúdo inválido e caminhos externos")
	Game.apply_settings()
	Game.reset_progress()
	Game.persist = false
	_finish()


func _finish() -> void:
	print("==== LOJA: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)
