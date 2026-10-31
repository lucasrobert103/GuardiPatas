class_name Ant
extends Insect
## Formiga Tilim: anda em fila pelo chão, sobe degraus e rampas suaves, mas não paredes.
## Não voa e não colide com as companheiras. Bloqueio justo: parede ou vala;
## água leva as formigas embora.


func _configure() -> void:
	radius = 8.0
	max_speed = 140.0
	agility = 6.0
	mass = 0.36
	flying = false


func _behave(_delta: float) -> void:
	_walk_toward(target_point(), 18.0, 140.0)
	if absf(linear_velocity.x) > 20.0 and fmod(_t + _phase, 0.35) < get_physics_process_delta_time():
		Sfx.play("ant_step", -18.0, 1.0, 0.25, 0.05)
