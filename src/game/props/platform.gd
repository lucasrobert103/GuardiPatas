class_name MovingPlatform
extends AnimatableBody2D
## Plataforma que vai e volta (seno) entre `start` e `start + travel`.
## Fica parada enquanto o jogador desenha (o caminho aparece pontilhado) e só
## começa a mover na simulação — o jogador sempre vê para onde ela vai.

var size := Vector2(140, 24)
var start := Vector2.ZERO
var travel := Vector2.ZERO
var period := 3.0
var running := false
var _time := 0.0


func setup(p_rect: Rect2, p_travel: Vector2, p_period: float) -> void:
	size = p_rect.size
	start = p_rect.get_center()
	travel = p_travel
	period = maxf(p_period, 0.5)
	position = start
	collision_layer = Layers.TERRAIN
	collision_mask = 0
	sync_to_physics = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	add_child(cs)


func _physics_process(delta: float) -> void:
	if not running:
		return
	_time += delta
	var k := 0.5 - 0.5 * cos(TAU * _time / period)
	position = start + travel * k


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	if not running:
		var a := Vector2.ZERO
		var b := travel
		var dots := int(b.length() / 16.0)
		for i in dots + 1:
			draw_circle(a.lerp(b, float(i) / maxf(dots, 1)), 3.0, Color(Palette.OUTLINE, 0.35), true, -1.0, true)
	draw_rect(rect.grow(Palette.OUTLINE_W * 0.5), Palette.OUTLINE, true)
	draw_rect(rect.grow(-Palette.OUTLINE_W * 0.5), Palette.STONE, true)
	draw_line(rect.position + Vector2(6, 6), Vector2(rect.end.x - 6, rect.position.y + 6), Color(1, 1, 1, 0.6), 3.0, true)


func begin() -> void:
	running = true
	queue_redraw()
