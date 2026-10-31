class_name Insect
extends RigidBody2D
## Base dos insetos. Cada espécie sobrescreve `_behave()`.
## Regras de justiça (docs/06-insetos.md): todo inseto tem alvo visível, velocidade
## de referência fixa e uma forma clara de ser bloqueado. Nada de aleatoriedade que decida a fase.

var level: Level
var kind := "bee"
var radius := 10.0
var max_speed := 200.0
var agility := 3.0
var flying := true
var calmed := false
var art: InsectArt
var shape: CircleShape2D
## Não é levado pela água (caranguejo, água-viva, baiacu).
var water_proof := false
## Prefere o pote de mel enquanto houver mel (abelhas, vespas, brocas).
var lured_by_honey := false

## Identidade estável dentro da tentativa: distribui rotas sem depender do RNG global.
var tactic_id := 0
var navigator := InsectNavigator.new()
var _target: Animal
var _target_timer := 0.0
var _lure_memory := false
var _lure_origin := Vector2.ZERO

var _t := 0.0
var _phase := 0.0
var _daze := 0.0
var _stuck := 0.0
var _slide := 1.0
var _slide_timer := 0.0
var _bonk_cd := 0.0
const RAM_RECOVERY := 1.55
var _ram_charge := 0.0
var _ram_cooldown := 0.0
var _ram_direction := 0.0


func setup(p_level: Level, p_kind: String) -> void:
	level = p_level
	kind = p_kind
	_configure()
	collision_layer = Layers.FLYER if flying else Layers.WALKER
	collision_mask = Layers.FLYER_MASK if flying else Layers.WALKER_MASK
	gravity_scale = 0.0 if flying else 1.0
	lock_rotation = true
	contact_monitor = true
	max_contacts_reported = 6
	can_sleep = false
	var mat := PhysicsMaterial.new()
	# andarilhos: atrito zero; o controle de velocidade em _walk_toward faz o papel do "pé"
	mat.friction = 0.3 if flying else 0.0
	mat.bounce = 0.25 if flying else 0.0
	physics_material_override = mat
	var cs := CollisionShape2D.new()
	shape = CircleShape2D.new()
	shape.radius = radius
	cs.shape = shape
	add_child(cs)
	art = InsectArt.new()
	art.kind = kind
	art.radius = radius
	add_child(art)
	body_entered.connect(_on_body_entered)


## Subclasses ajustam atributos aqui.
func _configure() -> void:
	pass


func _physics_process(delta: float) -> void:
	_t += delta
	_bonk_cd = maxf(_bonk_cd - delta, 0.0)
	_target_timer -= delta
	if level == null:
		return
	if calmed:
		_calm_behavior(delta)
	elif _daze > 0.0:
		_daze -= delta
		art.dazed = true
		art.aiming = false
		art.aim_vector = Vector2.ZERO
		art.work_progress = 0
	else:
		art.dazed = false
		_behave(delta)
	if absf(linear_velocity.x) > 8.0:
		art.facing = signf(linear_velocity.x)
	if global_position.y > 1700.0 or global_position.y < -900.0 or absf(global_position.x - 360.0) > 1400.0:
		queue_free()


func _behave(_delta: float) -> void:
	pass


func daze(seconds: float) -> void:
	_daze = maxf(_daze, seconds)


## Fim de fase: os insetos desistem de forma simpática (voam para longe / tiram um cochilo).
func calm_down() -> void:
	calmed = true
	art.calmed = true
	art.aiming = false
	art.work_progress = 0
	art.aim_vector = Vector2.ZERO


func _calm_behavior(_delta: float) -> void:
	if flying:
		var away := Vector2(signf(global_position.x - 360.0) * 0.6, -1.0).normalized()
		_steer_velocity(away * max_speed * 0.8, 2.0)
	else:
		linear_velocity.x = move_toward(linear_velocity.x, 0.0, 400.0 * get_physics_process_delta_time())


## Água leva o inseto embora (sem violência: ele sai boiando numa bolha).
func wash_away() -> void:
	if is_queued_for_deletion() or water_proof:
		return
	Fx.splash(level.fx_layer, global_position)
	Sfx.play("splash", -4.0, 1.2, 0.2, 0.08)
	queue_free()


# ------------------------------------------------------------------ helpers de movimento
func set_tactic_id(value: int) -> void:
	tactic_id = value
	_phase = fmod(value * 2.399963, TAU)
	_slide = 1.0 if value % 2 == 0 else -1.0


func target_point() -> Vector2:
	if lured_by_honey:
		var h: HoneyPot = level.nearest_honey(global_position)
		if h != null:
			remember_lure(h.global_position)
			if global_position.distance_to(h.global_position) < 70.0:
				h.eat(get_physics_process_delta_time())
			return h.global_position
	# A isca é uma decisão estratégica: ao acabar, o inseto mantém o cheiro
	# do amigo mais próximo dali, em vez de adivinhar um alvo do outro lado da fase.
	if _lure_memory:
		if not is_instance_valid(_target): _target = level.nearest_animal(_lure_origin)
		return _target.global_position if is_instance_valid(_target) else global_position
	if not is_instance_valid(_target) or _target_timer <= 0:
		_target_timer = 0.65 + (tactic_id % 3) * 0.08
		var best := _target if is_instance_valid(_target) else null
		var score := _target_score(best) * 0.78 if best != null else INF
		for animal in level.animals:
			if not is_instance_valid(animal): continue
			var candidate := _target_score(animal)
			if candidate < score:
				best = animal
				score = candidate
		_target = best
	return _target.global_position if is_instance_valid(_target) else global_position


func remember_lure(point: Vector2) -> void:
	_target = null
	_lure_memory = true
	_lure_origin = point


func _target_score(animal: Animal) -> float:
	var score := global_position.distance_to(animal.global_position)
	if flying:
		if not InsectNavigator.obstacle(self, global_position, animal.global_position).is_empty(): score += 180
	elif animal.global_position.y < global_position.y - 100:
		score += 220 # andarilhos não confundem um alvo alto com um caminho acessível
	return score


func predicted_target(seconds: float) -> Vector2:
	var point := target_point()
	if is_instance_valid(_target):
		point += (_target.linear_velocity * seconds).limit_length(70)
	return point


func _steer_velocity(desired: Vector2, gain: float) -> void:
	apply_central_force((desired - linear_velocity) * mass * gain)


## Perseguição com zigue-zague leve e "contorno" quando a barreira o segura:
## o inseto desliza pela superfície procurando uma brecha — por isso abrigos sem
## frestas funcionam e abrigos com frestas falham, de forma previsível.
func _fly_toward(point: Vector2, wobble: float, slide_strength: float) -> void:
	# Brocas e baiacus pressionam a tinta com sua habilidade própria; os outros
	# voadores procuram a ponta aberta. Todos continuam colidindo com a linha.
	var route := navigator.next_point(self, point, get_physics_process_delta_time(), kind != "broca" and kind != "drillfish" and kind != "puffer")
	var to := route - global_position
	var dist := to.length()
	if dist < 1.0:
		return
	var dir := to / dist
	var navigating := navigator.waypoint.is_finite()
	var speed := minf(max_speed, dist * 4) if navigating else max_speed
	var desired := dir * speed
	desired += dir.orthogonal() * sin(_t * 7.0 + _phase) * wobble * (minf(1, dist / 100) * 0.25 if navigating else 1.0)
	if navigating:
		_stuck = 0
	elif linear_velocity.length() < max_speed * 0.3:
		_stuck += get_physics_process_delta_time()
	else:
		_stuck = maxf(_stuck - get_physics_process_delta_time() * 2.0, 0.0)
	_slide_timer -= get_physics_process_delta_time()
	if _slide_timer <= 0.0:
		_slide_timer = 2.5 + fmod(_phase, 1.5)
		_slide = -_slide
	if _stuck > 0.4:
		desired += dir.orthogonal() * _slide * max_speed * slide_strength
	_steer_velocity(desired.limit_length(max_speed), agility)


## Caminhada: força horizontal + escalada de degraus baixos.
func _walk_toward(point: Vector2, climb_height: float, push_force: float) -> void:
	var dir := signf(point.x - global_position.x)
	if dir == 0.0:
		return
	var dvx := dir * max_speed - linear_velocity.x
	var f := clampf(dvx * mass * agility, -push_force, push_force)
	apply_central_force(Vector2(f, 0.0))
	if climb_height <= 0.0 or not _on_ground():
		return
	var space := get_world_2d().direct_space_state
	var foot := global_position + Vector2(0, radius * 0.6)
	var ahead := Vector2(dir * (radius + 6.0), 0.0)
	var q := PhysicsRayQueryParameters2D.create(foot, foot + ahead, Layers.TERRAIN | Layers.LINE | Layers.PROP, [get_rid()])
	if space.intersect_ray(q).is_empty():
		return
	var top := global_position + Vector2(0, -climb_height)
	var q2 := PhysicsRayQueryParameters2D.create(top, top + ahead, Layers.TERRAIN | Layers.LINE | Layers.PROP, [get_rid()])
	if space.intersect_ray(q2).is_empty():
		linear_velocity.y = -sqrt(2.0 * 980.0 * climb_height) * 0.9


## Besouros e caranguejos recuam a força durante o aviso e golpeiam o obstáculo
## realmente em contato. Pedra e Tinta Firme não recebem impulso.
func _ram_barrier(delta: float, impulse: float) -> bool:
	_ram_cooldown = maxf(0, _ram_cooldown - delta)
	var barrier: RigidBody2D
	for body in get_colliding_bodies():
		if (body is DrawnLine or body is Crate) and not body.freeze:
			barrier = body
			break
	if barrier == null or _ram_cooldown > 0:
		_ram_charge = 0
		art.aiming = false
		art.aim_progress = 0
		return false
	if _ram_charge == 0:
		_ram_direction = signf(target_point().x - global_position.x)
	_ram_charge += delta
	art.aiming = true
	art.aim_progress = minf(1, _ram_charge / 0.65)
	_steer_velocity(Vector2(0, linear_velocity.y), 8)
	if _ram_charge >= 0.65:
		barrier.apply_impulse(Vector2(_ram_direction * impulse, 0), global_position - barrier.global_position)
		apply_central_impulse(Vector2(-_ram_direction * impulse * 0.08, 0))
		_ram_charge = 0
		_ram_cooldown = RAM_RECOVERY
		art.aiming = false
		art.squash = 1
		Sfx.play("bonk", -7, 0.7, 0.1)
	return true


func _on_ground() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, radius + 4.0), Layers.TERRAIN | Layers.LINE | Layers.PROP, [get_rid()])
	return not space.intersect_ray(q).is_empty()


func _on_body_entered(body: Node) -> void:
	if body is DrawnLine and _bonk_cd <= 0.0:
		_bonk_cd = 0.5
		art.squash = 1.0
		Sfx.play("bonk", -10.0, 1.0 + randf_range(-0.2, 0.2), 0.0, 0.07)
