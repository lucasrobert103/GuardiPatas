class_name HoneyPot
extends StaticBody2D
## Pote de mel: abelhas, vespas e brocas vão nele ANTES do bichinho, enquanto houver mel.
## Cada inseto comendo gasta mel; o medidor mostra quanto falta. Acabou, eles voltam ao
## bichinho mais perto do pote. Uma isca — use o tempo que ela compra.

var amount := 6.0
var total := 6.0
var _t := 0.0


func setup(p_amount: float) -> void:
	amount = p_amount
	total = maxf(p_amount, 0.1)
	collision_layer = Layers.TERRAIN
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 22.0
	cs.shape = c
	add_child(cs)


func has_honey() -> bool:
	return amount > 0.0


func eat(delta: float) -> void:
	if amount <= 0.0:
		return
	amount = maxf(amount - delta, 0.0)
	if amount <= 0.0:
		Sfx.play("ui_back", -4.0, 0.7)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	var frac := clampf(amount / total, 0.0, 1.0)
	if frac > 0.0:
		draw_circle(Vector2.ZERO, 60.0 + sin(_t * 3.0) * 4.0, Color(1.0, 0.82, 0.25, 0.12), true, -1.0, true)
	var body := DrawUtil.ellipse(Vector2(0, 4), Vector2(24, 22))
	DrawUtil.shape(self, body, Color("e9a23b"), o, 3.5)
	draw_rect(Rect2(-18, -24, 36, 10), Color("c98a2a"), true)
	draw_rect(Rect2(-18, -24, 36, 10), o, false, 3.0, true)
	if frac > 0.0:
		# mel escorrendo
		DrawUtil.oval(self, Vector2(-8, -12), Vector2(7, 9), Palette.GOLD, o, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-24, 12), "MEL", HORIZONTAL_ALIGNMENT_CENTER, 48, 16, o)
	# medidor
	draw_rect(Rect2(-26, 32, 52, 9), Color.WHITE, true)
	draw_rect(Rect2(-26, 32, 52 * frac, 9), Palette.GOLD_DARK, true)
	draw_rect(Rect2(-26, 32, 52, 9), o, false, 2.0, true)
