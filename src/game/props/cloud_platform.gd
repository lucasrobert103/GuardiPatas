class_name CloudPlatform
extends AnimatableBody2D
## Nuvem fofa: AFUNDA devagar quando tem peso em cima (bichinho, linha, caixa) e volta a
## subir quando fica vazia. Afunda no máximo `drop` px.
## cfg: {"type": "cloud", "rect": [x, y, w, h], "drop": 90, "speed": 26}

var rect := Rect2()
var drop := 90.0
var speed := 26.0
var running := false
var offset := 0.0
var _query := PhysicsShapeQueryParameters2D.new()
var _probe := RectangleShape2D.new()
var _t := 0.0


func setup(cfg: Dictionary) -> void:
	var r: Array = cfg["rect"]
	rect = Rect2(r[0], r[1], r[2], r[3])
	drop = float(cfg.get("drop", 90.0))
	speed = float(cfg.get("speed", 26.0))
	position = rect.get_center()
	collision_layer = Layers.TERRAIN
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	add_child(cs)
	_probe.size = Vector2(rect.size.x - 8.0, 10.0)
	_query.shape = _probe
	_query.collision_mask = Layers.ANIMAL | Layers.LINE | Layers.PROP
	z_index = -2


func begin() -> void:
	running = true


func loaded() -> bool:
	_query.transform = Transform2D(0.0, global_position + Vector2(0, -rect.size.y * 0.5 - 6.0))
	_query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(_query, 1).is_empty()


func _physics_process(delta: float) -> void:
	_t += delta
	if not running:
		return
	var target := drop if loaded() else 0.0
	offset = move_toward(offset, target, speed * delta * (1.0 if target > offset else 0.6))
	position = rect.get_center() + Vector2(0, offset)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var half := rect.size * 0.5
	var puffs := int(rect.size.x / 34.0) + 1
	for i in puffs:
		var x := -half.x + rect.size.x * float(i) / maxf(puffs - 1, 1)
		DrawUtil.disc(self, Vector2(x, -half.y * 0.3 + sin(_t * 1.5 + i) * 1.5), half.y * 1.2, Color("f7fbff"), Palette.OUTLINE, 3.0)
	draw_rect(Rect2(-half.x, -half.y * 0.4, rect.size.x, half.y * 1.4), Color("f7fbff"), true)
	if running and offset > 2.0:
		# gotinhas caindo mostrando que está afundando
		for k in 3:
			var p := Vector2(-half.x * 0.5 + k * half.x * 0.5, half.y + fmod(_t * 60.0 + k * 13.0, 30.0))
			draw_circle(p, 3.0, Color("9ec9f0"), true, -1.0, true)
