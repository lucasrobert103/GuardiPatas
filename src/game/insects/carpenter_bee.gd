class_name CarpenterBee
extends Insect
## Abelha Broca: empurra a linha e, depois de 2,2 s encostada no mesmo traço, FURA e passa.
## Cada traço novo é uma camada a mais para furar. Pedra e terreno ela não fura.
## Bloqueio justo: parede dupla (dois traços), pedra ou isca de mel.

const DRILL_TIME := 2.2

var _drill: Dictionary = {}


func _configure() -> void:
	lured_by_honey = true
	radius = 12.0
	max_speed = 220.0
	agility = 2.4
	mass = 0.22
	linear_damp = 0.4


func _behave(delta: float) -> void:
	_fly_toward(target_point(), 30.0, 0.35)
	art.excited = false
	for b in get_colliding_bodies():
		if b is DrawnLine:
			var id := b.get_instance_id()
			_drill[id] = float(_drill.get(id, 0.0)) + delta
			art.excited = true
			if _drill[id] >= DRILL_TIME:
				_drill.erase(id)
				add_collision_exception_with(b)
				(b as DrawnLine).add_hole(global_position)
				Sfx.play("pop", -2.0, 0.5)
				Fx.popup_text(level.fx_layer, global_position + Vector2(0, -24), "Furou!", Palette.WOOD_DARK, 0.8)
