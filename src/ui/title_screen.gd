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
var _bounce_time: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBg.new())
	var shield := TitleShield.new()
	add_child(shield)
	var species_list := _parade_species()
	for i in species_list.size():
		var sp: String = species_list[i]
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

	var col := UiKit.vbox(14)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 80)
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer_top)

	var t := UiKit.title("GuardiPatas", 80)
	col.add_child(t)
	UiKit.pop_in(t, 0.1)

	var bottom := UiKit.vbox(14)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.position.y -= 80
	add_child(bottom)

	var play := UiKit.button("Jogar", Palette.UI_GOOD, "play", 400, 110)
	play.add_theme_font_size_override("font_size", 42)
	play.pressed.connect(func(): go.emit("map", -1))
	bottom.add_child(play)
	UiKit.pop_in(play, 0.25)

	var quick_row := UiKit.hbox(10)
	quick_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(quick_row)

	var tiles := [
		["Desafio", "calendar", Color("ffb340"), "daily"],
		["Casinha", "house", Color("8fd3a0"), "home"],
		["Loja", "coin", Palette.GOLD, "store"],
		["Criar", "pencil", Color("b18cff"), "editor"],
		["Mais", "gear", Palette.UI_PANEL, "settings"],
	]
	for i in tiles.size():
		var spec: Array = tiles[i]
		var b := UiKit.tile(spec[0], spec[1], spec[2], 90, 90)
		var dest: String = spec[3]
		b.pressed.connect(func(): go.emit(dest, null))
		quick_row.add_child(b)
		UiKit.pop_in(b, 0.35 + i * 0.08)
		if dest == "daily" and not Game.daily_done_today(Daily.today_key()):
			UiKit.badge(b)

	var coins := UiKit.hbox(6)
	coins.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	coins.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	coins.position += Vector2(-20, 24)
	var ci := UiIcon.new()
	ci.icon = "coin"
	ci.custom_minimum_size = Vector2(40, 40)
	coins.add_child(ci)
	coins.add_child(UiKit.label(str(Game.coins()), 28, Palette.WHITE, 10, Palette.OUTLINE))
	add_child(coins)

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
		var base_y := ground_top - half

		# animação de pulo
		var bounce := 0.0
		if i in _bounce_time:
			_bounce_time[i] -= delta
			if _bounce_time[i] > 0:
				var t := 1.0 - (_bounce_time[i] / 0.4)
				bounce = -sin(t * PI) * 80.0
			else:
				_bounce_time.erase(i)

		# ondulação suave contínua
		var wave := sin(_t * 2.0 + i * 0.5) * 4.0
		a.position = Vector2(x + widths[i] * TitleScreen.ART_LEFT.get(a.species, 0.5), base_y + bounce + wave)
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
			_bounce_time[i] = 0.4
			_happy_until[i] = Time.get_ticks_msec() / 1000.0 + 1.2
			Sfx.play("pop", -2.0, 0.9 + i * 0.08)
			get_tree().root.set_input_as_handled()


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
