class_name Firefly
extends Insect
## Vagalume Pisca: brilha e ANIMA os insetos por perto (ficam mais rápidos enquanto
## estão na luz dele). Sozinho é fraco; no meio do enxame vira o líder.
## Bloqueio justo: abrigo sem frestas — a luz acelera, mas não atravessa a tinta.

const AURA := 170.0


func _configure() -> void:
	radius = 10.0
	max_speed = 230.0
	agility = 4.0
	mass = 0.2
	linear_damp = 0.5


func _behave(_delta: float) -> void:
	_fly_toward(target_point(), 50.0, 0.9)
	art.excited = true
	for bug in level.insects:
		if bug != self and is_instance_valid(bug) and bug.global_position.distance_to(global_position) < AURA:
			bug.boost_until = level._sim_time + 0.3
