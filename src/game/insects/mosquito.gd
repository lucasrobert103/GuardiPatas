class_name Mosquito
extends Insect
## Mosquito Zizi: pequeno, rápido e insistente; quase não empurra, mas acha qualquer fresta.
## Bloqueio justo: abrigo sem brechas maiores que o corpinho dele (~14 px).


func _configure() -> void:
	radius = 7.0
	max_speed = 325.0
	agility = 4.8
	mass = 0.05
	linear_damp = 0.5


func _behave(_delta: float) -> void:
	_fly_toward(target_point(), 75.0, 1.4)
