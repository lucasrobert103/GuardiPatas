class_name Crab
extends Insect
## Caranguejo Belisco: anda de lado, empurra com força e NÃO é levado pela água.
## Bloqueio justo: parede firme ou abrigo fechado; a água não ajuda.


func _configure() -> void:
	radius = 15.0
	max_speed = 115.0
	agility = 5.0
	mass = 2.2
	flying = false
	water_proof = true


func _behave(delta: float) -> void:
	if _ram_barrier(delta, 250): return
	_walk_toward(target_point(), 14.0, 1000.0)
