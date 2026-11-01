class_name EditorScreen
extends Control
## Editor de fases: a fase aparece de verdade (mesmo motor) e o jogador toca para colocar
## bichinhos, ninhos, pedras e blocos. "Testar" joga a fase; vencendo, ela ganha o selo.
## Layout responsivo: barras presas às bordas da área segura, botões que dividem a
## largura disponível (nunca saem da tela) e seletores com TODOS os bichinhos e insetos.

signal go(screen: String, arg: Variant)

const GROUND := 1000.0
const MAX := {"animal": 4, "nest": 5, "rock": 6, "block": 6}
const TIMES := [6.0, 8.0, 10.0, 12.0, 15.0]
const INKS := [["Pouca", 450], ["Média", 750], ["Muita", 1100]]
const UNDO_MAX := 40
const TILE_H := 96.0
## Quantidades que o ninho pode soltar (toque no ninho de novo para trocar).
const COUNTS := [2, 3, 4, 6, 8, 10]
## [quantidade, intervalo] iniciais de cada tipo.
const NEST_DEFAULTS := {
	"bee": [6, 0.4], "mosquito": [6, 0.35], "wasp": [2, 1.4], "moth": [4, 0.8], "broca": [3, 0.9],
	"ant": [6, 0.6], "beetle": [2, 1.5], "termite": [3, 1.0], "caterpillar": [3, 1.2], "cricket": [4, 1.0],
	"spider": [2, 2.0], "crab": [2, 1.2], "jellyfish": [4, 0.8], "puffer": [2, 1.4], "drillfish": [2, 1.4],
}

var custom_index := -1
var draft: Dictionary
var tool := "animal"
var species := "capi"
var insect_kind := "bee"
var hole_mode := false
var _lv: Level
## A interface fica numa camada própria: a câmera da fase desloca o desenho em telas
## mais altas que 16:9, e a doca não pode ser empurrada para fora da tela junto.
var _layer: CanvasLayer
var _ui: Control
var _tool_btns: Dictionary = {}
var _name_label: Label
var _world_label: Label
var _status: Label
var _counts: Label
var _opt_btns: Dictionary = {}
var _top: HBoxContainer
var _opts: HBoxContainer
var _dock: PanelContainer
var _modal: Control
var _undo: Array = []
## Câmera do cenário: em telas baixas desce para o chão não ficar escondido atrás da doca.
var _cam_y := 640.0
var _animal_preview: PreviewBox
var _insect_preview: PreviewBox


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer = CanvasLayer.new()
	_layer.layer = 1
	add_child(_layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.theme = theme if theme != null else UiKit.make_theme()
	_ui.gui_input.connect(_on_canvas_input)
	_layer.add_child(_ui)
	var list: Array = Game.custom_levels()
	if custom_index >= 0 and custom_index < list.size():
		draft = (list[custom_index] as Dictionary).duplicate(true)
	else:
		custom_index = -1
		draft = new_draft(list.size() + 1)
	for key in ["animals", "nests", "rocks", "blocks"]:
		if not draft.has(key) or not (draft[key] is Array):
			draft[key] = []
	# começa com um bichinho que o jogador já conhece (ou a Capitu)
	for sp in Game.data["met"]:
		if all_species().has(str(sp)):
			species = str(sp)
			break
	_build_ui()
	_ui.resized.connect(_layout)
	_rebuild()
	_layout()
	Sfx.music("music_menu")


static func new_draft(n: int) -> Dictionary:
	return {"name": UiKit.tr_text("Minha fase %d") % n, "world": 1, "survive": 8.0, "ink": 750, "strokes": 1,
		"animals": [], "nests": [], "rocks": [], "blocks": [], "verified": false}


## Todos os bichinhos que podem aparecer nas fases.
static func all_species() -> Array:
	return Cast.ORDER.duplicate()


## Todos os insetos e criaturas que podem sair de um ninho.
static func all_insects() -> Array:
	return Nest.KINDS.duplicate()


static func world_count() -> int:
	return maxi(1, LevelDB.worlds.size())


static func is_walker(kind: String) -> bool:
	return not Nest.FLYERS.has(kind) and not Nest.SEA.has(kind) and kind != "spider"


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


# ------------------------------------------------------------------ interface
func _build_ui() -> void:
	# barra de cima: voltar · mundo (‹ nome ›) · testar
	_top = UiKit.hbox(8)
	_ui.add_child(_top)
	var back := UiKit.icon_button("back", Palette.UI_PANEL, 76)
	back.pressed.connect(_save_and_exit)
	_top.add_child(back)
	var prev := UiKit.icon_button("back", Palette.UI_SECONDARY, 64)
	prev.pressed.connect(func(): _world(-1))
	_top.add_child(prev)
	var names := UiKit.vbox(0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_child(names)
	_name_label = _clipped(UiKit.label("", 24, Palette.WHITE, 8, Palette.OUTLINE))
	names.add_child(_name_label)
	_world_label = _clipped(UiKit.label("", 18, Palette.WHITE, 6, Palette.OUTLINE))
	names.add_child(_world_label)
	var nxt := UiKit.icon_button("next", Palette.UI_SECONDARY, 64)
	nxt.pressed.connect(func(): _world(1))
	_top.add_child(nxt)
	var test := UiKit.button("Testar", Palette.UI_GOOD, "play", 150, 76)
	test.add_theme_font_size_override("font_size", UiKit.fs(24))
	test.pressed.connect(_test)
	_top.add_child(test)

	# opções da fase: dividem a largura (clip_text: nunca empurram a tela para fora)
	_opts = UiKit.hbox(8)
	_ui.add_child(_opts)
	for key in ["time", "ink", "strokes"]:
		var b := UiKit.button("", Palette.UI_PANEL, "", 0, 62)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_theme_font_size_override("font_size", UiKit.fs(20))
		var k: String = key
		b.pressed.connect(func(): _cycle(k))
		_opts.add_child(b)
		_opt_btns[key] = b
	var rename := UiKit.icon_button("pencil", Palette.UI_PANEL, 62)
	rename.pressed.connect(_ask_name)
	_opts.add_child(rename)
	var clear := UiKit.icon_button("close", Palette.DANGER, 62)
	clear.pressed.connect(_ask_clear)
	_opts.add_child(clear)

	_status = UiKit.label("", 21, Palette.WHITE, 8, Palette.OUTLINE, true)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_ui.add_child(_status)

	# doca de ferramentas embaixo: sempre inteira na tela
	_dock = PanelContainer.new()
	var st := UiKit.panel_style(Color(Palette.UI_PANEL, 0.94), 28)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 8
	st.content_margin_bottom = 10
	_dock.add_theme_stylebox_override("panel", st)
	_ui.add_child(_dock)
	var col := UiKit.vbox(6)
	_dock.add_child(col)
	_counts = _clipped(UiKit.label("", 19, Palette.UI_TEXT))
	col.add_child(_counts)
	var row := UiKit.hbox(6)
	col.add_child(row)
	for spec in [["animal", "Bichinho", ""], ["insect", "Inseto", ""], ["rock", "Pedra", "rock"], ["block", "Bloco", "block"], ["erase", "Apagar", "close"], ["undo", "Desfazer", "restart"]]:
		var id: String = spec[0]
		var b := _tool_tile(spec[1], spec[2])
		row.add_child(b)
		_tool_btns[id] = b
		match id:
			"animal": b.pressed.connect(func(): _open_picker("animal"))
			"insect": b.pressed.connect(func(): _open_picker("insect"))
			"undo": b.pressed.connect(_undo_last)
			_: b.pressed.connect(func(): _select(id))
	_animal_preview = _tool_btns["animal"].get_meta("preview")
	_insect_preview = _tool_btns["insect"].get_meta("preview")
	_refresh_previews()
	_select("animal")


static func _clipped(l: Label) -> Label:
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = 40
	return l


## Azulejo que divide a largura com os vizinhos: ícone (ou desenho) em cima, nome embaixo.
func _tool_tile(text: String, icon: String) -> Button:
	var b := UiKit.button("", Palette.UI_PANEL, "", 0, int(TILE_H))
	b.custom_minimum_size = Vector2(0, TILE_H)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := PreviewBox.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 6
	box.offset_bottom = -34
	b.add_child(box)
	b.set_meta("preview", box)
	if icon != "":
		var ic := UiIcon.new()
		ic.icon = icon
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = 18
		ic.offset_right = -18
		box.add_child(ic)
	var l := _clipped(UiKit.label(text, 16 if bool(Game.setting("big_text")) else 17))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.custom_minimum_size.x = 0
	l.anchor_right = 1.0
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.offset_top = -38
	l.offset_bottom = -10
	b.add_child(l)
	return b


func _refresh_previews() -> void:
	var a := AnimalArt.new()
	a.species = species
	a.preview = true
	a.scale = Vector2.ONE * fit_scale(species, 0.62)
	_animal_preview.show_node(a, Vector2(0.5, 0.5))
	var ia := InsectArt.new()
	ia.kind = insect_kind
	ia.radius = 15.0
	_insect_preview.show_node(ia, Vector2(0.5, 0.55))


## Escala para o desenho caber num azulejo (a capivara é bem mais larga que o esquilo).
static func fit_scale(sp: String, base: float) -> float:
	var cfg: Dictionary = Animal.SPECIES.get(sp, {})
	var half_w := float(cfg.get("r", 24.0))
	if str(cfg.get("shape", "")) == "hcapsule":
		half_w = float(cfg.get("h", 60.0)) * 0.5
	return base * clampf(34.0 / maxf(half_w, Animal.half_height(sp)), 0.5, 1.15)


## Posiciona as barras dentro da área segura do aparelho (entalhe, barra de gestos).
func _layout() -> void:
	var size := _ui.size
	if size.x <= 0 or size.y <= 0 or _top == null:
		return
	# área segura + faixa de gestos do Android embaixo (toques colados na borda se perdem)
	var ins := UiKit.safe_insets(_ui)
	var bottom := maxf(ins.w + 12.0, UiKit.GESTURE_GAP)
	var safe := Rect2(ins.x, ins.y, size.x - ins.x - ins.z, size.y - ins.y - bottom + 12.0)
	var margin := 12.0
	var left := safe.position.x + margin
	var width := safe.size.x - margin * 2
	_top.position = Vector2(left, safe.position.y + 14)
	_top.size = Vector2(width, 76)
	_opts.position = Vector2(left, _top.position.y + 86)
	_opts.size = Vector2(width, 62)
	# autowrap: a largura vem das âncoras (senão a altura mínima explode e o texto desce)
	_status.anchor_left = 0.0
	_status.anchor_right = 1.0
	_status.offset_left = left
	_status.offset_right = -(size.x - safe.end.x) - margin
	_status.offset_top = _opts.position.y + 70
	_status.offset_bottom = _status.offset_top + 56
	var dock_h := _dock.get_combined_minimum_size().y
	_dock.position = Vector2(left, safe.end.y - dock_h - margin)
	_dock.size = Vector2(width, dock_h)
	# o chão (e o que fica nele) precisa aparecer acima da doca
	_cam_y = maxf(640.0, GROUND + 40.0 + size.y * 0.5 - (_dock.position.y - 8.0))
	if _lv != null and _lv.camera != null:
		_lv.camera.position.y = _cam_y


func _option_text(key: String) -> String:
	match key:
		"time":
			return tr("Tempo %ds") % int(draft["survive"])
		"ink":
			var n := "Média"
			for k in INKS:
				if int(k[1]) == int(draft["ink"]):
					n = k[0]
			return tr("Tinta: %s") % tr(n)
		"strokes":
			return tr("Traços: %d") % int(draft["strokes"])
	return ""


func _cycle(key: String) -> void:
	_push_undo()
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
			draft["strokes"] = int(draft["strokes"]) % 3 + 1
	draft["verified"] = false
	Sfx.play("pop", -6.0, 1.2)
	_update_labels()


func _select(id: String) -> void:
	# compatível com o editor antigo: _select("bee") escolhe o inseto direto
	if Nest.KINDS.has(id):
		insect_kind = id
		id = "insect"
		_refresh_previews()
	tool = id
	for k in _tool_btns.keys():
		var b: Button = _tool_btns[k]
		var col := Palette.GOLD if k == id else Palette.UI_PANEL
		b.add_theme_stylebox_override("normal", UiKit.btn_style(col, false))
		b.add_theme_stylebox_override("hover", UiKit.btn_style(col.lightened(0.06), false))
	_update_labels()


func _update_labels() -> void:
	_name_label.text = str(draft.get("name", ""))
	var w := LevelDB.world_info(int(draft["world"]))
	_world_label.text = (tr(str(w["name"])) if w.has("name") else tr("Mundo %d") % int(draft["world"])) + "  ·  %d/%d" % [int(draft["world"]), world_count()]
	for key in _opt_btns.keys():
		(_opt_btns[key] as Button).text = _option_text(key)
	var msg := ""
	match tool:
		"animal":
			msg = tr("Toque no cenário para pôr: %s. Toque nele de novo para virar.") % Animal.SPECIES[species]["name"]
		"insect":
			var nm: String = Cast.INSECTS.get(insect_kind, {}).get("name", insect_kind)
			if is_walker(insect_kind):
				msg = tr("Toque no chão: %s sai de um %s.") % [tr(nm), tr("buraco") if hole_mode else tr("formigueiro")]
			else:
				msg = tr("Toque no céu para pôr o ninho: %s.") % tr(nm)
			msg += " " + tr("Toque num ninho para mudar a quantidade.")
		"rock": msg = tr("Toque para pôr uma pedra pesada.")
		"block": msg = tr("Toque para pôr um bloco de pedra (empilha!).")
		"erase": msg = tr("Toque perto de algo para apagar.")
		_: msg = tr("Toque para pôr")
	_status.text = msg
	_counts.text = tr("Bichinhos %d/%d · Ninhos %d/%d · Pedras %d/%d · Blocos %d/%d") % [
		_count("animal"), MAX["animal"], _count("nest"), MAX["nest"], _count("rock"), MAX["rock"], _count("block"), MAX["block"]]
	if _tool_btns.has("undo"):
		(_tool_btns["undo"] as Button).disabled = _undo.is_empty()


func _world(dir: int) -> void:
	_push_undo()
	var n := world_count()
	draft["world"] = (int(draft["world"]) - 1 + dir + n) % n + 1
	draft["verified"] = false
	Sfx.play("ui_click", -4.0)
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
	if _lv.camera != null:
		_lv.camera.position.y = _cam_y
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


## Toque no cenário (os painéis consomem os próprios toques antes de chegar aqui).
func _on_canvas_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _modal != null:
		return
	var p := _to_world(mb.position)
	if p.y < 250.0 or p.y > GROUND + 40.0 or p.x < 30.0 or p.x > 690.0:
		return
	_place(p)
	_ui.accept_event()


func _place(p: Vector2) -> void:
	var kind: String = {"animal": "animal", "rock": "rock", "block": "block", "erase": "erase", "insect": "nest"}.get(tool, "nest")
	if kind == "erase":
		_erase(p)
		return
	# tocar de novo num item já posto: vira o bichinho / muda a quantidade do ninho
	if kind == "animal":
		var i := _nearest("animals", p, 60.0)
		if i >= 0:
			_push_undo()
			var a: Dictionary = draft["animals"][i]
			a["flip"] = not bool(a.get("flip", false))
			Sfx.play("pop", -4.0, 1.3)
			_changed()
			return
	if kind == "nest":
		var i := _nearest("nests", p, 50.0)
		if i >= 0:
			_push_undo()
			var n: Dictionary = draft["nests"][i]
			var c := COUNTS.find(int(n.get("count", 4)))
			n["count"] = COUNTS[(c + 1) % COUNTS.size()]
			Sfx.play("pop", -4.0, 0.9 + 0.05 * float(n["count"]))
			_changed()
			_status.text = tr("Este ninho agora solta %d.") % int(n["count"])
			return
	if _count(kind) >= int(MAX[kind]):
		Sfx.play("ui_locked")
		_status.text = tr("Limite atingido! Apague algo primeiro.")
		return
	if kind == "block" and _surface(p.x) < 330.0:
		Sfx.play("ui_locked")
		_status.text = tr("Alto demais! Não dá para empilhar mais aqui.")
		return
	_push_undo()
	match kind:
		"animal":
			var y := _surface(p.x) - Animal.half_height(species) - 1.0
			draft["animals"].append({"type": species, "pos": [round(p.x), round(y)], "flip": p.x > 360.0})
		"nest":
			draft["nests"].append(_make_nest(insect_kind, p))
		"rock":
			draft["rocks"].append({"pos": [round(p.x), round(minf(p.y, GROUND - 10.0))], "r": 30})
		"block":
			var top := _surface(p.x)
			draft["blocks"].append([round(p.x - 50.0), top - 70.0, round(p.x + 50.0), top])
	Sfx.play("pop", -2.0, 1.1)
	_changed()


func _make_nest(kind: String, p: Vector2) -> Dictionary:
	var cfg: Array = NEST_DEFAULTS.get(kind, [4, 0.8])
	var nest := {"insect": kind, "count": int(cfg[0]), "interval": float(cfg[1]), "delay": 0.5}
	if is_walker(kind):
		if hole_mode:
			nest["pos"] = [round(p.x), _surface(p.x)]
			nest["hole"] = true
		else:
			nest["pos"] = [round(p.x), _surface(p.x) - 20.0]
	else:
		nest["pos"] = [round(p.x), round(clampf(p.y, 280.0, 760.0))]
		nest["delay"] = 0.4
	return nest


func _nearest(key: String, p: Vector2, max_d: float) -> int:
	var best := -1
	var bd := max_d
	var arr: Array = draft[key]
	for i in arr.size():
		var q := Vector2(arr[i]["pos"][0], arr[i]["pos"][1])
		if q.distance_to(p) < bd:
			bd = q.distance_to(p)
			best = i
	return best


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
	_push_undo()
	(draft[best_list] as Array).remove_at(best_i)
	if best_list == "blocks":
		_settle()
	Sfx.play("ui_back")
	_changed()


## Depois de apagar um bloco, o que estava em cima desce até a nova superfície.
func _settle() -> void:
	var blocks: Array = draft["blocks"]
	blocks.sort_custom(func(a, b): return float(a[3]) > float(b[3]))
	var placed: Array = []
	for b in blocks:
		var cx := (float(b[0]) + float(b[2])) * 0.5
		var top := GROUND
		for o in placed:
			if cx >= float(o[0]) and cx <= float(o[2]):
				top = minf(top, float(o[1]))
		var h := float(b[3]) - float(b[1])
		b[3] = top
		b[1] = top - h
		placed.append(b)
	draft["blocks"] = placed
	for a in draft["animals"]:
		a["pos"][1] = round(_surface(float(a["pos"][0])) - Animal.half_height(str(a["type"])) - 1.0)


func _changed() -> void:
	draft["verified"] = false
	_rebuild()


func _push_undo() -> void:
	_undo.append(draft.duplicate(true))
	if _undo.size() > UNDO_MAX:
		_undo.pop_front()


func _undo_last() -> void:
	if _undo.is_empty():
		Sfx.play("ui_locked")
		return
	draft = _undo.pop_back()
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


# ------------------------------------------------------------------ janelas
func _open_modal(title_text: String) -> VBoxContainer:
	_close_modal()
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(_modal)
	var dim := UiKit.dim(0.55)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_close_modal())
	_modal.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal.add_child(center)
	var panel := PanelContainer.new()
	var st := UiKit.panel_style(Palette.CREAM)
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 16
	st.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size.x = minf(_ui.size.x - 36.0, 700.0)
	center.add_child(panel)
	var col := UiKit.vbox(12)
	panel.add_child(col)
	var head := UiKit.hbox(8)
	col.add_child(head)
	var t := _clipped(UiKit.label(title_text, 30))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close := UiKit.icon_button("close", Palette.UI_SECONDARY, 64)
	close.pressed.connect(_close_modal)
	head.add_child(close)
	_modal.modulate.a = 0.0
	var tw := _modal.create_tween()
	tw.tween_property(_modal, "modulate:a", 1.0, 0.16)
	return col


func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null


## Seletor com TODOS os bichinhos (ou todos os insetos) do jogo, em grade rolável.
func _open_picker(which: String) -> void:
	var col := _open_modal(tr("Escolha o bichinho") if which == "animal" else tr("Escolha o inseto"))
	var scroll := ScrollContainer.new()
	DragScroll.attach(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = clampf(_ui.size.y * 0.56, 300.0, 900.0)
	col.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4 if _ui.size.x >= 900 else 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	var ids: Array = all_species() if which == "animal" else all_insects()
	for id in ids:
		grid.add_child(_picker_cell(which, str(id)))
	if which == "insect":
		var hole_btn := UiKit.button("", Palette.UI_GOOD if hole_mode else Palette.UI_MUTED, "", 0, 66)
		hole_btn.text = tr("Andarilhos saem de: %s") % (tr("buraco no chão") if hole_mode else tr("formigueiro"))
		hole_btn.clip_text = true
		hole_btn.add_theme_font_size_override("font_size", UiKit.fs(21))
		hole_btn.pressed.connect(func():
			hole_mode = not hole_mode
			_open_picker("insect"))
		col.add_child(hole_btn)
	col.add_child(UiKit.label(tr("Role para ver todos (%d).") % ids.size(), 19, Color(Palette.UI_TEXT, 0.7)))


func _picker_cell(which: String, id: String) -> Button:
	var selected := (which == "animal" and id == species) or (which == "insect" and id == insect_kind)
	var b := UiKit.button("", Palette.GOLD if selected else Palette.UI_PANEL, "", 0, 156)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(150, 156)
	var box := PreviewBox.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 8
	box.offset_bottom = -42
	b.add_child(box)
	var label_text := ""
	if which == "animal":
		var a := AnimalArt.new()
		a.species = id
		a.preview = true
		a.accessory = Game.equipped(id)
		a.scale = Vector2.ONE * fit_scale(id, 1.05)
		box.show_node(a, Vector2(0.5, 0.52))
		label_text = Animal.SPECIES[id]["name"]
	else:
		var ia := InsectArt.new()
		ia.kind = id
		ia.radius = 20.0
		box.show_node(ia, Vector2(0.5, 0.55))
		label_text = tr(str(Cast.INSECTS.get(id, {}).get("name", id)))
	var l := _clipped(UiKit.label(label_text, 18))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.custom_minimum_size.x = 0
	l.anchor_right = 1.0
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.offset_left = 6
	l.offset_right = -6
	l.offset_top = -46
	l.offset_bottom = -12
	b.add_child(l)
	b.pressed.connect(func():
		if which == "animal":
			species = id
			_refresh_previews()
			_select("animal")
		else:
			insect_kind = id
			_refresh_previews()
			_select("insect")
			var desc: String = Cast.INSECTS.get(id, {}).get("desc", "")
			if desc != "":
				_status.text = tr(desc)
		Sfx.play("pop", -2.0, 1.2)
		_close_modal())
	return b


func _ask_name() -> void:
	var col := _open_modal(tr("Nome da fase"))
	var entry := LineEdit.new()
	entry.text = str(draft.get("name", ""))
	entry.max_length = 28
	entry.custom_minimum_size = Vector2(0, 72)
	entry.add_theme_font_size_override("font_size", UiKit.fs(28))
	entry.select_all_on_focus = true
	col.add_child(entry)
	var ok := UiKit.button("Salvar nome", Palette.UI_GOOD, "check", 0, 76)
	var apply := func():
		var t := entry.text.strip_edges()
		if t != "":
			_push_undo()
			draft["name"] = t
		_close_modal()
		_update_labels()
	ok.pressed.connect(apply)
	entry.text_submitted.connect(func(_t: String): apply.call())
	col.add_child(ok)
	entry.grab_focus.call_deferred()


func _ask_clear() -> void:
	var col := _open_modal(tr("Limpar a fase?"))
	col.add_child(UiKit.label("Tira todos os bichinhos, ninhos, pedras e blocos. Dá para desfazer.", 22, Palette.UI_TEXT, 0, Palette.WHITE, true))
	var row := UiKit.hbox(10)
	col.add_child(row)
	var no := UiKit.button("Cancelar", Palette.UI_SECONDARY, "", 0, 76)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(_close_modal)
	row.add_child(no)
	var yes := UiKit.button("Limpar", Palette.DANGER, "close", 0, 76)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func():
		_push_undo()
		for key in ["animals", "nests", "rocks", "blocks"]:
			draft[key] = []
		_close_modal()
		Sfx.play("ui_back")
		_changed())
	row.add_child(yes)


## Caixinha que mantém um desenho (Node2D) centralizado quando o botão muda de tamanho.
class PreviewBox:
	extends Control
	var node: Node2D
	var ratio := Vector2(0.5, 0.5)

	func _ready() -> void:
		resized.connect(_center)
		_center()

	func show_node(n: Node2D, r: Vector2) -> void:
		if node != null and is_instance_valid(node):
			node.queue_free()
		node = n
		ratio = r
		add_child(n)
		_center()

	func _center() -> void:
		if node != null and is_instance_valid(node):
			node.position = size * ratio
