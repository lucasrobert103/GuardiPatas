extends Node
## Teste de fluxo: dirige a cena principal como um jogador, apertando botões de verdade
## (emite `pressed`), e confere que cada tela abre. Erros de script aparecem no log;
## o CI falha se houver "SCRIPT ERROR".
##   godot --headless --fixed-fps 60 --path . res://tests/flow_test.tscn

var main: Node
var failures := 0


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(0.5)
	_expect(main._current is SplashScreen, "abre na abertura RetroNexa")
	await _wait(SplashScreen.DURATION + 0.8)
	_expect(main._current is TitleScreen, "abertura leva ao título")

	await _press_text("Jogar")
	_expect(main._current is LevelSelect, "Jogar → mapa")
	await _press_text("1")
	_expect(main._current is Level, "botão 1 → fase 1-1")
	var lv: Level = main._current

	# pausa e continua
	lv.hud._open_pause()
	await _wait(0.2)
	_expect(get_tree().paused, "pausa congela o jogo")
	await _press_text("Continuar")
	_expect(not get_tree().paused, "continuar despausa")

	# perde de propósito (sem linha) → tela de derrota → pedir dica
	lv.start_simulation()
	await _wait_until(func(): return lv.state == Level.State.LOST, 8.0)
	_expect(lv.state == Level.State.LOST, "sem linha perde")
	await _wait(1.6)
	var hint_btn := _find_button_with_icon(lv.hud.overlay, "hint")
	_expect(hint_btn != null, "derrota oferece dica")
	var hints_before := Game.hints()
	hint_btn.pressed.emit()
	await _wait(0.5)
	lv = main._current
	_expect(lv.hint_shown, "dica aparece ao recomeçar")
	_expect(Game.hints() == hints_before - 1, "dica custa 1")

	# vence com a solução → tela de vitória → próxima fase
	for s in lv.solution_strokes():
		lv.drawer.feed_stroke(s)
		await get_tree().physics_frame
	await _wait_until(func(): return lv.state == Level.State.WON, 10.0)
	_expect(lv.state == Level.State.WON, "solução vence")
	await _wait(1.8)
	_expect(Game.is_unlocked(1), "vitória libera a fase 2")
	await _press_text("Próxima")
	await _wait(0.6)
	_expect(main._current is Level and (main._current as Level).index == 1, "Próxima → fase 1-2")

	# recomeçar e voltar ao mapa pela pausa
	lv = main._current
	lv.hud.action.emit("restart")
	await _wait(0.3)
	lv = main._current
	lv.hud._open_pause()
	await _wait(0.2)
	await _press_text("Mapa")
	await _wait(0.6)
	_expect(main._current is LevelSelect, "pausa → Mapa")

	# troca de mundo no mapa
	var map: LevelSelect = main._current
	map._next.pressed.emit()
	await _wait(0.3)
	_expect(map.world_id == 2, "seta → mundo 2")

	# coleção: amigos, roupinhas (compra + equipa), conquistas
	main.go("collection", null)
	await _wait(0.6)
	_expect(main._current is CollectionScreen, "abre a coleção")
	Game.data["coins"] = 500
	await _press_text("Roupinhas")
	await _press_text("60")
	_expect(Game.owns("bone") or Game.owns("laco"), "compra um acessório")
	_expect(Game.equipped("capi") != "", "equipa na Capitu")
	await _press_text("Conquistas")
	await _press_text("Amigos")

	# ajustes: alterna opções e cancela o apagar progresso
	main.go("settings", null)
	await _wait(0.6)
	_expect(main._current is SettingsScreen, "abre os ajustes")
	await _press_text("Reduzir movimento", true)
	_expect(Game.setting("reduce_motion") == true, "liga reduzir movimento")
	await _press_text("Apagar progresso")
	await _press_text("Cancelar")
	_expect(Game.is_unlocked(1), "cancelar não apaga o progresso")

	# volta ao título pelo botão voltar do Android
	main._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await _wait(0.6)
	_expect(main._current is TitleScreen, "voltar → título")

	print("==== FLUXO: %s ====" % ("OK" if failures == 0 else "%d falhas" % failures))
	await get_tree().process_frame
	get_tree().quit(1 if failures > 0 else 0)


func _expect(cond: bool, what: String) -> void:
	print(("  ok   " if cond else "  FALHOU ") + what)
	if not cond:
		failures += 1


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func _wait_until(cond: Callable, timeout: float) -> void:
	var t := 0.0
	while not cond.call() and t < timeout:
		await get_tree().physics_frame
		t += 1.0 / 60.0


## Aperta o primeiro botão visível cujo texto contém `text`.
func _press_text(text: String, contains: bool = false) -> void:
	var b := _find_button(get_tree().root, text, contains)
	if b == null:
		_expect(false, "botão \"%s\" encontrado" % text)
		return
	b.pressed.emit()
	await _wait(0.6)


func _find_button(n: Node, text: String, contains: bool) -> Button:
	if n is Button and (n as Button).is_visible_in_tree() and not (n as Button).disabled:
		var t := (n as Button).text.strip_edges()
		if t == text or (contains and t.contains(text)):
			return n
	for c in n.get_children():
		if c.is_queued_for_deletion():
			continue
		var r := _find_button(c, text, contains)
		if r != null:
			return r
	return null


func _find_button_with_icon(n: Node, icon: String) -> Button:
	if n == null:
		return null
	if n is Button:
		for c in n.get_children():
			if c is UiIcon and (c as UiIcon).icon == icon:
				return n
	for c in n.get_children():
		var r := _find_button_with_icon(c, icon)
		if r != null:
			return r
	return null
