class_name Caterpillar
extends Insect
## Lagarta Gulosa: lenta, mas sobe por QUALQUER superfície vertical (inclusive a sua linha)
## e desce do outro lado. Paredes não a seguram; só um abrigo fechado ou a água.

var _climbing := false


func _configure() -> void:
	radius = 9.0
	max_speed = 50.0
	agility = 6.0
	mass = 0.25
	flying = false


func _behave(_delta: float) -> void:
	var target := target_point()
	var dir := signf(target.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	var space := get_world_2d().direct_space_state
	var ahead := Vector2(dir * (radius + 5.0), 0.0)
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + ahead, Layers.TERRAIN | Layers.LINE | Layers.PROP, [get_rid()])
	var wall := not space.intersect_ray(q).is_empty()
	if wall:
		# gruda na parede e sobe
		_climbing = true
		gravity_scale = 0.0
		linear_velocity = Vector2(dir * 12.0, -max_speed)
	elif _climbing:
		# chegou ao topo: avança por cima e volta a sentir a gravidade
		_climbing = false
		gravity_scale = 1.0
		linear_velocity = Vector2(dir * max_speed * 1.5, -30.0)
	else:
		gravity_scale = 1.0
		_walk_toward(target, 10.0, 120.0)
	art.excited = _climbing
