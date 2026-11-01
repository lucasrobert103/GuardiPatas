class_name BubbleGame
extends Control
## Mini-jogo do banho: bolhas sobem por 15 s; toque para estourar. Cada bolha limpa um
## pouquinho e dá carinho; bolhas douradas valem 3. No fim, moedas pelo placar.

signal finished(score: int)

const DURATION := 15.0
var pet := "capi"
var _t := 0.0
var _spawn := 0.0
var _bubbles: Array[Dictionary] = []
var _score := 0
var _combo := 0
var _combo_t := 0.0
var _over := false
var _label: Label
var _time: Label
var _pops: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 60
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.make_theme()
	_label = UiKit.label("", 34, Palette.WHITE, 10, Palette.OUTLINE)
	_label.position = Vector2(0, 80)
	_label.size = Vector2(720, 50)
	add_child(_label)
	_time = UiKit.label("", 24, Palette.WHITE, 8, Palette.OUTLINE)
	_time.position = Vector2(0, 130)
	_time.size = Vector2(720, 40)
	add_child(_time)
	resized.connect(func():
		_label.size.x = size.x
		_time.size.x = size.x)
	_update_labels()


func _update_labels() -> void:
	_label.text = tr("Bolhas: %d") % _score + ("   " + tr("Combo ×%d!") % _combo if _combo >= 3 else "")
	_time.text = tr("Estoure as bolhas! %d s") % int(ceil(maxf(0.0, DURATION - _t)))


func _process(delta: float) -> void:
	if _over:
		return
	_t += delta
	_combo_t -= delta
	if _combo_t <= 0.0:
		_combo = 0
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = maxf(0.18, 0.55 - _t * 0.025)
		var gold := randf() < 0.12
		_bubbles.append({"p": Vector2(randf_range(60, size.x - 60), size.y + 30), "r": randf_range(26, 46) * (0.8 if gold else 1.0),
			"v": randf_range(110, 200) + _t * 6.0, "ph": randf() * TAU, "gold": gold})
	for b in _bubbles.duplicate():
		b["p"] = Vector2(b["p"]) + Vector2(sin(_t * 2.0 + float(b["ph"])) * 30.0 * delta, -float(b["v"]) * delta)
		if Vector2(b["p"]).y < -60:
			_bubbles.erase(b)
	for p in _pops.duplicate():
		p["t"] = float(p["t"]) + delta
		if float(p["t"]) > 0.4:
			_pops.erase(p)
	if _t >= DURATION:
		_finish()
	_update_labels()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or _over:
		return
	for i in range(_bubbles.size() - 1, -1, -1):
		var b: Dictionary = _bubbles[i]
		if Vector2(b["p"]).distance_to(mb.position) <= float(b["r"]) + 10.0:
			_bubbles.remove_at(i)
			var value := 3 if b["gold"] else 1
			_combo += 1
			_combo_t = 0.9
			_score += value + (1 if _combo >= 5 else 0)
			_pops.append({"p": b["p"], "r": b["r"], "t": 0.0, "gold": b["gold"]})
			Sfx.play("pop", -4.0, 0.9 + minf(_combo, 10) * 0.06, 0.05)
			var needs := PetCare.state(pet)
			needs["clean"] = minf(100.0, float(needs["clean"]) + 1.5 * value)
			needs["love"] = minf(100.0, float(needs["love"]) + 0.6 * value)
			accept_event()
			return


func _finish() -> void:
	_over = true
	_bubbles.clear()
	var coins := mini(25, _score / 2)
	Game.data["coins"] = Game.coins() + coins
	Game.add_stat("bubbles", _score, true)
	Game.save()
	Game.coins_changed.emit(Game.coins())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel(Palette.CREAM)
	center.add_child(panel)
	var col := UiKit.vbox(12)
	panel.add_child(col)
	col.add_child(UiKit.label("Banho de bolhas!", 38))
	col.add_child(UiKit.label(tr("Você estourou %d bolhas!") % _score, 28))
	col.add_child(UiKit.label("+%d" % coins, 30, Palette.GOLD.darkened(0.3)))
	var row := UiKit.hbox(12)
	col.add_child(row)
	var again := UiKit.button("De novo", Palette.UI_SECONDARY, "restart", 200, 76)
	again.pressed.connect(func():
		var g := BubbleGame.new()
		g.pet = pet
		g.finished.connect(func(s: int): finished.emit(s))
		get_parent().add_child(g)
		queue_free())
	row.add_child(again)
	var ok := UiKit.button("Pronto", Palette.UI_GOOD, "check", 200, 76)
	ok.pressed.connect(func():
		finished.emit(_score)
		queue_free())
	row.add_child(ok)
	Sfx.play("win", -4.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.8, 0.95, 0.35), true)
	for b in _bubbles:
		var p: Vector2 = b["p"]
		var r: float = b["r"]
		var col := Color("ffd23f") if b["gold"] else Color("bfe9ff")
		draw_circle(p, r, Color(col, 0.25), true, -1.0, true)
		draw_arc(p, r, 0.0, TAU, 28, col.darkened(0.2), 3.0, true)
		draw_arc(p, r * 0.7, PI * 1.1, PI * 1.5, 10, Color(1, 1, 1, 0.8), 4.0, true)
		draw_circle(p + Vector2(-r * 0.35, -r * 0.4), r * 0.12, Color(1, 1, 1, 0.9), true, -1.0, true)
	for pp in _pops:
		var k := float(pp["t"]) / 0.4
		var p2: Vector2 = pp["p"]
		for i in 8:
			var a := TAU * i / 8.0
			draw_line(p2 + Vector2.from_angle(a) * float(pp["r"]) * (0.6 + k), p2 + Vector2.from_angle(a) * float(pp["r"]) * (0.9 + k), Color(1, 1, 1, 1.0 - k), 3.0, true)
