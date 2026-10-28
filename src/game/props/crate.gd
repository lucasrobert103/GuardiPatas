class_name Crate
extends RigidBody2D
## Caixa ou tábua de madeira solta: cai, rola, pode ser empurrada (inclusive por besouros).
## Útil como "peso" ou parede pronta — o jogador pode apoiar a linha nela.

var size := Vector2(60, 60)
var plank := false


func setup(p_size: Vector2, p_plank: bool, rot: float) -> void:
	size = p_size
	plank = p_plank
	rotation = rot
	collision_layer = Layers.PROP
	collision_mask = Layers.PROP_MASK
	mass = clampf(size.x * size.y / 2400.0, 0.4, 6.0)
	freeze = true
	var mat := PhysicsMaterial.new()
	mat.friction = 0.8
	physics_material_override = mat
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	add_child(cs)


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect.grow(Palette.OUTLINE_W * 0.5), Palette.OUTLINE, true)
	draw_rect(rect.grow(-Palette.OUTLINE_W * 0.5), Palette.WOOD, true)
	if plank:
		var x := rect.position.x + 14.0
		while x < rect.end.x - 8.0:
			draw_circle(Vector2(x, 0), 2.2, Palette.WOOD_DARK, true, -1.0, true)
			x += 40.0
		return
	var inset := rect.grow(-9.0)
	draw_rect(inset, Palette.WOOD_DARK, false, 3.0, true)
	draw_line(inset.position, inset.end, Palette.WOOD_DARK, 4.0, true)
