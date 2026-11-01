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
var free_btn: Button
var speed_btn: Button
var review: AttemptReview
var review_btn: Button
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
	level.simulation_speed_changed.connect(func(_speed: int): refresh())
	level.drawer.ink_changed.connect(func(_l, _t): ink_bar.queue_redraw())
	level.drawer.stroke_started.connect(hide_tip)
	Game.hints_changed.connect(_on_hints_changed)
	refresh()
	# primeira vez com um inseto: cartão com demonstração ao vivo e treino
	if level.mode == "campaign" and not level.free_mode:
		var kinds := Tutorials.new_kinds(level.data)
		if not kinds.is_empty():
			_open_intro.call_deferred(kinds)


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
	# a campanha é numerada sem parar: Fase 1, 2, 3... (o mundo-fase fica entre parênteses)
	var title_text := (tr("Fase %d · %s") % [level.index + 1, tr(str(level.data.get("name", "")))]) if level.mode == "campaign" else tr(str(level.data.get("name", "")))
	title_label = UiKit.label(title_text, 26, Palette.WHITE, 10, Palette.OUTLINE)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	mid.add_child(title_label)
	if level.mode == "infinite":
		# corações da corrida
		var hearts := UiKit.hbox(4)
		hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in Infinite.HEARTS:
			var h := UiIcon.new()
			h.icon = "heart"
			h.custom_minimum_size = Vector2(30, 30)
			h.modulate = Color.WHITE if i < int(Infinite.run.get("hearts", 0)) else Color(0.2, 0.2, 0.2, 0.35)
			hearts.add_child(h)
		mid.add_child(hearts)
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
	speed_btn = UiKit.button("Velocidade: 1×", Palette.UI_SECONDARY, "", 280, 80)
	speed_btn.add_theme_font_size_override("font_size", UiKit.fs(26))
	_anchor_box(speed_btn, Vector2(0.5, 1), Rect2(-150, -226, 300, 80))
	speed_btn.visible = false
	speed_btn.pressed.connect(func():
		level.set_simulation_speed(2 if level.simulation_speed == 1 else 1))
	root.add_child(speed_btn)
	# Modo Livre: liberado depois de vencer a fase uma vez
	free_btn = UiKit.button("Livre: sim" if level.free_mode else "Livre", Color("b18cff"), "ink", 0, 96)
	free_btn.add_theme_font_size_override("font_size", 24)
	_anchor_box(free_btn, Vector2(0, 1), Rect2(24, -226, 190, 96))
	free_btn.pressed.connect(func():
		Game.free_mode = not level.free_mode
		action.emit("restart"))
	root.add_child(free_btn)


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
	var tip := str(level.data.get("objective", level.data.get("tip", "")))
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
	if level == null or not is_inside_tree():
		return
	var drawing := level.state == Level.State.DRAWING
	speed_btn.visible = level.state == Level.State.RUNNING
	speed_btn.disabled = get_tree().paused
	speed_btn.text = tr("Velocidade: 2×") if level.simulation_speed == 2 else tr("Velocidade: 1×")
	speed_btn.tooltip_text = tr("Acelerar a simulação") if level.simulation_speed == 1 else tr("Voltar à velocidade normal")
	hint_btn.visible = drawing and not level.solution_strokes().is_empty()
	hint_badge.text = "" if level.hint_shown else str(Game.hints())
	play_btn.visible = drawing and level.strokes_total > 1 and not level.lines.is_empty()
	free_btn.visible = drawing and level.lines.is_empty() and not level.drawer.drawing and Game.is_completed(str(level.data.get("id", "")))
	ink_bar.queue_redraw()


func _process(_delta: float) -> void:
	if level == null:
		return
	if level.state == Level.State.RUNNING:
		status_label.text = tr("Aguente firme! %d") % int(ceil(maxf(level.time_left, 0.0)))
	elif level.state == Level.State.RUNNING and level.goal != null:
		status_label.text = tr("Rumo à toca! %d") % int(ceil(maxf(level.time_left, 0.0)))
	elif level.state == Level.State.DRAWING and level.free_mode:
		status_label.text = tr("Modo Livre: tinta infinita!")
	elif level.state == Level.State.DRAWING and level.strokes_total > 1:
		status_label.text = tr("Traços: %d") % level.strokes_left
	elif level.state == Level.State.DRAWING and level.ink_mode == "static":
		status_label.text = tr("Tinta Firme: a linha não cai!")
	elif level.state == Level.State.DRAWING:
		status_label.text = ""
	if level.state == Level.State.RUNNING and level.goal != null:
		status_label.text = tr("Rumo à toca! %d") % int(ceil(maxf(level.time_left, 0.0)))


func _on_state(_s: int) -> void:
	refresh()
	if level.state != Level.State.DRAWING:
		free_btn.visible = false
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
	box.add_child(UiKit.label(tr("Troque %d moedas por 1 dica.\nVocê tem %d moedas.") % [Game.HINT_PRICE, Game.coins()], 26, Palette.UI_TEXT, 0, Palette.WHITE, true))
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


# ------------------------------------------------------------------ inseto novo
func _open_intro(kinds: Array) -> void:
	if kinds.is_empty() or level.state != Level.State.DRAWING:
		return
	var kind: String = kinds[0]
	var box := _open_overlay()
	var info: Dictionary = Cast.INSECTS.get(kind, {})
	box.add_child(UiKit.label("Novo inseto!", 26, Palette.DANGER))
	box.add_child(UiKit.label(tr(str(info.get("name", kind))), 40))
	var demo := InsectIntro.new()
	demo.kind = kind
	box.add_child(demo)
	var desc := UiKit.label(tr(str(info.get("desc", ""))), 22, Palette.UI_TEXT, 0, Palette.WHITE, true)
	desc.custom_minimum_size = Vector2(480, 0)
	box.add_child(desc)
	box.add_child(UiKit.label("Veja o poder dele num abrigo de verdade. Quer treinar antes?", 19, Color(Palette.UI_TEXT, 0.7), 0, Palette.WHITE, true))
	var row := UiKit.hbox(14)
	box.add_child(row)
	var train := UiKit.button("Treinar", Palette.UI_SECONDARY, "pencil", 230, 88)
	train.pressed.connect(func():
		Tutorials.mark_seen(kinds)
		_close_overlay()
		action.emit("practice:" + kind))
	row.add_child(train)
	var go_btn := UiKit.button("Jogar", Palette.UI_GOOD, "play", 230, 88)
	go_btn.pressed.connect(func():
		Tutorials.mark_seen([kind])
		_close_overlay()
		level._draw_clock = 0.0
		if kinds.size() > 1:
			_open_intro(kinds.slice(1)))
	row.add_child(go_btn)


# ------------------------------------------------------------------ pausa
func _open_pause() -> void:
	if overlay != null or level.state == Level.State.WON or level.state == Level.State.LOST:
		return
	level.set_simulation_speed(1)
	var box := _open_overlay()
	# pausa DEPOIS de abrir o painel (_open_overlay fecha o anterior e despausa)
	get_tree().paused = true
	Sfx.stop_all_loops()
	var head := UiKit.vbox(2)
	head.add_child(UiKit.label("Pausa", 46))
	var lname := str(level.data.get("name", ""))
	if lname != "":
		head.add_child(UiKit.label(lname, 22, Color(Palette.UI_TEXT, 0.7)))
	box.add_child(head)
	box.add_child(PauseScene.new().setup(level))
	var tip := str(level.data.get("tip", ""))
	if tip != "":
		var tl := UiKit.label(tip, 20, Palette.UI_TEXT, 0, Palette.WHITE, true)
		tl.custom_minimum_size = Vector2(480, 0)
		box.add_child(tl)
	# três ações grandes e redondas, com desenho e nome embaixo
	var row := UiKit.hbox(26)
	box.add_child(row)
	var rs := _round_action("Recomeçar", "restart", Palette.UI_SECONDARY, 112)
	rs.pressed.connect(func():
		_close_overlay()
		action.emit("restart"))
	row.add_child(rs)
	var cont := _round_action("Continuar", "play", Palette.UI_GOOD, 140)
	cont.pressed.connect(_close_overlay)
	row.add_child(cont)
	var mp := _round_action("Mapa", "house", Palette.UI_PRIMARY, 112)
	mp.pressed.connect(func():
		_close_overlay()
		action.emit("menu"))
	row.add_child(mp)
	# música e sons: interruptores desenhados (nota musical / alto-falante, riscados quando desligados)
	var toggles := UiKit.hbox(18)
	box.add_child(toggles)
	for key in ["music", "sfx"]:
		toggles.add_child(_sound_toggle(key))


## Botão redondo com ícone desenhado e o nome logo abaixo (o nome é filho do botão).
func _round_action(text: String, icon: String, color: Color, d: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(d, d + 34)
	b.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled"]:
		var st := StyleBoxEmpty.new()
		b.add_theme_stylebox_override(state, st)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var disc := RoundFace.new()
	disc.color = color
	disc.icon = icon
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.position = Vector2.ZERO
	disc.size = Vector2(d, d)
	b.add_child(disc)
	b.button_down.connect(func(): disc.pressed = true)
	b.button_up.connect(func(): disc.pressed = false)
	var l := UiKit.label(text, 20, Palette.UI_TEXT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = Vector2(-20, d + 2)
	l.size = Vector2(d + 40, 30)
	b.add_child(l)
	b.pressed.connect(func(): Sfx.play("ui_click", -2.0, 1.0, 0.05))
	return b


func _sound_toggle(key: String) -> Button:
	var on: bool = float(Game.setting(key)) > 0.01
	var b := UiKit.button("", Palette.UI_GOOD if on else Palette.UI_MUTED, "", 210, 76)
	var ic := UiIcon.new()
	ic.icon = ("music" if key == "music" else "sound") + ("" if on else "_off")
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.position = Vector2(14, 12)
	ic.size = Vector2(48, 48)
	b.add_child(ic)
	var l := UiKit.label("Música" if key == "music" else "Sons", 22)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = Vector2(66, 12)
	l.size = Vector2(130, 46)
	b.add_child(l)
	b.pressed.connect(func():
		var now_on: bool = float(Game.setting(key)) > 0.01
		Game.set_setting(key, 0.0 if now_on else (0.6 if key == "music" else 0.9))
		var col := Palette.UI_MUTED if now_on else Palette.UI_GOOD
		b.add_theme_stylebox_override("normal", UiKit.btn_style(col, false))
		b.add_theme_stylebox_override("hover", UiKit.btn_style(col.lightened(0.06), false))
		ic.icon = ("music" if key == "music" else "sound") + ("_off" if now_on else "")
		ic.queue_redraw()
		var tw := ic.create_tween()
		ic.pivot_offset = ic.size * 0.5
		tw.tween_property(ic, "scale", Vector2(1.25, 1.25), 0.08)
		tw.tween_property(ic, "scale", Vector2.ONE, 0.12))
	return b


class RoundFace:
	extends Control
	## Círculo "gordinho" com sombra embaixo e o ícone no meio (afunda quando apertado).
	var color := Palette.UI_GOOD
	var icon := "play"
	var pressed := false:
		set(v):
			pressed = v
			queue_redraw()
	var _ic: UiIcon

	func _ready() -> void:
		_ic = UiIcon.new()
		_ic.icon = icon
		_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_ic)
		resized.connect(_fit)
		_fit()

	func _fit() -> void:
		if _ic == null:
			return
		var drop := 4.0 if pressed else 0.0
		_ic.position = size * 0.24 + Vector2(0, drop)
		_ic.size = size * 0.52

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.5
		var c := Vector2(r, r)
		var drop := 6.0 if pressed else 0.0
		draw_circle(c + Vector2(0, 8), r - 2.0, Palette.OUTLINE, true, -1.0, true)
		DrawUtil.disc(self, c + Vector2(0, drop), r - 4.0, color, Palette.OUTLINE, 5.0)
		draw_arc(c + Vector2(-r * 0.15, -r * 0.2 + drop), r * 0.55, PI * 1.1, PI * 1.5, 12, Color(1, 1, 1, 0.45), 6.0, true)
		_fit()


func on_back_pressed() -> void:
	if is_instance_valid(review):
		review.close()
		return
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
	if is_instance_valid(review):
		review._restore()
		review.queue_free()
		review = null
	if overlay != null:
		overlay.queue_free()
		overlay = null
	if get_tree() != null:
		get_tree().paused = false


# ------------------------------------------------------------------ resultado
const LOSE_TEXT := {
	"time": ["O tempo acabou!", "Desenhe uma rampa de Tinta Firme que leve o bichinho até a toca."],
	"coconut": ["Bonk!", "O coco cai onde a linha pontilhada mostra. Proteja por cima ou desvie!"],
	"snow": ["Bonk de neve!", "A Coruja avisa com X no chão onde a neve vai cair. Telhado inclinado faz a neve escorregar!"],
	"puff": ["Bonk de fumaça!", "O Besouro Pum-Pum mostra o arco pontilhado antes de lançar. Só um telhado segura!"],
	"shell": ["Bonk de concha!", "O Caranguejo Rei mostra o arco pontilhado antes de jogar. Faça uma parede do lado dele!"],
	"hug": ["Abraço apertado!", "O Polvo Gigante suga tudo! Prenda o abrigo embaixo das pedras para ele não subir."],
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
	if info.get("practice", false):
		box.add_child(UiKit.title("Treino feito!", 56))
		box.add_child(UiKit.label("Agora é para valer: a fase está esperando.", 24, Palette.UI_TEXT, 0, Palette.WHITE, true))
		var prow := UiKit.hbox(16)
		box.add_child(prow)
		var pagain := UiKit.button("Treinar de novo", Palette.UI_SECONDARY, "restart", 260, 90)
		pagain.pressed.connect(func(): action.emit("restart"))
		prow.add_child(pagain)
		var pgo := UiKit.button("Jogar a fase", Palette.UI_GOOD, "play", 260, 90)
		pgo.pressed.connect(func(): action.emit("menu"))
		prow.add_child(pgo)
		return
	if info.get("infinite", false):
		_build_infinite_win(box)
		return
	if info.get("daily", false):
		_build_daily_win(box, info)
		return
	if info.get("custom", false):
		box.add_child(UiKit.title("Salvos!", 60))
		box.add_child(UiKit.label("Sua fase funciona! Agora desafie alguém a resolver.", 26, Palette.UI_TEXT, 0, Palette.WHITE, true))
		var crow := UiKit.hbox(16)
		box.add_child(crow)
		var cback := UiKit.button("Editor", Palette.UI_PRIMARY, "pencil", 220, 96)
		cback.pressed.connect(func(): action.emit("menu"))
		crow.add_child(cback)
		var cagain := UiKit.button("De novo", Palette.UI_SECONDARY, "restart", 220, 96)
		cagain.pressed.connect(func(): action.emit("restart"))
		crow.add_child(cagain)
		return
	if info.get("free", false):
		box.add_child(UiKit.title("Modo Livre!", 60))
		box.add_child(UiKit.label("Sem limites, só diversão! Estrelas e moedas valem no modo normal.", 24, Palette.UI_TEXT, 0, Palette.WHITE, true))
		var got_free: Array = info.get("achievements", [])
		for a in got_free:
			box.add_child(UiKit.label(tr("Conquista: %s") % tr(Game.achievement_info(a)["name"]), 26, Palette.UI_GOOD))
		var frow := UiKit.hbox(16)
		box.add_child(frow)
		var fhome := UiKit.icon_button("home", Palette.UI_PANEL, 96)
		fhome.pressed.connect(func(): action.emit("menu"))
		frow.add_child(fhome)
		var fagain := UiKit.button("De novo", Palette.UI_SECONDARY, "restart", 220, 96)
		fagain.pressed.connect(func(): action.emit("restart"))
		frow.add_child(fagain)
		var fnormal := UiKit.button("Normal", Palette.UI_GOOD, "star", 200, 96)
		fnormal.pressed.connect(func():
			Game.free_mode = false
			action.emit("restart"))
		frow.add_child(fnormal)
		return
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
	box.add_child(UiKit.label(tr("Tinta usada: %d%%") % used, 26))
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
			box.add_child(UiKit.label(tr("Novo amigo: %s!") % Animal.SPECIES[f]["name"], 28, Palette.UI_PRIMARY))
	_add_medals(box, info)
	if level.mode == "campaign" and not level.free_mode:
		_add_missions(box, info)
		var treats: Dictionary = info.get("treats", {})
		if not treats.is_empty():
			var tl := UiKit.hbox(6)
			for k in treats:
				var dot := TreatIcon.new()
				dot.kind = k
				dot.custom_minimum_size = Vector2(36, 36)
				tl.add_child(dot)
			var n := 0
			for k in treats:
				n += int(treats[k])
			tl.add_child(UiKit.label(tr("+%d petiscos para a Casinha!") % n, 22, Palette.UI_TEXT))
			box.add_child(tl)
		var done := Game.completed_count()
		var prog := UiKit.label(tr("Fases vencidas: %d de %d") % [done, LevelDB.count()], 24, Palette.UI_PRIMARY.darkened(0.25))
		box.add_child(prog)
		if info.get("prev_stars", 0) == 0 and done % 10 == 0 and done > 0:
			var milestone := UiKit.label(tr("Marco: %d fases vencidas!") % done, 30, Palette.GOLD.darkened(0.25), 8, Palette.WHITE)
			box.add_child(milestone)
			UiKit.pop_in(milestone, 1.4)
			get_tree().create_timer(1.4).timeout.connect(func(): Sfx.play("unlock"))
	var got: Array = info.get("achievements", [])
	for k in mini(got.size(), 2):
		box.add_child(UiKit.label(tr("Conquista: %s") % tr(Game.achievement_info(got[k])["name"]), 26, Palette.UI_GOOD))
	if got.size() > 2:
		box.add_child(UiKit.label(tr("+%d conquistas! Veja em Bichinhos.") % (got.size() - 2), 24, Palette.UI_GOOD))
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
	var cam := UiKit.icon_button("camera", Palette.UI_PANEL, 96)
	cam.pressed.connect(func(): _take_photo(cam))
	row.add_child(cam)
	var has_next := level.index + 1 < LevelDB.count()
	var nxt := UiKit.button("Próxima" if has_next else "Mapa", Palette.UI_GOOD, "next", 240, 96)
	nxt.pressed.connect(func(): action.emit("next" if has_next else "menu"))
	row.add_child(nxt)


## Missões extras da fase: as cumpridas agora pulam na tela (+10 moedas cada).
func _add_missions(box: VBoxContainer, info: Dictionary) -> void:
	var id := str(level.data.get("id", ""))
	var fresh: Array = info.get("missions_new", [])
	var have := Missions.done(id)
	var panel := PanelContainer.new()
	var st := UiKit.panel_style(Palette.CREAM, 20)
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	st.content_margin_left = 14
	st.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", st)
	box.add_child(panel)
	var col := UiKit.vbox(4)
	panel.add_child(col)
	col.add_child(UiKit.label(tr("Missões %d/3") % have.size(), 22, Palette.UI_TEXT))
	var i := 0
	for m in Missions.for_level(id):
		var row := UiKit.hbox(8)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		var ic := UiIcon.new()
		ic.icon = "check" if have.has(m["kind"]) else "star_empty"
		ic.custom_minimum_size = Vector2(30, 30)
		row.add_child(ic)
		var l := UiKit.label(str(m["text"]) + ("  +%d" % Missions.REWARD if fresh.has(m["kind"]) else ""), 19,
			Palette.UI_GOOD.darkened(0.2) if have.has(m["kind"]) else Color(Palette.UI_TEXT, 0.7))
		row.add_child(l)
		col.add_child(row)
		if fresh.has(m["kind"]):
			UiKit.pop_in(row, 1.2 + i * 0.25)
			get_tree().create_timer(1.2 + i * 0.25).timeout.connect(func(): Sfx.play("coin", -2.0, 1.2))
		i += 1


## Três medalhas extras: pegada dourada, de primeira e relâmpago (as novas pulam na tela).
func _add_medals(box: VBoxContainer, info: Dictionary) -> void:
	var id := str(level.data.get("id", ""))
	var fresh: Array = info.get("new_medals", [])
	var row := UiKit.hbox(14)
	box.add_child(row)
	for i in Game.MEDALS.size():
		var m: String = Game.MEDALS[i]
		var got := Game.has_medal(id, m)
		var cell := UiKit.vbox(0)
		var ic := UiIcon.new()
		ic.icon = Game.MEDAL_INFO[m]["icon"]
		ic.custom_minimum_size = Vector2(60, 60)
		ic.modulate = Color.WHITE if got else Color(1, 1, 1, 0.28)
		cell.add_child(ic)
		cell.add_child(UiKit.label(Game.MEDAL_INFO[m]["name"], 18, Palette.UI_TEXT if got else Palette.UI_MUTED))
		row.add_child(cell)
		if fresh.has(m):
			UiKit.pop_in(ic, 1.0 + i * 0.2)
			get_tree().create_timer(1.0 + i * 0.2).timeout.connect(func(): Sfx.play("pop", 0.0, 1.2 + i * 0.1))


## Foto da vitória: esconde o painel por um instante, captura a tela e guarda no Álbum.
func _take_photo(btn: Button) -> void:
	btn.disabled = true
	overlay.visible = false
	for c in root.get_children():
		if c != overlay:
			c.visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	for c in root.get_children():
		c.visible = true
	refresh()
	if level.state != Level.State.DRAWING:
		free_btn.visible = false
		hint_btn.visible = false
		play_btn.visible = false
	overlay.visible = true
	var cap := (tr("Fase %d · %s") % [level.index + 1, tr(str(level.data.get("name", "")))]) if level.mode == "campaign" else str(level.data.get("name", ""))
	Game.add_photo(img, cap)
	Sfx.play("ui_click", 2.0, 0.6)
	var flash := ColorRect.new()
	flash.color = Color.WHITE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.35)
	tw.tween_callback(flash.queue_free)
	var note := UiKit.label("Foto salva no Álbum da Casinha!", 26, Palette.WHITE, 10, Palette.OUTLINE)
	note.anchor_right = 1.0
	note.offset_top = 1120
	note.offset_bottom = 1170
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(note)
	get_tree().create_timer(2.0).timeout.connect(note.queue_free)


func _build_daily_win(box: VBoxContainer, info: Dictionary) -> void:
	box.add_child(UiKit.title("Desafio vencido!", 54))
	var mod := Daily.mod_info(str(level.data.get("daily_mod", "")))
	box.add_child(UiKit.label(tr("%s · fase %s") % [tr(mod["name"]), level.data.get("base_id", "")], 24))
	var flame := UiKit.hbox(8)
	var fi := UiIcon.new()
	fi.icon = "flame"
	fi.custom_minimum_size = Vector2(56, 56)
	flame.add_child(fi)
	var streak := int(info.get("streak", 1))
	flame.add_child(UiKit.label((tr("%d dia seguido!") if streak == 1 else tr("%d dias seguidos!")) % streak, 30, Palette.UI_PRIMARY))
	box.add_child(flame)
	UiKit.pop_in(fi, 0.3)
	if info.get("repeat", false):
		box.add_child(UiKit.label("O prêmio de hoje já foi pego. Volte amanhã para um desafio novo!", 24, Palette.UI_TEXT, 0, Palette.WHITE, true))
	else:
		var coin_row := UiKit.hbox(8)
		var ci := UiIcon.new()
		ci.icon = "coin"
		ci.custom_minimum_size = Vector2(44, 44)
		coin_row.add_child(ci)
		coin_row.add_child(UiKit.label("+%d   (total %d)" % [int(info.get("coins", 0)), Game.coins()], 30))
		box.add_child(coin_row)
		get_tree().create_timer(0.8).timeout.connect(func(): Sfx.play("coin"))
	for a in info.get("achievements", []):
		box.add_child(UiKit.label(tr("Conquista: %s") % tr(Game.achievement_info(a)["name"]), 26, Palette.UI_GOOD))
	var row := UiKit.hbox(16)
	box.add_child(row)
	var home := UiKit.button("Voltar", Palette.UI_PRIMARY, "calendar", 220, 96)
	home.pressed.connect(func(): action.emit("menu"))
	row.add_child(home)
	var again := UiKit.icon_button("restart", Palette.UI_SECONDARY, 96)
	again.pressed.connect(func(): action.emit("restart"))
	row.add_child(again)


func _build_infinite_win(box: VBoxContainer) -> void:
	var res := Infinite.cleared()
	box.add_child(UiKit.title(tr("Fase %d vencida!") % int(res["stage"]), 52))
	var seq := UiKit.label(tr("Sequência: %d") % int(res["stage"]), 40, Palette.UI_PRIMARY.darkened(0.2))
	box.add_child(seq)
	UiKit.pop_in(seq, 0.2)
	if res["record"]:
		var rl := UiKit.label("NOVO RECORDE!", 36, Palette.GOLD.darkened(0.2), 8, Palette.WHITE)
		box.add_child(rl)
		UiKit.pop_in(rl, 0.6)
		get_tree().create_timer(0.6).timeout.connect(func(): Sfx.play("unlock"))
	var coin_row := UiKit.hbox(8)
	var ci := UiIcon.new()
	ci.icon = "coin"
	ci.custom_minimum_size = Vector2(44, 44)
	coin_row.add_child(ci)
	coin_row.add_child(UiKit.label("+%d" % int(res["coins"]), 30))
	box.add_child(coin_row)
	if res["chest"]:
		var cl := UiKit.label("Baú de 5 fases: +40 moedas e petiscos!", 24, Palette.UI_GOOD.darkened(0.2))
		box.add_child(cl)
		UiKit.pop_in(cl, 1.0)
	var next := int(Infinite.run["stage"])
	box.add_child(UiKit.label(tr("Próxima: Fase %d (mais difícil!)") % next, 22, Color(Palette.UI_TEXT, 0.7)))
	var row := UiKit.hbox(16)
	box.add_child(row)
	var home := UiKit.icon_button("home", Palette.UI_PANEL, 96)
	home.pressed.connect(func(): action.emit("menu"))
	row.add_child(home)
	var nxt := UiKit.button("Próxima", Palette.UI_GOOD, "next", 280, 96)
	nxt.pressed.connect(func(): action.emit("next"))
	row.add_child(nxt)


func _build_infinite_lose(box: VBoxContainer, info: Dictionary) -> void:
	var hearts := Infinite.failed()
	var reason := str(info.get("reason", "sting"))
	var txt: Array = LOSE_TEXT.get(reason, LOSE_TEXT["sting"])
	box.add_child(UiKit.title(txt[0], 48))
	var hr := UiKit.hbox(6)
	for i in Infinite.HEARTS:
		var h := UiIcon.new()
		h.icon = "heart"
		h.custom_minimum_size = Vector2(56, 56)
		h.modulate = Color.WHITE if i < hearts else Color(0.2, 0.2, 0.2, 0.3)
		hr.add_child(h)
	box.add_child(hr)
	var row := UiKit.hbox(16)
	if hearts > 0:
		box.add_child(UiKit.label(tr("Ainda restam %d corações. Tente de novo!") % hearts, 24, Palette.UI_TEXT, 0, Palette.WHITE, true))
		box.add_child(row)
		var home := UiKit.icon_button("home", Palette.UI_PANEL, 96)
		home.pressed.connect(func(): action.emit("menu"))
		row.add_child(home)
		var again := UiKit.button("De novo!", Palette.UI_GOOD, "restart", 260, 96)
		again.pressed.connect(func(): action.emit("restart"))
		row.add_child(again)
		return
	var reached := int(Infinite.run.get("stage", 1)) - 1
	box.add_child(UiKit.label(tr("Fim da corrida! Você passou %d fases seguidas.") % reached, 28, Palette.UI_TEXT, 0, Palette.WHITE, true))
	box.add_child(UiKit.label(tr("Recorde: %d") % Infinite.best(), 32, Palette.GOLD.darkened(0.25)))
	box.add_child(row)
	var menu := UiKit.button("Menu", Palette.UI_SECONDARY, "home", 220, 96)
	menu.pressed.connect(func(): action.emit("menu"))
	row.add_child(menu)
	var fresh := UiKit.button("Nova corrida", Palette.UI_GOOD, "play", 280, 96)
	fresh.pressed.connect(func(): action.emit("infinite_new"))
	row.add_child(fresh)


func _build_lose(box: VBoxContainer, info: Dictionary) -> void:
	if level.mode == "infinite":
		_build_infinite_lose(box, info)
		return
	if level.mode == "practice":
		box.add_child(UiKit.title("Quase!", 52))
		box.add_child(UiKit.label(tr(str(level.data.get("tip", ""))), 22, Palette.UI_TEXT, 0, Palette.WHITE, true))
		var prow := UiKit.hbox(16)
		box.add_child(prow)
		var pgo := UiKit.button("Ir para a fase", Palette.UI_SECONDARY, "next", 260, 90)
		pgo.pressed.connect(func(): action.emit("menu"))
		prow.add_child(pgo)
		var pagain := UiKit.button("Treinar de novo", Palette.UI_GOOD, "restart", 260, 90)
		pagain.pressed.connect(func(): action.emit("restart"))
		prow.add_child(pagain)
		return
	var reason := str(info.get("reason", "sting"))
	var txt: Array = LOSE_TEXT.get(reason, LOSE_TEXT["sting"])
	box.add_child(UiKit.title(txt[0], 52))
	box.add_child(UiKit.label(str(info.get("analysis", txt[1])), 26, Palette.UI_TEXT, 0, Palette.WHITE, true))
	if level.replay != null and level.replay.duration() > 0.01:
		review_btn = UiKit.button("Ver onde falhou", Palette.UI_SECONDARY, "", 0, 76)
		review_btn.pressed.connect(_open_review)
		box.add_child(review_btn)
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


func _open_review() -> void:
	if is_instance_valid(review) or level.replay == null or level.state != Level.State.LOST or level.replay.duration() <= 0.01: return
	review = AttemptReview.new()
	review.model = level.replay
	review.info = level.last_result
	review.z_index = 30
	if overlay != null: overlay.visible = false
	review.closed.connect(func():
		review.queue_free()
		review = null
		if overlay != null: overlay.visible = true
		if is_instance_valid(review_btn): review_btn.grab_focus())
	review.retry.connect(func():
		review.queue_free()
		review = null
		action.emit("restart"))
	root.add_child(review)


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
		if level.free_mode:
			var rainbow := StyleBoxFlat.new()
			rainbow.bg_color = Color.from_hsv(fmod(Time.get_ticks_msec() / 4000.0, 1.0), 0.45, 1.0)
			rainbow.set_corner_radius_all(int(r.size.y * 0.5) - 4)
			draw_style_box(rainbow, Rect2(r.position + Vector2(5, 5), r.size - Vector2(10, 10)))
			var c := r.get_center()
			draw_arc(c + Vector2(-11, 0), 10.0, 0.0, TAU, 20, o, 4.0, true)
			draw_arc(c + Vector2(11, 0), 10.0, 0.0, TAU, 20, o, 4.0, true)
			queue_redraw()
			return
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


## Desenhinho do petisco (biscoito, morango, picolé, bolinho).
class TreatIcon:
	extends Control
	var kind := "biscoito"
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.42
		var o := Palette.OUTLINE
		var col := Color(str(Treats.KINDS.get(kind, {}).get("color", "e0a860")))
		match kind:
			"morango":
				DrawUtil.shape(self, PackedVector2Array([c + Vector2(-r, -r * 0.3), c + Vector2(r, -r * 0.3), c + Vector2(0, r)]), col, o, 2.0)
				DrawUtil.tri(self, c + Vector2(-r * 0.5, -r * 0.3), c + Vector2(0, -r * 0.8), c + Vector2(r * 0.5, -r * 0.3), Color("5cc46a"), o, 2.0)
			"picole":
				draw_rect(Rect2(c + Vector2(-r * 0.15, r * 0.3), Vector2(r * 0.3, r * 0.7)), Color("e0a860"), true)
				DrawUtil.oval(self, c + Vector2(0, -r * 0.2), Vector2(r * 0.6, r * 0.75), col, o, 2.0)
			"bolinho":
				DrawUtil.oval(self, c + Vector2(0, r * 0.2), Vector2(r, r * 0.6), Color("c98a4a"), o, 2.0)
				DrawUtil.oval(self, c + Vector2(0, -r * 0.1), Vector2(r * 0.85, r * 0.45), col, o, 2.0)
			_:
				DrawUtil.disc(self, c, r, col, o, 2.0)
				for p in [Vector2(-0.35, -0.2), Vector2(0.3, -0.25), Vector2(0, 0.3)]:
					draw_circle(c + p * r, r * 0.15, Color("8a5a39"), true, -1.0, true)
