class_name NinjaMosquito
extends Insect
## Mosquito-Ninja: solta uma fumacinha (aviso) e fica quase INVISÍVEL por 1 s, voando
## mais rápido. Continua batendo na tinta como qualquer mosquito.
## Bloqueio justo: abrigo sem frestas, nem as pequenas.

const EVERY := 2.4
const SMOKE := 0.45
const HIDDEN := 1.0
var _timer := 1.2
var _state := 0   # 0 visível, 1 fumaça, 2 invisível


func _configure() -> void:
	radius = 7.0
	max_speed = 340.0
	agility = 6.0
	mass = 0.08
	linear_damp = 0.5


func _behave(delta: float) -> void:
	_timer -= delta
	var speed_k := 1.5 if _state == 2 else 1.0
	var keep := max_speed
	max_speed = keep * speed_k
	_fly_toward(target_point(), 70.0, 1.3)
	max_speed = keep
	match _state:
		0:
			art.modulate.a = 1.0
			art.aiming = false
			if _timer <= 0.0:
				_state = 1
				_timer = SMOKE
		1:
			art.aiming = true
			art.aim_progress = 1.0 - _timer / SMOKE
			if _timer <= 0.0:
				_state = 2
				_timer = HIDDEN
				art.aiming = false
				Fx.dust(level.fx_layer, global_position)
				Sfx.play("pop", -10.0, 2.0, 0.1)
		2:
			art.modulate.a = 0.18
			if _timer <= 0.0:
				_state = 0
				_timer = EVERY
				art.modulate.a = 1.0
