class_name Coconut
extends RigidBody2D
## Coco: preso no coqueiro até `drop` segundos de simulação; treme 1 s antes e cai reto.
## A linha pontilhada mostra onde ele vai cair. Bater num bichinho = "Bonk!" (derrota).
## Bloqueio justo: abrigo firme (ou fora da linha de queda) e telhado inclinado o desvia.

var drop := 3.0
var level: Level
var dropped := false
var _t := 0.0
var _ground_y := 1000.0
var _origin := Vector2.ZERO


func setup(p_level: Level, p_drop: float) -> void:
	level = p_level
	drop = p_drop
	collision_layer = Layers.PROP
	collision_mask = Layers.PROP_MASK
	mass = 2.5
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 4
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.3
	mat.friction = 0.6
	physics_material_override = mat
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 18.0
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_hit)


func _ready() -> void:
	_origin = position
	# onde vai cair: primeiro terreno abaixo
	await get_tree().physics_frame
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, 20), global_position + Vector2(0, 1600), Layers.TERRAIN)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		_ground_y = hit["position"].y
	queue_redraw()


func tick(sim_time: float) -> void:
	if dropped:
		return
	if sim_time >= drop:
		dropped = true
		freeze = false
		Sfx.play("ui_back", -6.0, 0.6)
	elif sim_time >= drop - 1.0:
		position = _origin + Vector2(sin(sim_time * 60.0) * 2.0, 0)


func _on_hit(body: Node) -> void:
	if body is Animal and linear_velocity.length() > 150.0 and level != null:
		level.on_animal_bonked(body as Animal)
	elif linear_velocity.length() > 200.0:
		Sfx.play("line_land", -2.0, 0.8, 0.1, 0.1)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	if not dropped:
		# trilha de queda pontilhada
		var y := 26.0
		while y < _ground_y - global_position.y - 4.0:
			draw_circle(Vector2(0, y), 2.5, Color(Palette.DANGER, 0.45), true, -1.0, true)
			y += 18.0
		var gy := _ground_y - global_position.y
		draw_line(Vector2(-12, gy - 12), Vector2(12, gy + 0), Color(Palette.DANGER, 0.7), 4.0, true)
		draw_line(Vector2(-12, gy), Vector2(12, gy - 12), Color(Palette.DANGER, 0.7), 4.0, true)
	DrawUtil.disc(self, Vector2.ZERO, 18.0, Color("8a5a39"), o, 3.0)
	for k in 3:
		draw_circle(Vector2(-6 + k * 6, -6 + (k % 2) * 3), 2.5, Color("5a3a2a"), true, -1.0, true)
	draw_line(Vector2(-9, 8), Vector2(-2, 12), Color(1, 1, 1, 0.4), 3.0, true)
