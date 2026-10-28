class_name GoldenPaw
extends Node2D
## Pegada dourada (medalha opcional): passe a linha por cima dela para pegar.
## Fica num ponto do caminho da solução registrada, então é sempre possível pegar.

const RADIUS := 30.0

var collected := false
var _t := 0.0
var _gone := 0.0


func collect() -> void:
	if collected:
		return
	collected = true
	Sfx.play("coin", 0.0, 1.3)


func _process(delta: float) -> void:
	_t += delta
	if collected:
		_gone += delta
		if _gone > 0.8:
			visible = false
	queue_redraw()


func _draw() -> void:
	var o := Palette.OUTLINE
	var bob := 0.0 if Game.setting("reduce_motion") else sin(_t * 3.0) * 4.0
	var k := 1.0
	var off := Vector2(0, bob)
	if collected:
		k = 1.0 + _gone * 0.8
		off.y -= _gone * 90.0
		modulate.a = clampf(1.0 - _gone / 0.8, 0.0, 1.0)
	draw_circle(off, 26.0 * k, Color(1.0, 0.86, 0.3, 0.25), true, -1.0, true)
	DrawUtil.disc(self, off + Vector2(0, 5) * k, 9.0 * k, Palette.GOLD, o, 2.5)
	for p in [Vector2(-10, -5), Vector2(-4, -12), Vector2(4, -12), Vector2(10, -5)]:
		DrawUtil.disc(self, off + p * k, 4.0 * k, Palette.GOLD, o, 2.0)
	var sp := fmod(_t * 1.3, 1.0)
	var star := off + Vector2(14, -16)
	draw_line(star + Vector2(-5, 0) * sp, star + Vector2(5, 0) * sp, Color(1, 1, 1, 1.0 - sp), 2.0, true)
	draw_line(star + Vector2(0, -5) * sp, star + Vector2(0, 5) * sp, Color(1, 1, 1, 1.0 - sp), 2.0, true)
