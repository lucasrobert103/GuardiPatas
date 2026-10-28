class_name Projectile
extends RigidBody2D
## Bola de neve (Coruja Nevasca) ou concha (Caranguejo Rei). Bater rápido num bichinho
## = "Bonk!" (derrota, sem machucar). A neve derrete depois de alguns segundos.

var kind := "snow"     # snow | shell
var level: Level
var life := 6.0
var radius := 15.0
var _t := 0.0
var _spin := 0.0


func setup(p_level: Level, p_kind: String) -> void:
	level = p_level
	kind = p_kind
	radius = 15.0 if kind == "snow" else 12.0
	life = 6.0 if kind == "snow" else 5.0
	# camada própria, que os insetos não enxergam: uma bola de neve rápida "atiraria"
	# a abelha através da linha
	collision_layer = Layers.PROJECTILE
	collision_mask = Layers.TERRAIN | Layers.LINE | Layers.ANIMAL | Layers.PROP | Layers.NEST | Layers.PROJECTILE
	mass = 1.2 if kind == "snow" else 0.8
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 4
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.2 if kind == "snow" else 0.45
	mat.friction = 0.3
	physics_material_override = mat
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_hit)


func _on_hit(body: Node) -> void:
	if body is Animal and linear_velocity.length() > 140.0 and level != null:
		level.on_animal_bonked(body as Animal, "snow" if kind == "snow" else "shell")
	elif linear_velocity.length() > 180.0:
		Sfx.play("line_land", -6.0, 1.3 if kind == "shell" else 0.7, 0.1, 0.1)


func _physics_process(delta: float) -> void:
	_t += delta
	if _t > life:
		var k := clampf(1.0 - (_t - life) / 0.6, 0.0, 1.0)
		scale = Vector2.ONE * maxf(k, 0.05)
		if k <= 0.0:
			queue_free()


func _process(delta: float) -> void:
	_spin += delta * linear_velocity.x * 0.02
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	if kind == "snow":
		DrawUtil.disc(self, Vector2.ZERO, radius, Color("f6fbff"), o, 3.0)
		draw_circle(Vector2(-5, -5), 4.0, Color(1, 1, 1), true, -1.0, true)
		draw_arc(Vector2.ZERO, radius - 4.0, 0.3, 1.6, 8, Color("bfd9f0"), 2.5, true)
	else:
		draw_set_transform(Vector2.ZERO, _spin)
		var shell := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			shell.append(Vector2(cos(a) * radius, sin(a) * radius * 0.9 + 4.0))
		DrawUtil.shape(self, shell, Color("ffb3a1"), o, 2.5)
		for k in 4:
			var a := PI + PI * (k + 1) / 5.0
			draw_line(Vector2(0, 4), Vector2(cos(a) * radius * 0.85, sin(a) * radius * 0.8 + 4.0), Color("e0806a"), 2.0, true)
		draw_set_transform(Vector2.ZERO)
