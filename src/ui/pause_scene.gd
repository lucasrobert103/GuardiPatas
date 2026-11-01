class_name PauseScene
extends Control
## Ilustração da pausa: céu de soneca, lua, e os bichinhos E os insetos da fase cochilando
## juntos ("Z z" subindo). Tocar num bichinho faz ele espreguiçar (pulinho + som).

var level: Level
var _arts: Array[AnimalArt] = []
var _bugs: Array[InsectArt] = []
var _t := 0.0
var _hop: Array[float] = []


func setup(p_level: Level) -> PauseScene:
	level = p_level
	custom_minimum_size = Vector2(0, 220)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var species: Array = []
	for a in level.animals:
		if is_instance_valid(a) and not species.has(a.species):
			species.append(a.species)
	if species.is_empty():
		for a in level.data.get("animals", []):
			if not species.has(str(a["type"])):
				species.append(str(a["type"]))
	for sp in species.slice(0, 3):
		var art := AnimalArt.new()
		art.species = sp
		art.preview = true
		art.mood = "idle"
		art.accessory = Game.equipped(sp)
		art.scale = Vector2.ONE * EditorScreen.fit_scale(sp, 1.0)
		add_child(art)
		_arts.append(art)
		_hop.append(0.0)
	var kinds: Array = []
	for n in level.data.get("nests", []):
		if not kinds.has(str(n["insect"])):
			kinds.append(str(n["insect"]))
	for k in kinds.slice(0, 3):
		var bug := InsectArt.new()
		bug.kind = k
		bug.radius = 14.0
		bug.calmed = true
		add_child(bug)
		_bugs.append(bug)
	resized.connect(_place)
	return self


func _place() -> void:
	var w := size.x
	var ground := size.y - 34.0
	for i in _arts.size():
		var a := _arts[i]
		var x := w * (0.5 + (i - (_arts.size() - 1) * 0.5) * 0.24)
		a.position = Vector2(x, ground - Animal.half_height(a.species) * a.scale.y - _hop[i])
	for i in _bugs.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		_bugs[i].position = Vector2(w * 0.5 + side * (w * 0.42 - i * 18.0), 52.0 + i * 26.0 + sin(_t * 1.4 + i) * 5.0)
		_bugs[i].facing = -side


func _process(delta: float) -> void:
	_t += delta
	for i in _hop.size():
		_hop[i] = maxf(0.0, _hop[i] - delta * 120.0) if _hop[i] > 0.0 else 0.0
	_place()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	for i in _arts.size():
		if _arts[i].position.distance_to(mb.position) < 60.0:
			_hop[i] = 34.0
			_arts[i].mood = "happy"
			var art := _arts[i]
			get_tree().create_timer(1.0, true).timeout.connect(func():
				if is_instance_valid(art):
					art.mood = "idle")
			Sfx.play("pop", -3.0, 0.9 + i * 0.12)
			accept_event()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var sky := StyleBoxFlat.new()
	sky.set_corner_radius_all(26)
	sky.bg_color = Color("3b4a8f")
	sky.set_border_width_all(4)
	sky.border_color = Palette.OUTLINE
	draw_style_box(sky, r)
	DrawUtil.vgradient(self, Rect2(6, 6, size.x - 12, size.y * 0.7), Color("2c3570"), Color("6b78c9"))
	# estrelinhas piscando e lua
	for i in 14:
		var p := Vector2(fmod(i * 97.0, size.x - 40.0) + 20.0, fmod(i * 53.0, size.y * 0.5) + 14.0)
		var tw := 0.5 + 0.5 * sin(_t * 2.0 + i * 1.7)
		draw_circle(p, 1.4 + tw * 1.4, Color(1, 1, 0.85, 0.4 + tw * 0.5), true, -1.0, true)
	var moon := Vector2(size.x - 60.0, 46.0)
	draw_circle(moon, 34.0, Color(1, 1, 0.8, 0.15), true, -1.0, true)
	DrawUtil.disc(self, moon, 22.0, Color("fff6cf"), Color(0, 0, 0, 0), 0.0)
	DrawUtil.disc(self, moon + Vector2(9, -6), 18.0, Color("4b58a8"), Color(0, 0, 0, 0), 0.0)
	# morrinho de grama
	var hill := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		hill.append(Vector2(clampf(size.x * 0.5 + cos(a) * size.x * 0.56, 5.0, size.x - 5.0), size.y - 30.0 + sin(a) * 40.0))
	hill.append(Vector2(size.x - 4, size.y - 4))
	hill.append(Vector2(4, size.y - 4))
	draw_colored_polygon(hill, Color("6fb86a"))
	draw_rect(Rect2(4, size.y - 34, size.x - 8, 30), Color("6fb86a"), true)
	# "Z z" subindo de cada bichinho
	var font := ThemeDB.fallback_font
	for i in _arts.size():
		var base := _arts[i].position + Vector2(24, -Animal.half_height(_arts[i].species) * _arts[i].scale.y - 6.0)
		for k in 3:
			var ph := fmod(_t * 0.5 + k * 0.33 + i * 0.2, 1.0)
			var p := base + Vector2(ph * 18.0 + k * 4.0, -ph * 46.0)
			draw_string(font, p, "Z" if k == 0 else "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 16 + int((1.0 - ph) * 8.0), Color(1, 1, 1, 1.0 - ph))
	draw_style_box(_border(), r)


func _border() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.draw_center = false
	b.set_corner_radius_all(26)
	b.set_border_width_all(4)
	b.border_color = Palette.OUTLINE
	return b
