extends Node
## Provas físicas da IA, com barreiras e saídas reais. Sem comparar só flags do modelo.
var passed := 0
var failures := 0


func check(value: bool, message: String) -> void:
	if value: passed += 1
	else:
		failures += 1
		print("FALHOU: ", message)


func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame


func fixture(target: Vector2 = Vector2(570, 600)) -> Level:
	var level := Level.new()
	level.setup(-1, {"id": "tactics-test", "world": 1, "mode": "custom", "survive": 90,
		"animals": [{"type": "nino", "pos": [target.x, target.y]}],
		"terrain": [{"poly": [[-400, 1000], [1120, 1000], [1120, 1800], [-400, 1800]], "style": "ground"}]}, false)
	add_child(level)
	level.set_physics_process(false)
	for animal in level.animals:
		animal.collision_layer = 0
		animal.collision_mask = 0
		animal.set_physics_process(false)
	return level


func spawn(level: Level, kind: String, point: Vector2) -> Insect:
	var bug := Nest.make_insect(kind)
	bug.setup(level, kind)
	bug.position = point
	level.add_insect(bug)
	return bug


func line(level: Level, points: Array, fixed: bool = true) -> DrawnLine:
	var barrier := DrawnLine.new()
	barrier.build(PackedVector2Array(points), Palette.INK, fixed)
	level.world.add_child(barrier)
	level.lines.append(barrier)
	return barrier


func stone(level: Level, points: Array) -> Terrain:
	var terrain := Terrain.new()
	terrain.setup(PackedVector2Array(points), "stone", 1)
	level.world.add_child(terrain)
	return terrain


func close(level: Level) -> void:
	level.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	var level := fixture()
	stone(level, [Vector2(320, 450), Vector2(420, 450), Vector2(420, 750), Vector2(320, 750)])
	var bee := spawn(level, "bee", Vector2(150, 600))
	var crossed := false
	var clipped := false
	for i in 360:
		await get_tree().physics_frame
		crossed = crossed or bee.position.x > 450
		clipped = clipped or Rect2(323, 453, 94, 294).has_point(bee.position)
	check(crossed, "abelha contorna pedra e alcança o outro lado")
	check(not clipped and bee.get_collision_exceptions().is_empty(), "contorno não atravessa pedra nem desliga colisões")
	await close(level)

	level = fixture(Vector2(570, 575))
	line(level, [Vector2(360, 100), Vector2(360, 550)])
	line(level, [Vector2(360, 600), Vector2(360, 995)])
	var mosquito := spawn(level, "mosquito", Vector2(150, 700))
	var gap_crossing := false
	var previous := mosquito.position
	for i in 240:
		await get_tree().physics_frame
		if previous.x < 360 and mosquito.position.x >= 360 and mosquito.position.y > 560 and mosquito.position.y < 590: gap_crossing = true
		previous = mosquito.position
	check(gap_crossing, "mosquito encontra e atravessa fresta compatível com o corpo")
	await close(level)

	level = fixture()
	stone(level, [Vector2(0, 800), Vector2(720, 800), Vector2(720, 1000), Vector2(0, 1000)])
	line(level, [Vector2(430, 800), Vector2(430, 500), Vector2(650, 500), Vector2(650, 560)])
	mosquito = spawn(level, "mosquito", Vector2(300, 600))
	var entered := false
	for i in 720:
		await get_tree().physics_frame
		entered = entered or mosquito.position.distance_to(Vector2(570, 600)) < 45
	check(entered, "mosquito percorre vários cantos para explorar um abrigo incompleto")
	await close(level)

	level = fixture()
	var circle: Array = []
	for i in 49: circle.append(Vector2(570, 600) + Vector2.from_angle(TAU * i / 48.0) * 90)
	line(level, circle)
	mosquito = spawn(level, "mosquito", Vector2(150, 600))
	var closest := INF
	for i in 360:
		await get_tree().physics_frame
		closest = minf(closest, mosquito.position.distance_to(Vector2(570, 600)))
	check(closest > 80 and mosquito.get_collision_exceptions().is_empty(), "abrigo fechado continua impedindo mosquito inteligente")
	await close(level)

	level = fixture(Vector2(470, 977))
	stone(level, [Vector2(300, 860), Vector2(720, 860), Vector2(720, 1000), Vector2(560, 1000), Vector2(560, 900), Vector2(300, 900)])
	mosquito = spawn(level, "mosquito", Vector2(90, 804))
	await frames(300)
	check(mosquito.position.x > 350 and mosquito.position.y > 900, "navegação reconhece a entrada côncava da caverna")
	await close(level)

	level = fixture(Vector2(390, 600))
	circle.clear()
	for i in 49: circle.append(Vector2(390, 600) + Vector2.from_angle(TAU * i / 48.0) * 75)
	line(level, circle)
	var exposed := Animal.new()
	exposed.position = Vector2(430, 810)
	exposed.setup("nino", level, false)
	exposed.collision_layer = 0
	exposed.collision_mask = 0
	level.world.add_child(exposed)
	level.animals.append(exposed)
	bee = spawn(level, "bee", Vector2(150, 600))
	bee.set_physics_process(false)
	await frames(2)
	check(bee.target_point() == exposed.position, "batedora prefere amigo exposto a alvo mais perto protegido")
	var honey := HoneyPot.new()
	honey.position = Vector2(200, 620)
	honey.setup(6)
	level.world.add_child(honey)
	level.honeys.append(honey)
	check(bee.target_point() == honey.position, "mel tem prioridade sobre escolha de alvo exposto")
	honey.amount = 0
	var remembered := bee.target_point()
	check(remembered == level.animals[0].position, "ao acabar o mel persegue o amigo próximo da isca")
	await close(level)

	level = fixture(Vector2(410, 600))
	var wasp := spawn(level, "wasp", Vector2(210, 600)) as Wasp
	var warnings := 0
	var dashed := false
	var locked := Vector2.ZERO
	for i in 70:
		await get_tree().physics_frame
		if wasp.art.aiming:
			warnings += 1
			if wasp._timer < 0.2 and locked == Vector2.ZERO:
				locked = wasp._dash_dir
				level.animals[0].position += Vector2(0, 160)
		if wasp.state == Wasp.State.DASH:
			dashed = true
			break
	check(dashed and warnings >= 38, "vespa avisa por pelo menos 0,63 s antes da investida")
	check(locked != Vector2.ZERO and wasp._dash_dir.is_equal_approx(locked), "direção fica travada no final do aviso em vez de seguir o alvo invisivelmente")
	check(wasp.linear_velocity.length() > 700, "investida tem impacto maior que voo normal")
	wasp.calm_down()
	check(not wasp.art.aiming and wasp.art.aim_vector == Vector2.ZERO, "fim de fase cancela avisos de ataque")
	await close(level)

	level = fixture(Vector2(600, 969))
	var barrier := line(level, [Vector2(345, 850), Vector2(345, 983)], false)
	barrier.mass = 9
	var beetle := spawn(level, "beetle", Vector2(280, 980))
	var saw_charge := false
	var rammed := false
	for i in 300:
		await get_tree().physics_frame
		saw_charge = saw_charge or beetle.art.aiming
		if beetle._ram_cooldown > 1.9:
			rammed = true
			break
	check(saw_charge and rammed, "besouro carrega golpe visível antes de empurrar a barreira")
	await frames(20)
	check(barrier.position.x > 353 or absf(barrier.rotation) > 0.1, "golpe desloca ou inclina tinta sem apoio")
	await close(level)

	level = fixture(Vector2(600, 970))
	barrier = line(level, [Vector2(345, 850), Vector2(345, 983)])
	var original := barrier.global_transform
	beetle = spawn(level, "beetle", Vector2(280, 980))
	await frames(240)
	check(barrier.global_transform.is_equal_approx(original) and beetle.position.x < 345, "Tinta Firme bloqueia inseto pesado sem ser deslocada")
	await close(level)

	level = fixture(Vector2(600, 970))
	stone(level, [Vector2(350, 890), Vector2(380, 890), Vector2(380, 1000), Vector2(350, 1000)])
	var cricket := spawn(level, "cricket", Vector2(250, 980)) as Cricket
	var announced := false
	crossed = false
	for i in 300:
		await get_tree().physics_frame
		announced = announced or cricket.art.aiming
		crossed = crossed or (cricket.position.x > 350 and cricket.position.x < 390 and cricket.position.y < 881)
	check(announced and crossed and cricket.position.x > 400, "grilo prepara salto para superar obstáculo real")
	await close(level)

	level = fixture(Vector2(650, 990))
	cricket = spawn(level, "cricket", Vector2(150, 980)) as Cricket
	announced = false
	for i in 150:
		await get_tree().physics_frame
		announced = announced or cricket.art.aiming
	check(not announced, "grilo não desperdiça pulos no caminho plano")
	await close(level)

	level = fixture(Vector2(360, 900))
	line(level, [Vector2(300, 700), Vector2(440, 700)])
	var spider := spawn(level, "spider", Vector2(360, 500)) as Spider
	var retried := false
	var found_side := false
	for i in 720:
		await get_tree().physics_frame
		retried = retried or spider.state == Spider.State.REEL
		found_side = found_side or (spider._attempt > 0 and spider.position.y > 735)
	check(retried, "aranha recolhe o fio quando o teto impede a descida")
	check(found_side, "aranha tenta outra lateral sem atravessar o teto")
	await close(level)


	level = fixture()
	var first_layer := line(level, [Vector2(350, 100), Vector2(350, 995)])
	var second_layer := line(level, [Vector2(430, 100), Vector2(430, 995)])
	var drill := spawn(level, "broca", Vector2(270, 600))
	var first_hole := -1.0
	var second_hole := -1.0
	var saw_drill_progress := false
	for i in 480:
		await get_tree().physics_frame
		saw_drill_progress = saw_drill_progress or drill.art.work_progress > 0.2
		if first_hole < 0 and not first_layer.holes.is_empty(): first_hole = i / 60.0
		if second_hole < 0 and not second_layer.holes.is_empty(): second_hole = i / 60.0
	check(saw_drill_progress and first_hole >= 2.15, "broca mostra progresso e precisa completar o tempo de contato")
	check(second_hole > first_hole + 2.15, "cada camada exige uma nova perfuração completa")
	await close(level)

	level = fixture(Vector2(760, 300))
	line(level, [Vector2(330, 100), Vector2(330, 995)])
	var puffer := spawn(level, "puffer", Vector2(260, 600)) as Puffer
	await frames(240)
	check(puffer.inflate > 0.9 and puffer.shape.radius > 25, "baiacu incha ao pressionar a barreira mesmo longe do bichinho")
	check(puffer.position.x < 330, "inchar não permite atravessar a tinta")
	await close(level)

	var trajectories: Array = []
	for run in 2:
		seed(123 + run * 99)
		level = fixture()
		bee = spawn(level, "bee", Vector2(150, 600))
		var trajectory: Array[Vector2] = []
		for i in 3:
			await frames(30)
			trajectory.append(bee.position)
		trajectories.append(trajectory)
		await close(level)
	var repeatable := true
	for i in 3: repeatable = repeatable and trajectories[0][i].distance_to(trajectories[1][i]) < 0.1
	check(repeatable, "mesma tentativa mantém trajetória mesmo mudando RNG global")
	print("==== TÁTICAS: %d ok, %d falhas ====" % [passed, failures])
	get_tree().quit(1 if failures else 0)
