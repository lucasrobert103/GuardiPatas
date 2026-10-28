class_name Bee
extends Insect
## Abelha Zumbi: persegue o bichinho mais próximo, empurra de leve e contorna barreiras.
## Bloqueio justo: qualquer abrigo fechado e firme.


func _configure() -> void:
	radius = 11.0
	max_speed = 230.0
	agility = 2.6
	mass = 0.15
	linear_damp = 0.4


func _behave(_delta: float) -> void:
	_fly_toward(target_point(), 70.0, 0.9)
