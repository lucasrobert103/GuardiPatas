class_name Ghost
extends Insect
## Boo, o fantasminha: ATRAVESSA a tinta comum, mas não a Tinta Firme (que brilha) nem
## pedras. Tem medo de luz: foge das lâmpadas acesas.
## Bloqueio justo: Tinta Firme fechada ou ficar perto de uma lâmpada acesa.

const FEAR := 190.0


func _configure() -> void:
	radius = 13.0
	max_speed = 150.0
	agility = 3.0
	mass = 0.2
	linear_damp = 0.8
	water_proof = true


func setup(p_level: Level, p_kind: String) -> void:
	super.setup(p_level, p_kind)
	# só a Tinta Firme (camada GLOW), terreno e caixas seguram o fantasma
	collision_layer = Layers.GHOST
	collision_mask = Layers.TERRAIN | Layers.PROP | Layers.ANIMAL | Layers.GLOW


func _behave(_delta: float) -> void:
	var lamp: Lamp = level.nearest_lit_lamp(global_position)
	art.excited = lamp != null and global_position.distance_to(lamp.global_position) < FEAR
	if art.excited:
		var away := (global_position - lamp.global_position).normalized()
		_steer_velocity(away * max_speed * 1.4, agility * 1.5)
		return
	var target := target_point()
	var wob := Vector2(sin(_t * 2.0 + _phase) * 40.0, cos(_t * 1.6) * 20.0)
	_steer_velocity((target + wob - global_position).normalized() * max_speed, agility)
