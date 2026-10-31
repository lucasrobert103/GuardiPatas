class_name HomeBall
extends RigidBody2D
## Bola física da sala. Pode ser agarrada, arrastada e lançada com o dedo.
const RADIUS := 38.0
const HOME_LAYER := 256
var arena: StaticBody2D
var bounds := Rect2()
var _walls: Array[CollisionShape2D] = []


func _ready() -> void:
	collision_layer = HOME_LAYER
	collision_mask = HOME_LAYER
	gravity_scale = 0.8
	mass = 0.6
	linear_damp = 0.12
	angular_damp = 0.5
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	var material := PhysicsMaterial.new()
	material.bounce = 0.72
	material.friction = 0.45
	physics_material_override = material
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	arena = StaticBody2D.new()
	arena.collision_layer = HOME_LAYER
	arena.collision_mask = HOME_LAYER
	get_parent().add_child(arena)
	for i in 4:
		var wall := CollisionShape2D.new()
		wall.shape = RectangleShape2D.new()
		arena.add_child(wall)
		_walls.append(wall)


func configure(rect: Rect2) -> void:
	bounds = rect
	if _walls.is_empty():
		return
	var geometries := [Rect2(rect.position.x - 16, rect.position.y, 16, rect.size.y), Rect2(rect.end.x, rect.position.y, 16, rect.size.y), Rect2(rect.position.x, rect.end.y, rect.size.x, 16), Rect2(rect.position.x, rect.position.y - 16, rect.size.x, 16)]
	for i in 4:
		var shape := _walls[i].shape as RectangleShape2D
		shape.size = geometries[i].size
		_walls[i].position = geometries[i].get_center()
	place(Vector2(clampf(position.x, rect.position.x + RADIUS, rect.end.x - RADIUS), clampf(position.y, rect.position.y + RADIUS, rect.end.y - RADIUS)))


func place(point: Vector2) -> void:
	position = point
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	# Sincroniza também o servidor: uma atualização física antiga não pode
	# recolocar a bola fora das novas paredes depois de girar a tela.
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, global_transform)
	reset_physics_interpolation()


func launch(velocity: Vector2) -> void:
	freeze = false
	sleeping = false
	linear_velocity = velocity.limit_length(1000)
	angular_velocity = clampf(velocity.x / 80, -9, 9)


func _draw() -> void:
	HomeArt.ball(self, Vector2.ZERO, RADIUS)
