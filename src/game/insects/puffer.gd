class_name Puffer
extends Insect
## Baiacu Bolha: nada até o bichinho e, quando chega perto, INCHA (fica 2x maior e mais
## pesado), empurrando abrigos apertados. Bloqueio justo: abrigo espaçoso e bem apoiado.

const BASE_R := 13.0
const BIG_R := 27.0
const NEAR := 170.0

var inflate := 0.0


func _configure() -> void:
	radius = BASE_R
	max_speed = 120.0
	agility = 2.5
	mass = 0.5
	water_proof = true


func _behave(delta: float) -> void:
	var t := target_point()
	var near := global_position.distance_to(t) < NEAR
	var was := inflate
	inflate = clampf(inflate + (1.6 if near else -0.5) * delta, 0.0, 1.0)
	if was < 0.5 and inflate >= 0.5:
		Sfx.play("pop", -6.0, 0.7)
	var r := lerpf(BASE_R, BIG_R, inflate)
	shape.radius = r
	art.radius = r
	mass = 0.5 + 1.2 * inflate
	_fly_toward(t, 20.0, 0.5)
