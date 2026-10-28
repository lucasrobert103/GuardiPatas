class_name Water
extends Area2D
## Água: insetos que caem nela são levados embora (boiando, sem violência).
## Bichinhos que não nadam e caem na água = derrota ("Molhou!"). A Lulu adora.

var rect := Rect2()
var level: Level
var _t := 0.0


func setup(p_rect: Rect2, p_level: Level) -> void:
	rect = p_rect
	level = p_level
	position = rect.get_center()
	collision_layer = 0
	collision_mask = Layers.ANIMAL | Layers.FLYER | Layers.WALKER
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size - Vector2(0, 8)
	cs.shape = r
	cs.position = Vector2(0, 4)
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Insect:
		(body as Insect).wash_away()
	elif body is Animal:
		level.on_animal_in_water(body as Animal)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var half := rect.size * 0.5
	var top := PackedVector2Array()
	var n := 24
	for i in n + 1:
		var x := -half.x + rect.size.x * float(i) / float(n)
		top.append(Vector2(x, -half.y + sin(_t * 2.5 + x * 0.05) * 3.0))
	var body := top.duplicate()
	body.append(Vector2(half.x, half.y))
	body.append(Vector2(-half.x, half.y))
	draw_colored_polygon(body, Palette.WATER)
	draw_polyline(top, Palette.WATER_HI, 4.0, true)
	for i in 4:
		var bx := -half.x + fmod(37.0 * i + _t * 12.0, rect.size.x)
		var by := half.y - fmod(_t * 30.0 + 50.0 * i, rect.size.y - 6.0)
		draw_arc(Vector2(bx, by), 3.0 + i % 2, 0.0, TAU, 10, Palette.WATER_HI, 1.5, true)
