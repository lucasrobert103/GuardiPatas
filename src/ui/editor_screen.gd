class_name EditorScreen
extends Control
## Editor de fases: a fase aparece de verdade (mesmo motor) e o jogador toca para colocar
## bichinhos, ninhos, pedras e blocos. "Testar" joga a fase; vencendo, ela ganha o selo.

signal go(screen: String, arg: Variant)

const GROUND := 1000.0
const MAX := {"animal": 4, "nest": 4, "rock": 6, "block": 6}
const TOOLS := [
	["animal", "Bichinho", "paw"],
	["bee", "Abelhas", "heart"],
	["mosquito", "Mosquitos", "bolt"],
	["ant", "Formigas", "star"],
	["beetle", "Besouro", "trophy"],
	["rock", "Pedra", "rock"],
	["block", "Bloco", "block"],
	["erase", "Apagar", "close"],
]
const TIMES := [6.0, 8.0, 10.0, 12.0]
const INKS := [["Pouca", 450], ["Média", 750], ["Muita", 1100]]

var custom_index := -1
var draft: Dictionary
var tool := "animal"
var species_i := 0
var _lv: Level
var _tool_btns: Dictionary = {}
var _name_label: Label
var _status: Label
var _species: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var list: Array = Game.custom_levels()
	if custom_index >= 0 and custom_index < list.size():
		draft = (list[custom_index] as Dictionary).duplicate(true)
	else:
		custom_index = -1
		draft = new_draft(list.size() + 1)
	_species = Game.data["met"].duplicate()
	if _species.is_empty():
		_species = ["capi"]
	_build_ui()
	_rebuild()
	Sfx.music("music_menu")


static func new_draft(n: int) -> Dictionary:
	return {"name": "Minha fase %d" % n, "world": 1, "survive": 8.0, "ink": 750, "strokes": 1,
		"animals": [], "nests": [], "rocks": [], "blocks": [], "verified": false}


## Dados completos de fase (o mesmo formato da campanha) a partir do rascunho.
static func playable(d: Dictionary, index: int) -> Dictionary:
	var terrain: Array = [{"poly": [[-400, GROUND], [1120, GROUND], [1120, 1800], [-400, 1800]], "style": "ground"}]
	for b in d.get("blocks", []):
		terrain.append({"poly": [[b[0], b[1]], [b[2], b[1]], [b[2], b[3]], [b[0], b[3]]], "style": "stone"})
	var w := int(d.get("world", 1))
	return {
		"id": "custom", "mode": "custom", "custom_index": index, "world": w, "name": str(d.get("name", "")),
		"tip": "Fase criada por você!", "ink": int(d.get("ink", 750)), "survive": float(d.get("survive", 8.0)),
		"stars": [0.6, 0.8], "strokes": int(d.get("strokes", 1)), "terrain": terrain,
		"rocks": d.get("rocks", []).duplicate(true), "props": [], "nodraw": [],
		"animals": d.get("animals", []).duplicate(true), "nests": d.get("nests", []).duplicate(true),
		"bosses": [], "solution": [], "underwater": w == 8,
	}


func _build_ui() -> void:
	var top := UiKit.hbox(10)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 20
	add_child(top)
	var back := UiKit.icon_button("back")
	back.pressed.connect(_save_and_exit)
	top.add_child(back)
	var prev := UiKit.icon_button("back", Palette.UI_SECONDARY, 72)
	prev.pressed.connect(func(): _world(-1))
	top.add_child(prev)
	_name_label = UiKit.label("", 26, Palette.WHITE, 10, Palette.OUTLINE)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name_label)
	var nxt := UiKit.icon_button("next", Palette.UI_SECONDARY, 72)
	nxt.pressed.connect(func(): _world(1))
	top.add_child(nxt)
	var test := UiKit.button("Testar", Palette.UI_GOOD, "play", 170, 84)
	test.pressed.connect(_test)
	top.add_child(test)

	var opts := UiKit.hbox(10)
	opts.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	opts.offset_left = 16
	opts.offset_right = -16
	opts.offset_top = 116
	opts.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(opts)
	for spec in [["time", "timer"], ["ink", "ink"], ["strokes", "pencil"]]:
		var b := UiKit.button("-", Palette.UI_PANEL, spec[1], 0, 70)
		b.add_theme_font_size_override("font_size", 22)
		b.custom_minimum_size.x = 200
		var key: String = spec[0]
		b.pressed.connect(func():
			_cycle(key)
			_option_text(b, key))
		_option_text(b, key)
		opts.add_child(b)

	_status = UiKit.label("", 24, Palette.WHITE, 8, Palette.OUTLINE)
	_status.anchor_right = 1.0
	_status.offset_top = 196
	_status.offset_bottom = 236
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status)

	var scroll := ScrollContainer.new()
	scroll.anchor_left = 0.0
	scroll.anchor_right = 1.0
	scroll.anchor_top = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_top = -170
	scroll.offset_bottom = -30
	scroll.offset_left = 10
	scroll.offset_right = -10
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var row := UiKit.hbox(10)
	scroll.add_child(row)
	for t in TOOLS:
		var b := UiKit.tile(t[1], t[2], Palette.UI_PANEL, 118, 124)
		var id: String = t[0]
		if id in ["bee", "mosquito", "ant", "beetle"]:
			# o próprio inseto no lugar do ícone
			for c in b.get_children():
				if c is UiIcon:
					c.queue_free()
			var ia := InsectArt.new()
			ia.kind = id
			ia.radius = 16.0
			ia.position = Vector2(59, 44)
			b.add_child(ia)
		b.pressed.connect(func(): _select(id))
		row.add_child(b)
		_tool_btns[id] = b
	_select("animal")


func _option_text(b: Button, key: String) -> void:
	match key:
		"time":
			b.text = "     Tempo %ds" % int(draft["survive"])
		"ink":
			var name := "Média"
			for k in INKS:
				if int(k[1]) == int(draft["ink"]):
					name = k[0]
			b.text = "     Tinta: %s" % name
		"strokes":
			b.text = "     Traços: %d" % int(draft["strokes"])


func _cycle(key: String) -> void:
	match key:
		"time":
			var i := TIMES.find(float(draft["survive"]))
			draft["survive"] = TIMES[(i + 1) % TIMES.size()]
		"ink":
			var i := 0
			for k in INKS.size():
				if int(INKS[k][1]) == int(draft["ink"]):
					i = k
			draft["ink"] = INKS[(i + 1) % INKS.size()][1]
		"strokes":
			draft["strokes"] = 2 if int(draft["strokes"]) == 1 else 1
	draft["verified"] = false
	_update_labels()


func _select(id: String) -> void:
	if id == "animal" and tool == "animal":
		species_i = (species_i + 1) % _species.size()
	tool = id
	for k in _tool_btns.keys():
		var b: Button = _tool_btns[k]
		var col := Palette.GOLD if k == id else Palette.UI_PANEL
		b.add_theme_stylebox_override("normal", UiKit.btn_style(col, false))
		b.add_theme_stylebox_override("hover", UiKit.btn_style(col.lightened(0.06), false))
	_update_labels()


func _update_labels() -> void:
	var w := LevelDB.world_info(int(draft["world"]))
	_name_label.text = str(w.get("name", "Mundo %d" % int(draft["world"])))
	var msg := ""
	match tool:
		"animal": msg = "Toque para pôr: %s (toque de novo no botão para trocar)" % Animal.SPECIES[_species[species_i]]["name"]
		"erase": msg = "Toque perto de algo para apagar"
		"bee", "mosquito": msg = "Toque no céu para pôr o ninho"
		"ant", "beetle": msg = "Toque no chão para pôr o formigueiro"
		_: msg = "Toque para pôr"
	_status.text = msg


func _world(dir: int) -> void:
	draft["world"] = clampi(int(draft["world"]) + dir, 1, 8)
	draft["verified"] = false
	_update_labels()
	_rebuild()


func _rebuild() -> void:
	if _lv != null:
		_lv.queue_free()
	_lv = Level.new()
	_lv.setup(-1, playable(draft, custom_index), false)
	_lv.set_process_unhandled_input(false)
	add_child(_lv)
	move_child(_lv, 0)
	_lv.drawer.enabled = false
	_update_labels()


func _to_world(screen: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen


## Altura da superfície (chão ou topo de bloco) embaixo de x.
func _surface(x: float, below_y: float = -INF) -> float:
	var y := GROUND
	for b in draft["blocks"]:
		if x >= float(b[0]) and x <= float(b[2]) and float(b[1]) < y and float(b[1]) > below_y:
			y = float(b[1])
	return y


func _count(kind: String) -> int:
	match kind:
		"animal": return draft["animals"].size()
		"nest": return draft["nests"].size()
		"rock": return draft["rocks"].size()
		"block": return draft["blocks"].size()
	return 0


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var p := _to_world(mb.position)
	if p.y < 250.0 or p.y > GROUND + 40.0 or p.x < 30.0 or p.x > 690.0:
		return
	_place(p)


func _place(p: Vector2) -> void:
	var kind: String = {"animal": "animal", "rock": "rock", "block": "block", "erase": "erase"}.get(tool, "nest")
	if kind == "erase":
		_erase(p)
		return
	if _count(kind) >= int(MAX[kind]):
		Sfx.play("ui_locked")
		_status.text = "Limite atingido! Apague algo primeiro."
		return
	match kind:
		"animal":
			var sp: String = _species[species_i]
			var y := _surface(p.x) - Animal.half_height(sp) - 1.0
			draft["animals"].append({"type": sp, "pos": [round(p.x), round(y)], "flip": p.x > 360.0})
		"nest":
			if tool == "ant" or tool == "beetle":
				draft["nests"].append({"insect": tool, "pos": [round(p.x), _surface(p.x) - 20.0], "count": 6 if tool == "ant" else 2, "interval": 0.6 if tool == "ant" else 1.5, "delay": 0.5})
			else:
				draft["nests"].append({"insect": tool, "pos": [round(p.x), round(clampf(p.y, 280.0, 760.0))], "count": 6, "interval": 0.4, "delay": 0.4})
		"rock":
			draft["rocks"].append({"pos": [round(p.x), round(minf(p.y, GROUND - 10.0))], "r": 30})
		"block":
			var top := _surface(p.x)
			draft["blocks"].append([round(p.x - 50.0), top - 70.0, round(p.x + 50.0), top])
	draft["verified"] = false
	Sfx.play("pop", -2.0, 1.1)
	_rebuild()


func _erase(p: Vector2) -> void:
	var best_list := ""
	var best_i := -1
	var bd := 80.0
	for key in ["animals", "nests", "rocks"]:
		var arr: Array = draft[key]
		for i in arr.size():
			var q := Vector2(arr[i]["pos"][0], arr[i]["pos"][1])
			if q.distance_to(p) < bd:
				bd = q.distance_to(p)
				best_list = key
				best_i = i
	var blocks: Array = draft["blocks"]
	for i in blocks.size():
		var b: Array = blocks[i]
		var q := Vector2((float(b[0]) + float(b[2])) * 0.5, (float(b[1]) + float(b[3])) * 0.5)
		if q.distance_to(p) < bd:
			bd = q.distance_to(p)
			best_list = "blocks"
			best_i = i
	if best_i < 0:
		return
	(draft[best_list] as Array).remove_at(best_i)
	draft["verified"] = false
	Sfx.play("ui_back")
	_rebuild()


func _test() -> void:
	if draft["animals"].is_empty() or draft["nests"].is_empty():
		Sfx.play("ui_locked")
		_status.text = "Coloque pelo menos 1 bichinho e 1 ninho!"
		return
	custom_index = Game.save_custom(custom_index, draft)
	go.emit("level", playable(draft, custom_index))


func _save_and_exit() -> void:
	if not draft["animals"].is_empty() or not draft["nests"].is_empty():
		custom_index = Game.save_custom(custom_index, draft)
	go.emit("editor", null)
