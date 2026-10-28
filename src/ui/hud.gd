class_name Hud
extends CanvasLayer
## Interface durante a fase: tinta, cronômetro, dica, pausa e resultado.
## Não há anúncios aqui: nada interrompe uma tentativa (docs/11-monetizacao.md).

signal action(name: String)

var level: Level
var root: Control
var ink_bar: InkBar
var title_label: Label
var status_label: Label
var tip_panel: PanelContainer
var hint_btn: Button
var hint_badge: Label
var play_btn: Button
var overlay: Control


func bind(p_level: Level) -> void:
	level = p_level
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.make_theme()
	add_child(root)
	_build_top()
	_build_bottom()
	_build_tip()
	level.state_changed.connect(_on_state)
	level.result_ready.connect(_on_result)
	level.drawer.ink_changed.connect(func(_l, _t): ink_bar.queue_redraw())
	level.drawer.stroke_started.connect(hide_tip)
	Game.hints_changed.connect(_on_hints_changed)
	refresh()


func _on_hints_changed(_h: int) -> void:
	refresh()


func _build_top() -> void:
	var top := MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		top.add_theme_constant_override("margin_" + side, 20)
	top.add_theme_constant_override("margin_top", 24)
	root.add_child(top)
	var row := UiKit.hbox(14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(row)
	var pause := UiKit.icon_button("pause")
	pause.pressed.connect(_open_pause)
	row.add_child(pause)
	var mid := UiKit.vbox(6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mid)
	title_label = UiKit.label("%s  %s" % [level.data.get("id", ""), level.data.get("name", "")], 26, Palette.WHITE, 10, Palette.OUTLINE)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	mid.add_child(title_label)
	ink_bar = InkBar.new()
	ink_bar.level = level
	ink_bar.custom_minimum_size = Vector2(300, 46)
	mid.add_child(ink_bar)
	var restart := UiKit.icon_button("restart")
	restart.pressed.connect(func(): action.emit("restart"))
	row.add_child(restart)
	status_label = UiKit.label("", 34, Palette.WHITE, 12, Palette.OUTLINE)
	status_label.anchor_left = 0.0
	status_label.anchor_right = 1.0
	status_label.offset_top = 150
	status_label.offset_bottom = 210
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(status_label)


func _build_bottom() -> void:
	hint_btn = UiKit.icon_button("hint", Palette.GOLD, 96)
	_anchor_box(hint_btn, Vector2(1, 1), Rect2(-120, -226, 96, 96))
	hint_btn.pressed.connect(_on_hint)
	root.add_child(hint_btn)
	hint_badge = UiKit.label("0", 22, Palette.WHITE, 8, Palette.OUTLINE)
	hint_badge.position = Vector2(62, -14)
	hint_badge.size = Vector2(40, 30)
	hint_btn.add_child(hint_badge)
	play_btn = UiKit.button("Pronto!", Palette.UI_GOOD, "play", 260)
	_anchor_box(play_btn, Vector2(0.5, 1), Rect2(-130, -236, 260, 96))
	play_btn.visible = false
	play_btn.pressed.connect(func(): action.emit("play"))
	root.add_child(play_btn)


## Posiciona um controle por âncora (0..1 do pai) + retângulo de deslocamento fixo.
static func _anchor_box(c: Control, anchor: Vector2, r: Rect2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = r.position.x
	c.offset_top = r.position.y
	c.offset_right = r.end.x
	c.offset_bottom = r.end.y


func _build_tip() -> void:
	var tip := str(level.data.get("tip", ""))
	if tip == "":
		return
	# o balão fica na faixa de terra embaixo (nunca cobre ninhos nem bichinhos)
	tip_panel = UiKit.panel(Palette.CREAM)
	tip_panel.anchor_left = 0.0
	tip_panel.anchor_right = 1.0
	tip_panel.anchor_top = 1.0
	tip_panel.anchor_bottom = 1.0
	tip_panel.offset_left = 28
	tip_panel.offset_right = -140
	tip_panel.offset_top = -250
	tip_panel.offset_bottom = -130
	tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiKit.label(tip, 26, Palette.UI_TEXT, 0, Palette.WHITE, true)
	tip_panel.add_child(l)
	root.add_child(tip_panel)
	UiKit.pop_in(tip_panel, 0.3)


func hide_tip() -> void:
	if tip_panel != null and tip_panel.visible:
		var p := tip_panel
		tip_panel = null
		var tw := p.create_tween()
		tw.tween_property(p, "modulate:a", 0.0, 0.25)
		tw.tween_callback(p.queue_free)


func refresh() -> void:
	if level == null:
		return
	var drawing := level.state == Level.State.DRAWING
	hint_btn.visible = drawing and not level.solution_strokes().is_empty()
	hint_badge.text = "" if level.hint_shown else str(Game.hints())
	play_btn.visible = drawing and level.strokes_total > 1 and not level.lines.is_empty()
	ink_bar.queue_redraw()


func _process(_delta: float) -> void:
	if level == null:
		return
	if level.state == Level.State.RUNNING:
		status_label.text = "Aguente firme! %d" % int(ceil(maxf(level.time_left, 0.0)))
	elif level.state == Level.State.DRAWING and level.strokes_total > 1:
		status_label.text = "Traços: %d" % level.strokes_left
	elif level.state == Level.State.DRAWING:
		status_label.text = ""


func _on_state(_s: int) -> void:
	refresh()
	if level.state == Level.State.RUNNING:
		hide_tip()
		UiKit.pop_in(status_label)
	elif level.state != Level.State.DRAWING:
		status_label.text = ""


func _on_hint() -> void:
	if level.hint_shown or Game.hinted.has(str(level.data.get("id"))):
		level.show_hint()
		refresh()
		return
	if Game.use_hint():
		Game.hinted[str(level.data.get("id"))] = true
		level.show_hint()
		refresh()
		return
	_show_buy_hint()


func _show_buy_hint() -> void:
	var box := _open_overlay()
	box.add_child(UiKit.label("Sem dicas!", 44))
	box.add_child(UiKit.label("Troque %d moedas por 1 dica.\nVocê tem %d moedas." % [Game.HINT_PRICE, Game.coins()], 26, Palette.UI_TEXT, 0, Palette.WHITE, true))
	var row := UiKit.hbox()
	box.add_child(row)
	var no := UiKit.button("Agora não", Palette.UI_MUTED)
	no.pressed.connect(_close_overlay)
	row.add_child(no)
	var yes := UiKit.button("Trocar", Palette.GOLD, "coin")
	yes.disabled = Game.coins() < Game.HINT_PRICE
	yes.pressed.connect(func():
		if Game.buy_hint():
			Sfx.play("coin")
			_close_overlay()
			_on_hint())
	row.add_child(yes)


# ------------------------------------------------------------------ pausa
func _open_pause() -> void:
	if overlay != null or level.state == Level.State.WON or level.state == Level.State.LOST:
		return
	get_tree().paused = true
	Sfx.stop_all_loops()
	var box := _open_overlay()
	box.add_child(UiKit.label("Pausa", 52))
	var cont := UiKit.button("Continuar", Palette.UI_GOOD, "play", 420)
	cont.pressed.connect(_close_overlay)
	box.add_child(cont)
	var rs := UiKit.button("Recomeçar", Palette.UI_SECONDARY, "restart", 420)
	rs.pressed.connect(func():
		_close_overlay()
		action.emit("restart"))
	box.add_child(rs)
	var mp := UiKit.button("Mapa", Palette.UI_PRIMARY, "home", 420)
	mp.pressed.connect(func():
		_close_overlay()
		action.emit("menu"))
	box.add_child(mp)
	var toggles := UiKit.hbox(12)
	box.add_child(toggles)
	for key in ["music", "sfx"]:
		var on: bool = float(Game.setting(key)) > 0.01
		var b := UiKit.button(("Música" if key == "music" else "Sons") + (": sim" if on else ": não"), Palette.UI_PANEL, "", 200, 76)
		b.pressed.connect(func():
			var now_on: bool = float(Game.setting(key)) > 0.01
			Game.set_setting(key, 0.0 if now_on else (0.6 if key == "music" else 0.9))
			b.text = ("Música" if key == "music" else "Sons") + (": não" if now_on else ": sim"))
		toggles.add_child(b)


func on_back_pressed() -> void:
	if overlay != null:
		if level.state == Level.State.DRAWING or level.state == Level.State.RUNNING:
			_close_overlay()
		return
	_open_pause()


func _open_overlay() -> VBoxContainer:
	_close_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	overlay.add_child(UiKit.dim())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := UiKit.panel()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var box := UiKit.vbox(20)
	panel.add_child(box)
	UiKit.pop_in(panel)
	return box


func _close_overlay() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null
	if get_tree() != null:
		get_tree().paused = false


# ------------------------------------------------------------------ resultado
const LOSE_TEXT := {
	"sting": ["Ai! Uma picadinha!", "Procure frestas: os insetos deslizam pela linha até achar uma brecha."],
	"fall": ["Ops! Caiu!", "Cuidado com o peso da linha: ela cai e pode empurrar o bichinho."],
	"water": ["Molhou!", "Esse bichinho não nada. Segure-o longe da água!"],
}


func _on_result(won: bool, info: Dictionary) -> void:
	refresh()
	var box := _open_overlay()
	get_tree().paused = false
	if won:
		_build_win(box, info)
	else:
		_build_lose(box, info)


func _build_win(box: VBoxContainer, info: Dictionary) -> void:
	box.add_child(UiKit.title("Salvos!" if level.animals.size() > 1 else "Salvo!", 60))
	var stars_row := UiKit.hbox(8)
	box.add_child(stars_row)
	var stars: int = info.get("stars", 1)
	for i in 3:
		var ic := UiIcon.new()
		ic.icon = "star" if i < stars else "star_empty"
		ic.custom_minimum_size = Vector2(110, 110)
		stars_row.add_child(ic)
		UiKit.pop_in(ic, 0.25 + i * 0.3)
		if i < stars:
			var snd := "star%d" % (i + 1)
			get_tree().create_timer(0.25 + i * 0.3).timeout.connect(func(): Sfx.play(snd))
	var used := int(round(float(info.get("ink_used", 0.0)) * 100.0))
	box.add_child(UiKit.label("Tinta usada: %d%%" % used, 26))
	var coin_row := UiKit.hbox(8)
	var ci := UiIcon.new()
	ci.icon = "coin"
	ci.custom_minimum_size = Vector2(44, 44)
	coin_row.add_child(ci)
	coin_row.add_child(UiKit.label("+%d   (total %d)" % [int(info.get("coins", 0)), Game.coins()], 30))
	box.add_child(coin_row)
	get_tree().create_timer(1.3).timeout.connect(func(): Sfx.play("coin"))
	for f in info.get("new_friends", []):
		if f != "capi" or Game.data["met"].size() > 1:
			box.add_child(UiKit.label("Novo amigo: %s!" % Animal.SPECIES[f]["name"], 28, Palette.UI_PRIMARY))
	var got: Array = info.get("achievements", [])
	for k in mini(got.size(), 2):
		box.add_child(UiKit.label("Conquista: %s" % Game.ACHIEVEMENTS[got[k]]["name"], 26, Palette.UI_GOOD))
	if got.size() > 2:
		box.add_child(UiKit.label("+%d conquistas! Veja em Bichinhos." % (got.size() - 2), 24, Palette.UI_GOOD))
	if not got.is_empty():
		get_tree().create_timer(1.6).timeout.connect(func(): Sfx.play("unlock"))
	var row := UiKit.hbox(16)
	box.add_child(row)
	var home := UiKit.icon_button("home", Palette.UI_PANEL, 96)
	home.pressed.connect(func(): action.emit("menu"))
	row.add_child(home)
	var again := UiKit.icon_button("restart", Palette.UI_SECONDARY, 96)
	again.pressed.connect(func(): action.emit("restart"))
	row.add_child(again)
	var has_next := level.index + 1 < LevelDB.count()
	var nxt := UiKit.button("Próxima" if has_next else "Mapa", Palette.UI_GOOD, "next", 240, 96)
	nxt.pressed.connect(func(): action.emit("next" if has_next else "menu"))
	row.add_child(nxt)


func _build_lose(box: VBoxContainer, info: Dictionary) -> void:
	var reason := str(info.get("reason", "sting"))
	var txt: Array = LOSE_TEXT.get(reason, LOSE_TEXT["sting"])
	box.add_child(UiKit.title(txt[0], 52))
	box.add_child(UiKit.label(txt[1], 26, Palette.UI_TEXT, 0, Palette.WHITE, true))
	var row := UiKit.hbox(16)
	box.add_child(row)
	var home := UiKit.icon_button("home", Palette.UI_PANEL, 96)
	home.pressed.connect(func(): action.emit("menu"))
	row.add_child(home)
	if not level.solution_strokes().is_empty():
		var hint := UiKit.icon_button("hint", Palette.GOLD, 96)
		hint.pressed.connect(func():
			Game.pending_hint = true
			action.emit("restart"))
		row.add_child(hint)
	var again := UiKit.button("De novo!", Palette.UI_GOOD, "restart", 260, 96)
	again.pressed.connect(func(): action.emit("restart"))
	row.add_child(again)


class InkBar:
	extends Control
	## Barra de tinta com marcas de estrela: o jogador vê quanto pode gastar para 3★/2★.
	var level: Level

	func _draw() -> void:
		if level == null:
			return
		var r := Rect2(Vector2(0, 6), Vector2(size.x, size.y - 12))
		var o := Palette.OUTLINE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.9)
		sb.set_corner_radius_all(int(r.size.y * 0.5))
		sb.set_border_width_all(4)
		sb.border_color = o
		draw_style_box(sb, r)
		var frac := clampf(level.drawer.ink_left / maxf(level.drawer.ink_total, 1.0), 0.0, 1.0)
		if frac > 0.0:
			var fill := StyleBoxFlat.new()
			fill.bg_color = Palette.INK if frac > 0.2 else Palette.INK_LOW
			fill.set_corner_radius_all(int(r.size.y * 0.5) - 4)
			draw_style_box(fill, Rect2(r.position + Vector2(5, 5), Vector2((r.size.x - 10) * frac, r.size.y - 10)))
		var th: Array = level.data.get("stars", [0.4, 0.7])
		for i in th.size():
			var x := r.position.x + 5 + (r.size.x - 10) * (1.0 - float(th[i]))
			draw_line(Vector2(x, r.position.y + 2), Vector2(x, r.end.y - 2), o, 3.0, true)
			var n := 3 - i
			for k in n:
				var p := Vector2(x - (n - 1) * 7.0 + k * 14.0, r.position.y - 2)
				DrawUtil.shape(self, DrawUtil.star_points(p, 8.0, 3.6), Palette.GOLD, o, 2.0)
