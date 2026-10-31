class_name Rhino
extends Insect
## Besouro-Rinoceronte: forte e teimoso. Quando encosta numa linha solta, enfia o chifre por
## baixo e LEVANTA — abrigos soltos viram de pernas para o ar. Caixas também.
## Estratégia: travar a linha no terreno (por baixo de pedras/bordas), Tinta Firme, ou
## desviar o caminho dele para a água ou um buraco.

const LIFT_COOLDOWN := 1.1
const LIFT_SPEED := 900.0

var _cd := 0.0


func _configure() -> void:
	radius = 18.0
	max_speed = 66.0
	agility = 5.0
	mass = 1.6
	flying = false


func _behave(delta: float) -> void:
	var tp := target_point()
	_walk_toward(tp, 10.0, 1500.0)
	_cd = maxf(_cd - delta, 0.0)
	if _cd > 0.0:
		return
	for b in get_colliding_bodies():
		var body := b as RigidBody2D
		if body == null or body.freeze or not (body is DrawnLine or body is Crate):
			continue
		_cd = LIFT_COOLDOWN
		var dir := signf(tp.x - global_position.x)
		var at := global_position + Vector2(dir * radius, -radius * 0.2)
		# levanta pela ponta encostada: gira o abrigo de pernas para o ar
		var imp := Vector2(dir * 0.5, -1.0).normalized() * LIFT_SPEED * body.mass
		body.apply_impulse(imp, at - body.global_position)
		body.apply_torque_impulse(dir * body.mass * 9000.0)
		art.squash = 1.0
		Sfx.play("bonk", -2.0, 0.55, 0.1)
		Fx.popup_text(level.fx_layer, global_position + Vector2(0, -34), "Upa!", Palette.WOOD_DARK, 0.7)
		return
