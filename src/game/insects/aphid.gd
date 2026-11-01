class_name Aphid
extends Insect
## Pulgão Cola: voa devagar e GRUDA na tinta (gotinhas verdes). Cada pulgão grudado
## pesa como uma pedrinha: vários juntos entortam ou derrubam a linha.
## Bloqueio justo: Tinta Firme (não cede), abrigo apoiado no cenário ou mais tinta.

const WEIGHT := 1.6
var _glued: DrawnLine
var _local := Vector2.ZERO


func _configure() -> void:
	radius = 8.0
	max_speed = 150.0
	agility = 3.0
	mass = 0.12
	linear_damp = 0.6


func _behave(_delta: float) -> void:
	if _glued != null:
		if not is_instance_valid(_glued):
			queue_free()
			return
		global_position = _glued.to_global(_local)
		if not _glued.freeze and not _glued.static_ink:
			_glued.apply_force(Vector2(0, 980.0 * WEIGHT), global_position - _glued.global_position)
		art.excited = true
		return
	_fly_toward(target_point(), 30.0, 0.8)
	for b in get_colliding_bodies():
		if b is DrawnLine and not (b as DrawnLine).static_ink:
			call_deferred("_stick", b)
			return


func _stick(line: DrawnLine) -> void:
	if _glued != null or not is_instance_valid(line):
		return
	_glued = line
	_local = line.to_local(global_position)
	freeze = true
	collision_layer = 0
	collision_mask = 0
	Sfx.play("bloop", -8.0, 1.6)
