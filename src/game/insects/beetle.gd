class_name Beetle
extends Insect
## Besouro Bolota: lento, pesado e teimoso. Não escala, mas EMPURRA linhas e caixas leves.
## Bloqueio justo: barreira pesada (mais tinta) ou travada contra o terreno.


func _configure() -> void:
	radius = 19.0
	max_speed = 60.0
	agility = 5.0
	mass = 3.0
	flying = false


func _behave(_delta: float) -> void:
	_walk_toward(target_point(), 0.0, 1100.0)
	if absf(linear_velocity.x) > 10.0 and fmod(_t + _phase, 0.5) < get_physics_process_delta_time():
		Sfx.play("beetle_step", -12.0, 1.0, 0.15, 0.1)
