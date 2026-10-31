class_name Moth
extends Insect
## Mariposa Lumi: atraída pela luz. Enquanto houver lâmpada acesa, ela dá voltas nela;
## quando a lâmpada apaga, vai devagarinho atrás do bichinho.
## Bloqueio justo: proteger o bichinho para o momento em que a luz apagar.


func _configure() -> void:
	radius = 12.0
	max_speed = 165.0
	agility = 2.3
	mass = 0.12
	linear_damp = 0.6


func _behave(_delta: float) -> void:
	var lamp: Node2D = level.nearest_lit_lamp(global_position)
	if lamp == null:
		art.excited = false
		_fly_toward(target_point(), 60.0, 0.8)
		return
	art.excited = true
	_target = null
	_lure_memory = true
	if global_position.distance_to(lamp.global_position) > 180:
		_fly_toward(lamp.global_position, 20, 0.8)
		return
	var to := lamp.global_position - global_position
	var d := to.length()
	var orbit := 55.0 + 15.0 * sin(_t * 1.3 + _phase)
	var radial := to / maxf(d, 1.0)
	var desired := radial * clampf((d - orbit) * 3.0, -max_speed, max_speed) + radial.orthogonal() * max_speed * 0.9
	_steer_velocity(desired, agility)
