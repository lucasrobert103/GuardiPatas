extends Node
## Termos de Uso e Política de Privacidade: textos completos nos três idiomas, aviso de aceite
## na primeira abertura (e quando os termos mudam), registro no save, tela com as quatro abas,
## atalhos nos Ajustes e o quadro "Guardado neste aparelho".
##   godot --headless --path . res://tests/legal_test.tscn
var passed := 0
var failures := 0
var last_go: Array = []


func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)


func frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame


func _screen(c: Control) -> Control:
	c.theme = UiKit.make_theme()
	c.connect("go", func(screen, arg): last_go = [screen, arg])
	add_child(c)
	await frames(3)
	return c


func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text and (n as Button).is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find_button(c, text)
		if r != null:
			return r
	return null


func _texts(n: Node, out: Array) -> Array:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)
	return out


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	Game.set_setting("lang", "pt_BR")
	get_window().size = Vector2i(720, 1280)

	# --- conteúdo
	var d := Legal.data()
	check(not d.is_empty(), "data/legal.json carrega")
	check(str(d.get("developer", "")) == "RetroNexa", "desenvolvedora é a RetroNexa")
	check(Legal.email().contains("@"), "contato de privacidade presente")
	for id in Legal.ORDER:
		var doc := Legal.doc(id)
		check(not doc.is_empty(), "documento %s existe" % id)
		for lang in ["pt", "en", "es"]:
			check(str(doc.get("title", {}).get(lang, "")) != "", "%s: título em %s" % [id, lang])
			check(str(doc.get("summary", {}).get(lang, "")) != "", "%s: resumo em %s" % [id, lang])
			for s in doc.get("sections", []):
				check(str(s["h"].get(lang, "")) != "", "%s: seção com título em %s" % [id, lang])
				for p in s.get("p", []):
					check(str(p.get(lang, "")).length() > 20, "%s: parágrafo em %s" % [id, lang])
	var privacy_pt := JSON.stringify(Legal.doc("privacy")).to_lower()
	for needle in ["lgpd", "13.709", "art. 18", "art. 14", "anpd", "google play", "coppa", "não coletamos", "vibração", "apagar progresso"]:
		check(privacy_pt.contains(needle), "privacidade cita \"%s\"" % needle)
	var terms_pt := JSON.stringify(Legal.doc("terms")).to_lower()
	for needle in ["ao baixar, instalar ou usar", "retronexa", "google play", "barreira para responsáveis", "código de defesa do consumidor", "valor em dinheiro"]:
		check(terms_pt.contains(needle), "termos citam \"%s\"" % needle)
	Game.set_setting("lang", "en")
	check(Legal.lang() == "en" and Legal.text(Legal.doc("terms")["title"]) == "Terms of Use", "termos em inglês")
	Game.set_setting("lang", "es")
	check(Legal.text(Legal.doc("privacy")["title"]) == "Política de Privacidad", "privacidade em espanhol")
	Game.set_setting("lang", "pt_BR")
	check(Legal.updated_line().contains(Legal.version()), "rodapé com versão")

	# --- aceite na primeira abertura
	check(not Legal.accepted() and not Legal.is_update(), "save novo ainda não aceitou")
	var title: TitleScreen = await _screen(TitleScreen.new())
	check(title.consent != null, "título mostra o aviso de termos")
	var texts := " ".join(_texts(title.consent, []))
	check(texts.contains("você concorda"), "aviso diz que ao usar você concorda")
	check(texts.contains("Boas-vindas"), "aviso de primeira vez")
	var read := _find_button(title.consent, "Termos de Uso")
	check(read != null, "botão para ler os termos")
	if read != null:
		read.pressed.emit()
		check(last_go.size() == 2 and last_go[0] == "legal" and last_go[1]["doc"] == "terms" and last_go[1]["back"] == "title", "ler termos abre a tela e volta ao título")
	check(not Legal.accepted(), "ler não conta como aceite")
	var ok := _find_button(title.consent, "Concordar e continuar")
	check(ok != null, "botão Concordar e continuar")
	if ok != null:
		ok.pressed.emit()
	await frames(2)
	check(Legal.accepted() and title.consent == null, "concordar grava e fecha o aviso")
	check(Game.data["legal"]["date"] != "", "data do aceite gravada")
	title.queue_free()
	var again: TitleScreen = await _screen(TitleScreen.new())
	check(again.consent == null, "aviso não volta depois de aceito")
	again.queue_free()

	# --- persistência real: fechar e abrir o jogo não mostra o aviso de novo
	var path := Game.save_path()
	var had_save := FileAccess.file_exists(path)
	var old_save := FileAccess.get_file_as_string(path) if had_save else ""
	var had_rec := FileAccess.file_exists(Legal.RECORD)
	var old_rec := FileAccess.get_file_as_string(Legal.RECORD) if had_rec else ""
	Game.persist = true
	Game.data["legal"] = {"accepted": "", "date": ""}
	Legal.accept()
	Game.load_save()
	check(Legal.accepted(), "aceite sobrevive a fechar e abrir o jogo")
	var reopened: TitleScreen = await _screen(TitleScreen.new())
	check(reopened.consent == null, "reabrir o jogo não mostra o aviso")
	reopened.queue_free()
	DirAccess.remove_absolute(path)
	Game.load_save()
	check(Legal.accepted(), "save apagado: o aceite volta da cópia de segurança")
	check(FileAccess.file_exists(path) and Game.data["legal"]["accepted"] == Legal.version(), "cópia restaura o aceite no save")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{corrompido")
	f.close()
	Game.load_save()
	var broken: TitleScreen = await _screen(TitleScreen.new())
	check(broken.consent == null, "save corrompido não traz o aviso de volta")
	broken.queue_free()
	Game.reset_progress()
	Game.load_save()
	check(Legal.accepted(), "apagar progresso e reabrir: aviso não volta")
	DirAccess.remove_absolute(Legal.RECORD)
	DirAccess.remove_absolute(path)
	Game.load_save()
	check(not Legal.accepted(), "dados do app limpos: aviso volta (instalação nova)")
	# restaura os arquivos do desenvolvedor
	if had_save:
		var fs := FileAccess.open(path, FileAccess.WRITE)
		fs.store_string(old_save)
		fs.close()
	if had_rec:
		var fr := FileAccess.open(Legal.RECORD, FileAccess.WRITE)
		fr.store_string(old_rec)
		fr.close()
	Game.persist = false
	Game.load_save()
	Game.set_setting("lang", "pt_BR")
	Legal.accept()

	# --- termos atualizados
	Game.data["legal"]["accepted"] = "0.1"
	check(Legal.is_update(), "versão antiga = termos atualizados")
	var upd: TitleScreen = await _screen(TitleScreen.new())
	check(upd.consent != null and " ".join(_texts(upd.consent, [])).contains("Atualizamos"), "aviso de termos atualizados")
	upd._accept_consent()
	check(Legal.accepted(), "aceite da nova versão")
	upd.queue_free()

	# --- apagar progresso mantém o registro do aceite; save adulterado não quebra
	Game.data["coins"] = 99
	Game.reset_progress()
	check(Legal.accepted() and Game.coins() == 0, "apagar progresso mantém o aceite")
	Game.data["legal"] = {"accepted": 5, "date": []}
	for key in ["accepted", "date"]:
		Game.data["legal"][key] = str(Game.data["legal"].get(key, "")).left(20)
	check(not Legal.accepted(), "aceite inválido não vale")
	Legal.accept()

	# --- tela de termos: quatro abas
	var lg := LegalScreen.new()
	lg.setup({"doc": "privacy", "back": "settings"})
	await _screen(lg)
	check(lg.doc_id == "privacy" and (lg._tab_buttons["privacy"] as Button).button_pressed, "abre na aba pedida")
	var body := " ".join(_texts(lg._content, []))
	check(body.contains("Política de Privacidade") and body.contains("RetroNexa"), "privacidade completa na tela")
	for id in Legal.ORDER:
		(lg._tab_buttons[id] as Button).pressed.emit()
		await frames(2)
		check(lg.doc_id == id and (lg._tab_buttons[id] as Button).button_pressed, "aba %s" % id)
		check(lg._content.get_child_count() >= 4, "aba %s tem conteúdo" % id)
		var tab_rect: Rect2 = (lg._tab_buttons[id] as Button).get_global_rect()
		check(tab_rect.position.x >= 0 and tab_rect.end.x <= 720, "aba %s dentro da tela" % id)
	(lg._tab_buttons["rights"] as Button).pressed.emit()
	await frames(2)
	var rights := " ".join(_texts(lg._content, []))
	check(rights.contains("Guardado neste aparelho agora"), "direitos mostram o que está salvo")
	var erase := _find_button(lg._content, "Ir para Apagar progresso")
	check(erase != null, "atalho para apagar progresso")
	if erase != null:
		erase.pressed.emit()
		check(last_go == ["settings", "reset"], "atalho leva ao botão de apagar nos Ajustes")
	check(lg._scroll.size.y > 600 and lg._scroll.get_global_rect().end.y <= 1280 - UiKit.GESTURE_GAP + 1, "texto rola acima da faixa de gestos")
	lg.on_back_pressed()
	check(last_go[0] == "settings", "voltar leva aos Ajustes")
	lg.queue_free()

	# --- Ajustes: seção Termos e privacidade
	var st: SettingsScreen = await _screen(SettingsScreen.new())
	for id in Legal.ORDER:
		check(st._controls.has("legal_" + id), "Ajustes têm botão %s" % id)
	(st._controls["legal_privacy"] as Button).pressed.emit()
	check(last_go.size() == 2 and last_go[0] == "legal" and last_go[1]["doc"] == "privacy", "Ajustes abrem a política")
	var stexts := " ".join(_texts(st, []))
	check(stexts.contains("você concorda com os Termos de Uso"), "Ajustes avisam que ao usar você concorda")
	check(stexts.contains("Versão dos termos: %s" % Legal.version()), "Ajustes mostram a versão aceita")
	check(stexts.contains("RetroNexa"), "Ajustes citam a RetroNexa")
	st.queue_free()
	var st2 := SettingsScreen.new()
	st2.focus_target = "reset"
	await _screen(st2)
	await frames(4)
	check((st2._controls["reset"] as Button).has_focus(), "vindo dos termos, foca Apagar progresso")
	st2.queue_free()

	print("==== TERMOS E PRIVACIDADE: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)
