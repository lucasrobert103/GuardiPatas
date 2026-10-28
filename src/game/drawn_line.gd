class_name DrawnLine
extends RigidBody2D
## A linha desenhada vira UM corpo rígido com massa, feito de cápsulas (uma por segmento).
## Decisão (docs/09-arquitetura.md → ADR-003): corpo único composto é estável no
## GodotPhysics2D, não cria juntas que "explodem", e o nº de formas é limitado (≤ 40).

const THICKNESS := 14.0
const MASS_PER_PX := 0.01
const MIN_MASS := 0.8
const MAX_MASS := 9.0

var points_local := PackedVector2Array()
var length_px := 0.0
var _landed := false
var _fill: Line2D
var _shine: Line2D
## "Tinta Firme": a linha não cai nem se mexe (vira parede/rampa fixa).
var static_ink := false
var holes: Array[Vector2] = []
var _holes_node: Node2D


func build(world_points: PackedVector2Array, color: Color = Palette.INK, p_static: bool = false) -> void:
	static_ink = p_static
	if static_ink:
		color = Palette.INK_STATIC
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
		freeze = true
	collision_layer = Layers.LINE
	collision_mask = Layers.LINE_MASK
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 4
	var mat := PhysicsMaterial.new()
	mat.friction = 0.9
	mat.bounce = 0.05
	physics_material_override = mat
	angular_damp = 0.8
	var origin := LineMath.centroid(world_points)
	position = origin
	points_local = PackedVector2Array()
	for p in world_points:
		points_local.append(p - origin)
	length_px = LineMath.length(points_local)
	mass = clampf(length_px * MASS_PER_PX, MIN_MASS, MAX_MASS)
	var r := THICKNESS * 0.5
	if points_local.size() == 1:
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = r
		cs.shape = c
		cs.position = points_local[0]
		add_child(cs)
	for i in range(1, points_local.size()):
		var a := points_local[i - 1]
		var b := points_local[i]
		var seg := b - a
		var cs := CollisionShape2D.new()
		var cap := CapsuleShape2D.new()
		cap.radius = r
		cap.height = seg.length() + THICKNESS
		cs.shape = cap
		cs.position = (a + b) * 0.5
		cs.rotation = seg.angle() - PI / 2.0
		add_child(cs)
	_add_visuals(color)
	body_entered.connect(_on_body_entered)


func _add_visuals(color: Color) -> void:
	var outline := Line2D.new()
	outline.points = points_local
	outline.width = THICKNESS + Palette.OUTLINE_W * 2.0
	outline.default_color = Palette.OUTLINE
	_round(outline)
	add_child(outline)
	_fill = Line2D.new()
	_fill.points = points_local
	_fill.width = THICKNESS
	_fill.default_color = color
	_round(_fill)
	add_child(_fill)
	_shine = Line2D.new()
	var shine_pts := PackedVector2Array()
	for p in points_local:
		shine_pts.append(p + Vector2(-1.5, -2.5))
	_shine.points = shine_pts
	_shine.width = 3.0
	_shine.default_color = Color(Palette.INK_STATIC_HI if static_ink else Palette.INK_HI, 0.8)
	_round(_shine)
	add_child(_shine)


## Marca visual de um furo (feito pela abelha-broca). Guardado em coordenadas locais.
func add_hole(world_pos: Vector2) -> void:
	var local := to_local(world_pos)
	var best := local
	var best_d := INF
	for i in range(1, points_local.size()):
		var c := Geometry2D.get_closest_point_to_segment(local, points_local[i - 1], points_local[i])
		var d := c.distance_squared_to(local)
		if d < best_d:
			best_d = d
			best = c
	holes.append(best)
	if _holes_node == null:
		_holes_node = HoleMarks.new()
		add_child(_holes_node)
	(_holes_node as HoleMarks).holes = holes
	_holes_node.queue_redraw()


class HoleMarks:
	extends Node2D
	var holes: Array[Vector2] = []

	func _draw() -> void:
		for h in holes:
			draw_circle(h, 8.0, Palette.OUTLINE, true, -1.0, true)
			draw_circle(h, 5.0, Color("1a1420"), true, -1.0, true)
			for k in 5:
				var a := TAU * k / 5.0
				draw_line(h + Vector2.from_angle(a) * 8.0, h + Vector2.from_angle(a + 0.3) * 11.0, Palette.WOOD_DARK, 2.0, true)


static func _round(l: Line2D) -> void:
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.antialiased = true


func _on_body_entered(body: Node) -> void:
	if _landed:
		return
	if body is StaticBody2D or body is AnimatableBody2D or body is DrawnLine:
		_landed = true
		Sfx.play("line_land", -4.0, 1.0, 0.1)
		var lv := get_parent()
		while lv != null and not lv is Level:
			lv = lv.get_parent()
		if lv != null:
			Fx.dust((lv as Level).fx_layer, global_position + Vector2(0, 10))
