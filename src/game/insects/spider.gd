class_name Spider
extends Insect
## Aranha Fiandeira: anda pelo "teto" (na altura do ninho) até ficar em cima do bichinho
## e então DESCE reto pelo fio. Paredes laterais não adiantam: precisa de teto.

var anchor_y := 0.0
var _descending := false


func _configure() -> void:
	radius = 11.0
	max_speed = 120.0
	agility = 4.0
	mass = 0.2


func _behave(_delta: float) -> void:
	if anchor_y == 0.0:
		anchor_y = global_position.y
	var t := target_point()
	var dx := t.x - global_position.x
	if not _descending and absf(dx) > 8.0:
		_steer_velocity(Vector2(signf(dx) * max_speed, (anchor_y - global_position.y) * 4.0), agility)
	else:
		_descending = true
		_steer_velocity(Vector2(clampf(dx * 2.0, -40.0, 40.0), max_speed * 0.8), agility)
	art.thread = global_position.y - anchor_y
