class_name CarpenterBee
extends Insect
## Abelha Broca: empurra a linha e, depois de 1,6 s encostada no mesmo traço, FURA e passa.
## Cada traço novo é uma camada a mais para furar. Pedra e terreno ela não fura.
## Bloqueio justo: camadas independentes, pedra, ninho tampado ou isca de mel.

const DRILL_TIME := 1.6

var _drill: Dictionary = {}
var _route_timer := 0.0
var _waypoint := Vector2.INF


func _configure() -> void:
	lured_by_honey = true
	water_proof = kind == "drillfish"
	radius = 12.0
	max_speed = 270.0
	agility = 3.4
	mass = 0.36
	linear_damp = 0.4


func _behave(delta: float) -> void:
	_fly_toward(_route_around_stone(delta), 30.0, 0.35)
	art.excited = false
	art.work_progress = 0
	for b in get_colliding_bodies():
		if b is DrawnLine:
			var id := b.get_instance_id()
			_drill[id] = float(_drill.get(id, 0.0)) + delta
			art.excited = true
			art.work_progress = maxf(art.work_progress, minf(1, _drill[id] / DRILL_TIME))
			if _drill[id] >= DRILL_TIME:
				_drill.erase(id)
				add_collision_exception_with(b)
				(b as DrawnLine).add_hole(global_position)
				Sfx.play("pop", -2.0, 0.5)
				Fx.popup_text(level.fx_layer, global_position + Vector2(0, -24), "Furou!", Palette.WOOD_DARK, 0.8)


## Não ficar empurrando a pedra eternamente: contorna pelo canto superior visível.
## O corpo continua colidindo normalmente; não atravessa rochas nem linhas.
func _route_around_stone(delta: float) -> Vector2:
	var target := target_point()
	_route_timer -= delta
	if _route_timer <= 0.0:
		_route_timer = 0.18
		var query := PhysicsRayQueryParameters2D.create(global_position, target, Layers.TERRAIN)
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			_waypoint = Vector2.INF
		elif hit["collider"] is Terrain:
			var terrain := hit["collider"] as Terrain
			var bounds := terrain._bounds()
			var edge := bounds.position.x - radius * 2 if target.x < terrain.to_global(bounds.get_center()).x else bounds.end.x + radius * 2
			_waypoint = terrain.to_global(Vector2(edge, bounds.position.y - radius * 2))
	if _waypoint.is_finite() and global_position.distance_to(_waypoint) > radius:
		return _waypoint
	return target
