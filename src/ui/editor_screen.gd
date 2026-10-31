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
var _root: Control


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
	return {"name": UiKit.tr_text("Minha fase %d") % n, "world": 1, "survive": 8.0, "ink": 750, "strokes": 1,
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
	# a interface fica numa camada própria: a câmera da fase de fundo não pode arrastá-la
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiKit.make_theme()
	_root.gui_input.connect(_on_canvas_input)
	layer.add_child(_root)
	var col := UiKit.vbox(10)
	col.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	col.offset_left = 14
	col.offset_right = -14
	col.offset_top = 18
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(col)
	var top := UiKit.hbox(10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var back := UiKit.icon_button("back", Palette.UI_PANEL, 80)
	back.pressed.connect(_save_and_exit)
	top.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var test := UiKit.button("Testar", Palette.UI_GOOD, "play", 190, 80)
	test.pressed.connect(_test)
	top.add_child(test)
	# cenário: setas + nome (linha própria, o nome pode ser comprido)
	var wrow := UiKit.hbox(10)
	wrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(wrow)
	var prev := UiKit.icon_button("back", Palette.UI_SECONDARY, 64)
	prev.pressed.connect(func(): _world(-1))
	wrow.add_child(prev)
	_name_label = UiKit.label("", 24, Palette.WHITE, 10, Palette.OUTLINE)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.clip_text = true
	_name_label.custom_minimum_size.x = 80
	wrow.add_child(_name_label)
	var nxt := UiKit.icon_button("next", Palette.UI_SECONDARY, 64)
	nxt.pressed.connect(func(): _world(1))
	wrow.add_child(nxt)
	var opts := HFlowContainer.new()
	opts.alignment = FlowContainer.ALIGNMENT_CENTER
	opts.add_theme_constant_override("h_separation", 8)
	opts.add_theme_constant_override("v_separation", 8)
	opts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(opts)
	for spec in [["time", "timer"], ["ink", "ink"], ["strokes", "pencil"]]:
		var b := UiKit.button("-", Palette.UI_PANEL, spec[1], 0, 60)
		b.add_theme_font_size_override("font_size", UiKit.fs(20))
		b.custom_minimum_size.x = 190
		var key: String = spec[0]
		b.pressed.connect(func():
			_cycle(key)
			_option_text(b, key))
		_option_text(b, key)
		opts.add_child(b)
	_status = UiKit.label("", 20, Palette.WHITE, 8, Palette.OUTLINE, true)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_status)

	var bottom_bar := UiKit.vbox(8)
	bottom_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_top = -150
	bottom_bar.offset_left = 8
	bottom_bar.offset_right = -8
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bottom_bar)

	# primeira linha: animal selector
	var animal_row := UiKit.hbox(8)
	animal_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_bar.add_child(animal_row)
	var animal_btn := UiKit.tile("Bichinho", "paw", Palette.UI_PANEL, 100, 100)
	animal_btn.pressed.connect(_show_animals_picker)
	animal_row.add_child(animal_btn)
	_tool_btns["animal"] = animal_btn

	var species_label := UiKit.label("", 18, Palette.WHITE, 8, Palette.OUTLINE)
	species_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	animal_row.add_child(species_label)
	# guardar referência para atualizar
	_root.set_meta("species_label", species_label)

	# segunda linha: outras ferramentas
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 120
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom_bar.add_child(scroll)
	var row := UiKit.hbox(8)
	scroll.add_child(row)

	for t in TOOLS:
		if t[0] == "animal":
			continue
		var b := UiKit.tile(t[1], t[2], Palette.UI_PANEL, 100, 100)
		var id: String = t[0]
		if id in ["bee", "mosquito", "ant", "beetle"]:
			for c in b.get_children():
				if c is UiIcon:
					c.queue_free()
			var ia := InsectArt.new()
			ia.kind = id
			ia.radius = 15.0
			ia.position = Vector2(50, 40)
			b.add_child(ia)
		b.pressed.connect(func(): _select(id))
		row.add_child(b)
		_tool_btns[id] = b
	_select("animal")


func _option_text(b: Button, key: String) -> void:
	match key:
		"time":
			b.text = "     " + tr("Tempo %ds") % int(draft["survive"])
		"ink":
			var name := "Média"
			for k in INKS:
				if int(k[1]) == int(draft["ink"]):
					name = k[0]
			b.text = "     " + tr("Tinta: %s") % tr(name)
		"strokes":
			b.text = "     " + tr("Traços: %d") % int(draft["strokes"])


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
	_name_label.text = tr(str(w.get("name", ""))) if w.has("name") else tr("Mundo %d") % int(draft["world"])

	# atualizar label de bichinho
	if _root.has_meta("species_label"):
		var sp := _species[species_i]
		var lbl: Label = _root.get_meta("species_label")
		lbl.text = Animal.SPECIES[sp]["name"]

	var msg := ""
	match tool:
		"animal": msg = tr("Toque para pôr: %s") % Animal.SPECIES[_species[species_i]]["name"]
		"erase": msg = tr("Toque perto de algo para apagar")
		"bee", "mosquito": msg = tr("Toque no céu para pôr o ninho")
		"ant", "beetle": msg = tr("Toque no chão para pôr o formigueiro")
		_: msg = tr("Toque para pôr")
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


func _on_canvas_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	# fora da faixa dos botões (em cima) e da barra de ferramentas (embaixo)
	if mb.position.y < 300.0 or mb.position.y > _root.size.y - 140.0:
		return
	var p := _to_world(mb.position)
	if p.y < 150.0 or p.y > GROUND + 40.0 or p.x < 30.0 or p.x > 690.0:
		return
	_place(p)


func _place(p: Vector2) -> void:
	var kind: String = {"animal": "animal", "rock": "rock", "block": "block", "erase": "erase"}.get(tool, "nest")
	if kind == "erase":
		_erase(p)
		return
	if _count(kind) >= int(MAX[kind]):
		Sfx.play("ui_locked")
		_status.text = tr("Limite atingido! Apague algo primeiro.")
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
		_status.text = tr("Coloque pelo menos 1 bichinho e 1 ninho!")
		return
	custom_index = Game.save_custom(custom_index, draft)
	go.emit("level", playable(draft, custom_index))


func _save_and_exit() -> void:
	if not draft["animals"].is_empty() or not draft["nests"].is_empty():
		custom_index = Game.save_custom(custom_index, draft)
	go.emit("editor", null)


func _show_animals_picker() -> void:
	var all_species := Cast.ORDER.duplicate()

	var modal := Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.modulate.a = 0.0
	_root.add_child(modal)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.BLACK
	bg.color.a = 0.6
	modal.add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(700, 600)
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(Palette.BG, 20))
	modal.add_child(panel)

	var inner := UiKit.vbox(12)
	inner.offset_left = 20
	inner.offset_top = 20
	inner.offset_right = -20
	inner.offset_bottom = -20
	panel.add_child(inner)

	var title := UiKit.label("Escolha um Bichinho", 28, Palette.WHITE, 10, Palette.OUTLINE)
	inner.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	inner.add_child(grid)

	for sp in all_species:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 140)
		btn.add_theme_stylebox_override("normal", UiKit.btn_style(Palette.UI_PANEL, false))
		btn.add_theme_stylebox_override("hover", UiKit.btn_style(Palette.GOLD.lightened(0.1), false))

		var v := UiKit.vbox(4)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		btn.add_child(v)

		var art := AnimalArt.new()
		art.species = sp
		art.preview = true
		art.scale = Vector2(1.1, 1.1)
		art.custom_minimum_size = Vector2(120, 80)
		v.add_child(art)

		var name_lbl := UiKit.label(Animal.SPECIES[sp]["name"], 16, Palette.WHITE, 8, Palette.OUTLINE)
		name_lbl.alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(name_lbl)

		btn.pressed.connect(func():
			species_i = all_species.find(sp)
			_update_labels()
			modal.queue_free()
			Sfx.play("pop", 0.0, 1.2))
		grid.add_child(btn)

	var close_btn := UiKit.button("Fechar", Palette.UI_SECONDARY, "close", 200, 60)
	close_btn.pressed.connect(modal.queue_free)
	inner.add_child(close_btn)

	# animação de entrada
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "modulate:a", 1.0, 0.3)
