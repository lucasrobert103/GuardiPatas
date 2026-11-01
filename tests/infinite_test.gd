extends Node
## Modo Infinito: o gerador é determinístico, fica mais difícil com as fases e o diretor
## SEMPRE entrega uma fase em que a solução vence e "sem linha" perde.
##   godot --headless --fixed-fps 60 --path . res://tests/infinite_test.tscn [-- --stages=30]
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
	var stages := 24
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--stages="):
			stages = int(a.substr(9))
	Infinite.run = {"seed": 4242, "stage": 1, "hearts": 3, "coins": 0, "variant": 0}
	check(Infinite.generate(5, 0) == Infinite.generate(5, 0), "gerador determinístico")
	check(Infinite.generate(5, 0) != Infinite.generate(6, 0), "fases diferentes")
	var easy := Infinite.generate(1, 0)
	var hard := Infinite.generate(30, 0)
	var c_easy := 0
	var c_hard := 0
	for n in easy["nests"]: c_easy += int(n["count"])
	for n in hard["nests"]: c_hard += int(n["count"])
	check(c_hard > c_easy, "fase 30 tem mais insetos que a 1 (%d > %d)" % [c_hard, c_easy])
	var director := InfiniteDirector.new()
	add_child(director)
	var first_try := 0
	var templates := {}
	for s in range(1, stages + 1):
		var v := InfiniteValidator.new()
		add_child(v)
		v.check(Infinite.generate(s, 0))
		var r: Array = await v.done
		v.queue_free()
		if r[1]:
			first_try += 1
		templates[str(r[0].get("template", ""))] = true
		director.prepare(s)
		while not director.is_ready(s):
			await director.prepared
		var data := director.take(s)
		# confere de novo, do jeito do jogador: a fase entregue precisa ter solução
		var v2 := InfiniteValidator.new()
		add_child(v2)
		v2.check(data)
		var r2: Array = await v2.done
		v2.queue_free()
		check(r2[1], "fase %d entregue tem solução e sem linha perde (molde %s)" % [s, data.get("template", "?")])
		print("  infinito %2d  molde=%-7s  1a_tentativa=%s  insetos=%d" % [s, data.get("template", "?"), "sim" if r[1] else "não", _count(data)])
	check(first_try >= int(stages * 0.6), "maioria das fases válida já na 1ª variação (%d de %d)" % [first_try, stages])
	check(templates.size() >= 3, "vários moldes aparecem (%s)" % str(templates.keys()))
	# corrida: corações e recorde
	Game.data["infinite"]["best"] = 0
	Infinite.start_run()
	var before := Game.coins()
	var res := Infinite.cleared()
	check(res["record"] and Infinite.best() == 1 and Game.coins() > before, "vencer soma recorde e moedas")
	for i in 4: Infinite.cleared()
	check(Infinite.best() == 5, "recorde acompanha a sequência")
	check(Infinite.failed() == 2 and Infinite.active(), "perder tira um coração")
	Infinite.failed()
	Infinite.failed()
	check(not Infinite.active(), "sem corações, a corrida acaba")
	print("==== INFINITO: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)


func _count(d: Dictionary) -> int:
	var n := 0
	for x in d["nests"]: n += int(x["count"])
	return n
