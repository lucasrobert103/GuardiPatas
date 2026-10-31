class_name Bee
extends Insect
## Abelha Zumbi: persegue o bichinho mais próximo, empurra de leve e contorna barreiras.
## Bloqueio justo: qualquer abrigo fechado e firme.


func _configure() -> void:
	lured_by_honey = true
	radius = 11.0
	max_speed = 245.0
	agility = 3.0
	mass = 0.18
	linear_damp = 0.4


func _behave(_delta: float) -> void:
	_fly_toward(target_point(), 42.0, 0.9)
