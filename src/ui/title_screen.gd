class_name TitleScreen
extends Control
## Tela inicial: a turma inteira sendo protegida por uma linha, com uma abelha curiosa.
## Toque num bichinho para ele dar um pulinho.

signal go(screen: String, arg: Variant)

## Largura aproximada da arte de cada espécie e fração à esquerda da origem.
const ART_WIDTH := {"capi": 118.0, "brasa": 92.0, "pingo": 80.0, "nino": 64.0, "tuca": 104.0, "lulu": 92.0, "gelinho": 60.0, "tata": 70.0, "pompom": 60.0, "nuvem": 80.0, "fofa": 120.0, "tito": 60.0, "patinha": 62.0, "kiko": 70.0}
const ART_LEFT := {"capi": 0.5, "brasa": 0.6, "pingo": 0.5, "nino": 0.55, "tuca": 0.5, "lulu": 0.5, "gelinho": 0.5, "tata": 0.45, "pompom": 0.5, "nuvem": 0.45, "fofa": 0.5, "tito": 0.5, "patinha": 0.5, "kiko": 0.5}

var _parade: Array[AnimalArt] = []
var _bee: InsectArt
var _t := 0.0
var _happy_until: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBg.new())
	var shield := TitleShield.new()
	add_child(shield)
	for sp in _parade_species():
		var a := AnimalArt.new()
		a.species = sp
		a.preview = true
		a.accessory = Game.equipped(a.species)
		a.scale = Vector2(1.15, 1.15)
		add_child(a)
		_parade.append(a)
	_bee = InsectArt.new()
	_bee.kind = "bee"
	_bee.radius = 16.0
	add_child(_bee)

	var col := UiKit.vbox(16)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 150)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)
	var t := UiKit.title("GuardiPatas", 92)
	col.add_child(t)
	UiKit.pop_in(t, 0.1)
	var sub := UiKit.label("Proteja os Bichinhos!", 34, Palette.WHITE, 10, Palette.OUTLINE)
	col.add_child(sub)

	var bottom := UiKit.vbox(18)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.position.y -= 70
	add_child(bottom)
	var play := UiKit.button("Jogar", Palette.UI_GOOD, "play", 420, 120)
	play.add_theme_font_size_override("font_size", 44)
	play.pressed.connect(func(): go.emit("map", -1))
	bottom.add_child(play)
	UiKit.pop_in(play, 0.3)
	var row := UiKit.hbox(18)
	bottom.add_child(row)
	var friends := UiKit.button("Bichinhos", Palette.UI_PRIMARY, "paw", 260)
	friends.pressed.connect(func(): go.emit("collection", null))
	row.add_child(friends)
	var settings := UiKit.icon_button("gear", Palette.UI_PANEL, 96)
	settings.pressed.connect(func(): go.emit("settings", null))
	row.add_child(settings)

	var coins := UiKit.hbox(6)
	coins.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	coins.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	coins.position += Vector2(-24, 28)
	var ci := UiIcon.new()
	ci.icon = "coin"
	ci.custom_minimum_size = Vector2(44, 44)
	coins.add_child(ci)
	coins.add_child(UiKit.label(str(Game.coins()), 30, Palette.WHITE, 10, Palette.OUTLINE))
	add_child(coins)
	var credit := UiKit.label("RetroNexa · retronexa.com.br", 18, Palette.WHITE, 6, Palette.OUTLINE)
	credit.anchor_left = 0.0
	credit.anchor_right = 1.0
	credit.anchor_top = 1.0
	credit.anchor_bottom = 1.0
	credit.offset_top = -46
	credit.offset_bottom = -14
	credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(credit)
	Sfx.music("music_menu")


## Seis bichinhos no desfile: os já conhecidos primeiro (sorteados), completando com a turma inicial.
func _parade_species() -> Array:
	var met: Array = Game.data["met"].duplicate()
	met.shuffle()
	var out: Array = []
	for sp in met:
		if out.size() < 6 and Cast.ORDER.has(sp):
			out.append(sp)
	for sp in Cast.ORDER:
		if out.size() < 6 and not out.has(sp):
			out.append(sp)
	return out


func _process(delta: float) -> void:
	_t += delta
	var w := size.x
	# os bichinhos ficam em pé sobre a faixa de grama do escudo (ver TitleShield)
	var ground_top := size.y * 0.9 - 240.0 - 9.0
	# distribui pela largura de cada bichinho (a capivara é bem mais larga que o esquilo)
	var widths: Array[float] = []
	var total := 0.0
	for a in _parade:
		var wd: float = TitleScreen.ART_WIDTH.get(a.species, 60.0) * a.scale.x
		widths.append(wd)
		total += wd
	var gap := clampf((w * 0.86 - total) / 5.0, 2.0, 30.0)
	var x := w * 0.5 - (total + gap * 5.0) * 0.5
	for i in _parade.size():
		var a := _parade[i]
		var half := Animal.half_height(a.species) * a.scale.y
		a.position = Vector2(x + widths[i] * TitleScreen.ART_LEFT.get(a.species, 0.5), ground_top - half)
		x += widths[i] + gap
		var now := Time.get_ticks_msec() / 1000.0
		a.mood = "happy" if float(_happy_until.get(i, 0.0)) > now else ("scared" if _bee.position.distance_to(a.position) < 300.0 else "idle")
		a.look = (_bee.position - a.position).normalized() * Vector2(a.facing, 1)
	var c := Vector2(w * 0.5, size.y * 0.42)
	var prev := _bee.position
	_bee.position = c + Vector2(sin(_t * 0.9) * w * 0.36, sin(_t * 1.8) * 70.0 - 40.0)
	_bee.facing = signf(_bee.position.x - prev.x) if absf(_bee.position.x - prev.x) > 0.01 else _bee.facing


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	for i in _parade.size():
		if _parade[i].position.distance_to(mb.position) < 60.0:
			_happy_until[i] = Time.get_ticks_msec() / 1000.0 + 1.2
			Sfx.play("pop", -2.0, 1.0 + i * 0.08)


class TitleShield:
	extends Control
	## A linha azul "protegendo" a turma no título.
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var base := size.y * 0.9 - 250.0
		var pts := PackedVector2Array()
		for i in 25:
			var a := PI + PI * float(i) / 24.0
			pts.append(Vector2(w * 0.5 + cos(a) * w * 0.44, base + sin(a) * 190.0))
		draw_polyline(pts, Palette.OUTLINE, 22.0, true)
		draw_polyline(pts, Palette.INK, 14.0, true)
		var shine := PackedVector2Array()
		for i in range(4, 12):
			shine.append(pts[i] + Vector2(-2, -3))
		draw_polyline(shine, Palette.INK_HI, 3.0, true)
		draw_line(Vector2(0, base + 10), Vector2(w, base + 10), Palette.OUTLINE, 22.0, true)
		draw_line(Vector2(0, base + 10), Vector2(w, base + 10), Color("8fcf84"), 18.0, true)
