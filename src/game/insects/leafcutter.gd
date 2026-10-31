class_name Leafcutter
extends Insect
## Formiga Tesoura: anda pelo chão e, encostada na tinta por 1,3 s, CORTA um pedaço e passa.
## Pedra, terreno e caixas ela não corta. Bloqueio justo: camadas, pedras ou tampar o buraco.

const CUT_TIME := 1.3
var _cut: Dictionary = {}


func _configure() -> void:
	radius = 9.0
	max_speed = 80.0
	agility = 6.0
	mass = 0.25
	flying = false


func _behave(delta: float) -> void:
	_walk_toward(target_point(), 14.0, 160.0)
	art.excited = false
	art.work_progress = 0.0
	for b in get_colliding_bodies():
		if b is DrawnLine:
			var id := b.get_instance_id()
			_cut[id] = float(_cut.get(id, 0.0)) + delta
			art.excited = true
			art.work_progress = maxf(art.work_progress, minf(1.0, _cut[id] / CUT_TIME))
			if _cut[id] >= CUT_TIME:
				_cut.erase(id)
				add_collision_exception_with(b)
				(b as DrawnLine).add_hole(global_position)
				Sfx.play("pop", -3.0, 1.4)
				Fx.popup_text(level.fx_layer, global_position + Vector2(0, -22), "Cortou!", Palette.WOOD_DARK, 0.8)
