extends Node
var passed := 0
var failures := 0


func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	check(PetCare.roster() == ["capi"], "Capitu disponível antes da primeira vitória")
	check(PetCare.state("invalid").is_empty(), "recusa animal desconhecido")
	check(PetCare.state("amora").is_empty(), "não libera companheiro não adquirido")
	var clean := PetCare.sanitize({"food": -20, "clean": 900, "energy": "bad", "love": INF, "sleeping": "yes"})
	check(clean["food"] == 0 and clean["clean"] == 100, "limites das barras")
	check(clean["energy"] == 80 and clean["love"] == 65 and not clean["sleeping"], "valores corrompidos e infinitos")
	Game.data["met"] = ["capi", "brasa"]
	var capi := PetCare.state("capi")
	var brasa := PetCare.state("brasa").duplicate()
	capi["food"] = 20.0
	check(PetCare.act("capi", "feed", "meal")["ok"], "refeição")
	check(capi["food"] == 50, "refeição nutre")
	check(PetCare.state("brasa") == brasa, "cuidados independentes")
	var before := capi.duplicate()
	check(not PetCare.act("capi", "feed", "unknown")["ok"] and before == capi, "recusa comida inválida sem mutação")
	capi["food"] = 100.0
	check(not PetCare.act("capi", "feed")["ok"], "recusa superalimentação")
	capi["clean"] = 10.0
	check(PetCare.act("capi", "bath")["ok"] and capi["clean"] == 100, "banho limpa")
	capi["energy"] = 30.0
	check(PetCare.act("capi", "sleep")["ok"], "dormir")
	before = capi.duplicate()
	check(not PetCare.act("capi", "play")["ok"] and capi == before, "não brinca dormindo")
	check(not PetCare.act("capi", "feed")["ok"], "não come dormindo")
	PetCare.tick(1.0)
	check(capi["energy"] == 32, "sono recupera energia")
	var energy: float = capi["energy"]
	PetCare.tick(999999)
	check(capi["energy"] == energy + 4, "retomada longa não avança tempo offline")
	PetCare.tick(-1)
	PetCare.tick(INF)
	check(capi["energy"] == energy + 4, "recusa delta inválido")
	check(PetCare.act("capi", "sleep")["ok"] and not capi["sleeping"], "acordar")
	capi["energy"] = 4.0
	check(not PetCare.act("capi", "play")["ok"], "precisa descansar antes de brincar")
	capi["energy"] = 80.0
	capi["love"] = 10.0
	check(PetCare.act("capi", "play")["ok"] and capi["energy"] == 75 and capi["love"] == 22, "brincadeira melhora carinho")
	var coins := Game.coins()
	PetCare.act("capi", "pet")
	check(Game.coins() == coins and capi["love"] == 27, "carinho gratuito, sem farm de moedas")
	check(not PetCare.act("capi", "unknown")["ok"], "recusa ação inválida")

	var home := HomeScreen.new()
	add_child(home)
	await get_tree().process_frame
	home.set_process(false)
	home._select("capi")
	for i in home._pets.size():
		home._pets[i].art.position = Vector2(180 + i * 320, 600)
	check(home._pets.size() == 2, "elenco resgatado disponível")
	await get_tree().process_frame
	var bottom_bar: ProgressBar = home._bars["love"][1]
	check(bottom_bar.get_global_rect().end.y < home.size.y * 0.4, "indicadores não cobrem área de interação")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = home._pets[0].art.position
	capi["food"] = 10.0
	home._choose_food("fruit")
	home._gui_input(click)
	check(capi["food"] == 30 and home._tool.is_empty(), "dar comida tocando no bichinho")
	home._set_mode("bath")
	capi["clean"] = 10.0
	home._rinse_pet()
	check(capi["clean"] == 10, "não enxágua sem sabão")
	home._tool = "soap"
	for i in 4:
		home._gui_input(click)
	check(home._soap == 1, "banho acessível por toques")
	home._rinse_pet()
	check(capi["clean"] == 100 and home._soap == 0 and home._rinse > 0, "enxaguar conclui banho e feedback")
	home._tool = "soap"
	var motion := InputEventMouseMotion.new()
	motion.position = click.position
	motion.relative = Vector2(35, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	home._gui_input(motion)
	check(home._soap > 0, "esfregar com movimento")
	home._select("brasa")
	check(home._soap == 0 and home._tool.is_empty(), "troca de animal não transfere espuma")
	home._select("capi")
	home._sleep()
	home._process(1.0)
	check(home._pets[0].art.mood == "sleeping", "olhos fechados durante sono")
	home._sleep()
	home._set_mode("play")
	home._play_ball()
	check(home._catches == 1 and home._ball.visible, "brincadeira da bola")
	before = Game.data.duplicate(true)
	home._try_on("coroa")
	check(Game.data == before and home._pets[0].art.accessory == "coroa", "prévia sem débito e sem direito comprado")
	home._set_mode("food")
	check(home._pets[0].art.accessory == Game.equipped("capi"), "sair da prévia restaura visual")
	Game.data["coins"] = 1000
	home._buy_clothing("bone")
	check(Game.owns("bone") and Game.equipped("capi") == "bone" and Game.coins() == 940, "compra e veste dentro da Casinha")
	home._wear("bone")
	check(Game.equipped("capi") == "bone", "vestir item já equipado não o remove")
	home._wear("")
	check(Game.equipped("capi").is_empty(), "tirar roupa")
	var saved_care: Dictionary = Game.data["care"].duplicate(true)
	home.queue_free()
	await get_tree().process_frame
	var reopened := HomeScreen.new()
	add_child(reopened)
	await get_tree().process_frame
	reopened.set_process(false)
	check(Game.data["care"] == saved_care, "reabrir não reinicia necessidades nem cobra tempo offline")
	reopened.queue_free()
	await get_tree().process_frame
	for language in [["en", "Tummy"], ["es", "Barriguita"]]:
		Game.set_setting("lang", language[0])
		Game.set_setting("big_text", true)
		var localized := HomeScreen.new()
		localized.theme = UiKit.make_theme()
		add_child(localized)
		await get_tree().process_frame
		await get_tree().process_frame
		localized.set_process(false)
		check((localized._bars["food"][0] as Label).text.begins_with(language[1]), "indicadores traduzidos " + language[0])
		check((localized._bars["love"][1] as ProgressBar).get_global_rect().end.y < localized.size.y * 0.4, "layout texto grande " + language[0])
		localized.queue_free()
		await get_tree().process_frame
	Game.set_setting("lang", "pt_BR")
	Game.set_setting("big_text", false)

	if OS.get_cmdline_user_args().has("--test-io") and OS.get_environment("XDG_DATA_HOME").ends_with("/guardipatas-care-tests"):
		Game.persist = true
		check(Game.save(), "grava cuidados")
		Game.load_save()
		var restored := true
		for pet in saved_care:
			for key in PetCare.NEEDS:
				restored = restored and is_equal_approx(float(Game.data["care"][pet][key]), float(saved_care[pet][key]))
			restored = restored and Game.data["care"][pet]["sleeping"] == saved_care[pet]["sleeping"] and Game.data["care"][pet]["care_count"] == saved_care[pet]["care_count"]
		check(restored, "recarga JSON preserva cuidados")
		var screen := HomeScreen.new()
		add_child(screen)
		await get_tree().process_frame
		screen.set_process(false)
		var snapshot := Game.data.duplicate(true)
		DirAccess.make_dir_absolute(Game.save_path() + ".tmp")
		check(not screen._care("bath") and Game.data == snapshot, "falha ao salvar reverte cuidado")
		check(not Game.buy_item("laco") and Game.data == snapshot, "falha ao salvar não cobra roupa")
		check(not Game.equip("capi", "bone") and Game.data == snapshot, "falha ao salvar reverte vestuário")
		DirAccess.remove_absolute(Game.save_path() + ".tmp")
		screen.queue_free()
		await get_tree().process_frame
		Game.reset_progress()
		check(Game.data["care"].is_empty(), "reset limpa cuidados")
		Game.persist = false
	else:
		print("Persistência não executada: use --test-io e XDG_DATA_HOME terminado em /guardipatas-care-tests.")
	print("==== CUIDADOS: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)
