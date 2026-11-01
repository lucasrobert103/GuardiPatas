class_name DragScroll
extends Node
## Rolagem arrastando em QUALQUER ponto de uma ScrollContainer (dedo ou mouse), com inércia.
## O Godot só rola por arraste em telas de toque e nunca quando o toque começa num botão;
## aqui o arraste começa em qualquer lugar e, passado o limiar, o botão tocado é cancelado
## (não dispara). Toques curtos continuam funcionando normalmente como cliques.
## Uso: DragScroll.attach(scroll_container)

const THRESHOLD := 14.0
const FRICTION := 5.0
const MIN_SPEED := 20.0

var scroll: ScrollContainer
var _down := false
var _dragging := false
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _origin := Vector2.ZERO
var _velocity := Vector2.ZERO
var _last_time := 0
var _injecting := false


static func attach(sc: ScrollContainer) -> DragScroll:
	var d := DragScroll.new()
	d.scroll = sc
	# a barra fica escondida: rola-se arrastando o conteúdo
	if sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	if sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.add_child(d, false, Node.INTERNAL_MODE_FRONT)
	return d


func _ready() -> void:
	set_process(false)


func _can_x() -> bool:
	return scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED


func _can_y() -> bool:
	return scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED


func _input(event: InputEvent) -> void:
	if _injecting or scroll == null or not scroll.is_visible_in_tree():
		return
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			if scroll.get_global_rect().has_point(mb.position) and _on_top(mb.position):
				_down = true
				_dragging = false
				_start = mb.position
				_last = mb.position
				_origin = Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)
				_velocity = Vector2.ZERO
				_last_time = Time.get_ticks_usec()
				set_process(false)
		elif _down:
			_down = false
			if _dragging:
				_dragging = false
				get_viewport().set_input_as_handled()
				set_process(_velocity.length() > MIN_SPEED)
		return
	var mm := event as InputEventMouseMotion
	if mm == null or not _down:
		return
	var delta := mm.position - _start
	var axis := Vector2(1.0 if _can_x() else 0.0, 1.0 if _can_y() else 0.0)
	if not _dragging:
		if (delta * axis).length() < THRESHOLD:
			return
		_dragging = true
		_cancel_press()
	var now := Time.get_ticks_usec()
	var dt := maxf(float(now - _last_time) / 1000000.0, 0.001)
	var step := (mm.position - _last) * axis
	_velocity = _velocity.lerp(-step / dt, 0.4)
	_last = mm.position
	_last_time = now
	var target := _origin - delta * axis
	scroll.scroll_horizontal = int(target.x)
	scroll.scroll_vertical = int(target.y)
	get_viewport().set_input_as_handled()


## A rolagem só começa se nenhuma janela por cima (diálogo) cobre esse ponto.
func _on_top(point: Vector2) -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered == null:
		return true
	return hovered == scroll or scroll.is_ancestor_of(hovered)


## O botão onde o dedo encostou não pode disparar depois que virou arraste:
## move o "ponteiro" para fora e solta lá (o botão entende como desistência).
func _cancel_press() -> void:
	_injecting = true
	var away := Vector2(-10000, -10000)
	var mm := InputEventMouseMotion.new()
	mm.position = away
	mm.global_position = away
	mm.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(mm, true)
	var up := InputEventMouseButton.new()
	up.position = away
	up.global_position = away
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	get_viewport().push_input(up, true)
	_injecting = false


func _process(delta: float) -> void:
	_velocity = _velocity.lerp(Vector2.ZERO, clampf(FRICTION * delta, 0.0, 1.0))
	if _velocity.length() < MIN_SPEED:
		set_process(false)
		return
	scroll.scroll_horizontal += int(_velocity.x * delta)
	scroll.scroll_vertical += int(_velocity.y * delta)
