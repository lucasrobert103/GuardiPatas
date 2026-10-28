class_name Termite
extends Insect
## Cupim Roque-Roque: anda até a caixa/tábua de madeira mais próxima e a rói até quebrar.
## Não rói a linha de tinta nem pedra. Bloqueio justo: não depender só de madeira.

const SEEK_WOOD := 420.0


func _configure() -> void:
	radius = 8.0
	max_speed = 55.0
	agility = 6.0
	mass = 0.2
	flying = false


func _behave(delta: float) -> void:
	var wood: Crate = level.nearest_crate(global_position, SEEK_WOOD)
	var target := wood.global_position if wood != null else target_point()
	_walk_toward(target, 18.0, 140.0)
	art.excited = false
	for b in get_colliding_bodies():
		if b is Crate:
			(b as Crate).chew(delta)
			art.excited = true
