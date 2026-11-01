class_name Ladybug
extends Insect
## Joaninha Mamãe: encostada na tinta por 2 s (a barriga pisca), solta 3 filhotinhos
## pequenos e rápidos. Os filhotes não têm esse poder.
## Bloqueio justo: abrigo sem frestas — e longe do ponto onde ela encosta.

const BROOD_TIME := 2.0
const COOLDOWN := 4.0
var baby := false
var _brood := 0.0
var _cooldown := 0.0


func _configure() -> void:
	radius = 6.0 if baby else 11.0
	max_speed = 280.0 if baby else 200.0
	agility = 5.0 if baby else 3.5
	mass = 0.06 if baby else 0.3
	linear_damp = 0.5


func _behave(delta: float) -> void:
	_fly_toward(target_point(), 40.0, 1.0)
	if baby:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	var touching := false
	for b in get_colliding_bodies():
		if b is DrawnLine:
			touching = true
	if touching and _cooldown <= 0.0:
		_brood += delta
	else:
		_brood = maxf(0.0, _brood - delta * 2.0)
	art.aiming = _brood > 0.0
	art.aim_progress = _brood / BROOD_TIME
	if _brood >= BROOD_TIME:
		_brood = 0.0
		_cooldown = COOLDOWN
		art.aiming = false
		call_deferred("_hatch")


func _hatch() -> void:
	if not is_instance_valid(level) or is_queued_for_deletion():
		return
	for k in 3:
		var kid := Ladybug.new()
		kid.baby = true
		kid.setup(level, "ladybug")
		kid.art.radius = 6.0
		kid.position = position + Vector2.from_angle(TAU * k / 3.0) * 16.0
		kid.linear_velocity = Vector2.from_angle(TAU * k / 3.0) * 120.0
		level.add_insect(kid)
	Sfx.play("pop", -4.0, 1.8, 0.1)
	Fx.popup_text(level.fx_layer, global_position + Vector2(0, -24), "Filhotes!", Palette.DANGER, 0.8)
