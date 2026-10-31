class_name Traca
extends Insect
## Traça Come-Tinta: anda pelo chão até a linha de tinta MAIS PERTO e rói um pedaço dela
## (abre uma passagem de verdade). Não sobe paredes nem a linha e a água a leva embora.
## Estratégia: dar outra linha para ela roer primeiro (isca), passar por cima da água,
## ou deixar os pés do abrigo fora do chão onde ela anda.

const CHEW_TIME := 0.9
const LURE_RANGE := 700.0

var _chew := 0.0


func _configure() -> void:
	radius = 10.0
	max_speed = 72.0
	agility = 6.0
	mass = 0.35
	flying = false


func target_point() -> Vector2:
	var best := Vector2.INF
	var bd := LURE_RANGE
	for l in level.lines:
		if not is_instance_valid(l):
			continue
		var c: Vector2 = l.closest_intact_point(global_position)
		if c == Vector2.INF:
			continue
		var d := c.distance_to(global_position)
		if d < bd:
			bd = d
			best = c
	return best if best != Vector2.INF else super.target_point()


func _nearest_line_in_reach() -> DrawnLine:
	for l in level.lines:
		if is_instance_valid(l):
			var c: Vector2 = l.closest_intact_point(global_position)
			if c != Vector2.INF and c.distance_to(global_position) < radius + 22.0:
				return l
	return null


func _behave(delta: float) -> void:
	var tp := target_point()
	_walk_toward(tp, 18.0, 160.0)
	var line := _nearest_line_in_reach()
	art.excited = line != null
	if line == null:
		_chew = maxf(_chew - delta, 0.0)
		return
	_chew += delta
	if _chew >= CHEW_TIME:
		_chew = 0.0
		var at: Vector2 = line.closest_intact_point(global_position)
		if line.bite(at, 24.0):
			Sfx.play("pop", -4.0, 0.7, 0.1)
			Fx.popup_text(level.fx_layer, global_position + Vector2(0, -26), "Nhac!", Color("8a6bb8"), 0.7)
