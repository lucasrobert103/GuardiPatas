class_name GoalZone
extends Node2D
## Toca de chegada: em fases "Rumo à Toca", o bichinho precisa ENTRAR aqui (rolando pela
## rampa de Tinta Firme que você desenha) antes do tempo acabar.

var rect := Rect2()
var _t := 0.0
var reached := false


func setup(r: Rect2) -> void:
	rect = r
	z_index = -5


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	var c := Vector2(rect.get_center().x, rect.end.y)
	var hw := rect.size.x * 0.5
	var arch := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		arch.append(c + Vector2(cos(a) * hw, sin(a) * rect.size.y * 0.9))
	DrawUtil.shape(self, arch, Color("6b4a3a"), o, 4.0)
	var inner := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		inner.append(c + Vector2(cos(a) * hw * 0.72, sin(a) * rect.size.y * 0.68))
	draw_colored_polygon(inner, Color("2b1d18"))
	# bandeirinha
	var pole := Vector2(rect.end.x - 6, rect.position.y - 10)
	draw_line(pole, pole + Vector2(0, -60), o, 4.0, true)
	var wave := sin(_t * 5.0) * 4.0
	DrawUtil.shape(self, PackedVector2Array([pole + Vector2(0, -60), pole + Vector2(34, -50 + wave), pole + Vector2(0, -38)]), Palette.UI_GOOD if not reached else Palette.GOLD, o, 3.0)
	# setinha pulsante
	var bounce := absf(sin(_t * 4.0)) * 10.0
	var tip := Vector2(rect.get_center().x, rect.position.y - 40 - bounce)
	DrawUtil.tri(self, tip + Vector2(-14, -16), tip + Vector2(14, -16), tip + Vector2(0, 4), Palette.GOLD, o, 3.0)
