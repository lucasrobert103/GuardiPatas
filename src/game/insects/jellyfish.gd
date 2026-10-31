class_name Jellyfish
extends Insect
## Água-viva Gelatina: nada em pulsos lentos na direção do bichinho; fraca, mas insistente.
## Vive na água: não é levada embora por ela.

var _pulse := 0.0


func _configure() -> void:
	radius = 14.0
	max_speed = 90.0
	agility = 1.5
	mass = 0.2
	linear_damp = 1.4
	water_proof = true


func _behave(delta: float) -> void:
	_pulse -= delta
	if _pulse <= 0.0:
		_pulse = 0.9
		var route := navigator.next_point(self, predicted_target(0.25), 0.9)
		var dir := (route - global_position).normalized()
		apply_central_impulse(dir * 150.0 * mass)
		art.squash = 1.0
