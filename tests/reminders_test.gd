extends Node
## Recados dos bichinhos: horários (nunca à noite, 2 h depois de jogar, N por dia),
## textos montados com o progresso (em todos os idiomas), Ajustes e jogo sem o plugin.
##   godot --headless --path . res://tests/reminders_test.tscn
var passed := 0
var failures := 0


func check(v: bool, msg: String) -> void:
	if v:
		passed += 1
	else:
		failures += 1
		print("FALHOU: ", msg)


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	Legal.accept()
	Game.set_setting("lang", "pt_BR")
	Game.data["met"] = ["capi", "pingo", "lulu"]

	# sem o plugin (computador): nada quebra e os lembretes ficam desligados
	check(not Reminders.available(), "sem plugin no computador")
	check(not Reminders.should_ask(), "sem plugin não convida")
	Reminders.reschedule()
	check(Reminders.per_day() == 3, "padrão: 3 recados por dia")

	# textos
	var msgs := Reminders.messages()
	check(msgs.size() >= 14, "muitos recados diferentes (%d)" % msgs.size())
	var all := ""
	for m in msgs:
		check(str(m[0]) != "" and str(m[1]).length() > 15 and not str(m[0]).contains("%") and not str(m[1]).contains("%"), "recado completo: %s" % m[0])
		all += str(m[0]) + " " + str(m[1]) + " "
	for name in ["Capitu", "Pingo", "Lulu"]:
		check(all.contains(name), "recados chamam %s pelo nome" % name)
	for word in ["ajuda", "Desafio do Dia", "Casinha", "Ateliê", "Fase"]:
		check(all.contains(word), "recado sobre %s" % word)
	for bad in ["compr", "loja", "moeda", "R$"]:
		check(not all.to_lower().contains(bad), "nenhum recado fala em %s" % bad)
	Game.set_setting("lang", "en")
	var en := ""
	for m in Reminders.messages():
		en += str(m[0]) + " " + str(m[1])
	check(en.contains("needs help") and en.contains("Daily Challenge"), "recados em inglês")
	Game.set_setting("lang", "pt_BR")

	# horários: 3 dias, N por dia, só das 9h30 às 20h, nunca menos de 2 h depois de jogar
	for per in [1, 3, 5]:
		for hour in [0, 7, 9, 13, 19, 23]:
			var now: Dictionary = {"hour": hour, "minute": 10, "second": 0}
			var plan := Reminders.make_plan(now, per, 1234 + hour, msgs)
			var now_sec: int = hour * 3600 + 600
			var by_day := {}
			var ok_window := true
			var ok_gap := true
			for item in plan:
				var abs_sec: int = now_sec + int(item["delay"])
				var day: int = abs_sec / 86400
				var tod: float = (abs_sec % 86400) / 3600.0
				by_day[day] = int(by_day.get(day, 0)) + 1
				if tod < Reminders.WINDOW_START or tod > Reminders.WINDOW_END:
					ok_window = false
				if int(item["delay"]) < Reminders.MIN_DELAY:
					ok_gap = false
			check(ok_window, "%d/dia às %dh: só entre 9h30 e 20h" % [per, hour])
			check(ok_gap, "%d/dia às %dh: nada nas 2 h depois de jogar" % [per, hour])
			var max_day := 0
			for d in by_day:
				max_day = maxi(max_day, int(by_day[d]))
			check(max_day <= per, "%d/dia às %dh: no máximo %d por dia" % [per, hour, per])
			check(plan.size() >= per * (Reminders.DAYS - 1) and plan.size() <= per * Reminders.DAYS, "%d/dia às %dh: agenda os próximos dias (%d)" % [per, hour, plan.size()])
	var p := Reminders.make_plan({"hour": 8, "minute": 0, "second": 0}, 5, 9, msgs)
	var titles := {}
	for item in p.slice(0, 5):
		titles[item["title"]] = true
	check(titles.size() == 5, "recados do mesmo dia não se repetem")
	check(Reminders.make_plan({"hour": 8}, 0, 1, msgs).is_empty(), "desligados: nada agendado")

	# Ajustes: seção e opções
	var st := SettingsScreen.new()
	st.theme = UiKit.make_theme()
	add_child(st)
	await get_tree().process_frame
	await get_tree().process_frame
	check(st._controls.has("reminders"), "Ajustes têm os recados dos bichinhos")
	var pick: OptionButton = st._controls["reminders"]
	check(pick.item_count == 4 and pick.selected == 2, "opções: desligados, 1, 3 e 5 por dia")
	pick.item_selected.emit(0)
	check(Reminders.per_day() == 0, "desligar nos Ajustes")
	pick.item_selected.emit(3)
	check(Reminders.per_day() == 5, "5 por dia nos Ajustes")
	st.queue_free()

	# save adulterado
	Game.data["settings"]["reminders"] = 99
	Game.data["settings"]["reminders"] = clampi(int(Game.data["settings"]["reminders"]), 0, 3)
	check(Reminders.per_day() == 5, "valor inválido fica dentro das opções")
	print("==== RECADOS: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)
