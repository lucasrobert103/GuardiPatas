class_name Crate
extends RigidBody2D
## Caixa ou tábua de madeira solta: cai, rola, pode ser empurrada (inclusive por besouros).
## Útil como "peso" ou parede pronta — o jogador pode apoiar a linha nela.

const WOOD_HP := 1.6

var size := Vector2(60, 60)
var plank := false
var hp := WOOD_HP
var _wobble := 0.0


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


## Cupins roendo: a madeira racha e quebra quando o "hp" (segundos de roída) acaba.
func chew(delta: float) -> void:
	if hp <= 0.0:
		return
	hp -= delta
	_wobble = 1.0
	queue_redraw()
	if hp <= 0.0:
		var lv := get_parent()
		while lv != null and not lv is Level:
			lv = lv.get_parent()
		if lv != null:
			Fx.dust((lv as Level).fx_layer, global_position)
			Fx.popup_text((lv as Level).fx_layer, global_position + Vector2(0, -30), "Crec!", Palette.WOOD_DARK, 0.8)
		Sfx.play("pop", 0.0, 0.6)
		queue_free()


func _process(delta: float) -> void:
	if _wobble > 0.0:
		_wobble = maxf(_wobble - delta * 3.0, 0.0)
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	if _wobble > 0.0:
		draw_set_transform(Vector2(sin(Time.get_ticks_msec() * 0.06) * 1.5 * _wobble, 0))
	draw_rect(rect.grow(Palette.OUTLINE_W * 0.5), Palette.OUTLINE, true)
	draw_rect(rect.grow(-Palette.OUTLINE_W * 0.5), Palette.WOOD, true)
	if plank:
		var x := rect.position.x + 14.0
		while x < rect.end.x - 8.0:
			draw_circle(Vector2(x, 0), 2.2, Palette.WOOD_DARK, true, -1.0, true)
			x += 40.0
		_draw_cracks(rect)
		return
	var inset := rect.grow(-9.0)
	draw_rect(inset, Palette.WOOD_DARK, false, 3.0, true)
	draw_line(inset.position, inset.end, Palette.WOOD_DARK, 4.0, true)
	_draw_cracks(rect)


func _draw_cracks(rect: Rect2) -> void:
	var dmg := 1.0 - hp / WOOD_HP
	if dmg <= 0.05:
		return
	var o := Palette.OUTLINE
	var c := rect.get_center()
	draw_polyline(PackedVector2Array([c + Vector2(-rect.size.x * 0.4, -6), c + Vector2(-8, 4), c + Vector2(4, -6), c + Vector2(rect.size.x * 0.4 * dmg, 6)]), o, 2.5, true)
	if dmg > 0.5:
		draw_polyline(PackedVector2Array([c + Vector2(0, -rect.size.y * 0.4), c + Vector2(6, -6), c + Vector2(-4, 8), c + Vector2(2, rect.size.y * 0.4)]), o, 2.5, true)
