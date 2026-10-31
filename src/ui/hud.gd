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
	var title_text := "%s  %s" % [level.data.get("id", ""), tr(str(level.data.get("name", "")))] if level.mode == "campaign" else str(level.data.get("name", ""))
	title_label = UiKit.label(title_text, 26, Palette.WHITE, 10, Palette.OUTLINE)
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


# ------------------------------------------------------------------ pausa
func _open_pause() -> void:
	if overlay != null or level.state == Level.State.WON or level.state == Level.State.LOST:
		return
	level.set_simulation_speed(1)
	var box := _open_overlay()
	# pausa DEPOIS de abrir o painel (_open_overlay fecha o anterior e despausa)
	get_tree().paused = true
	Sfx.stop_all_loops()
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
		var names := {true: tr("Música: sim") if key == "music" else tr("Sons: sim"), false: tr("Música: não") if key == "music" else tr("Sons: não")}
		var b := UiKit.button(names[on], Palette.UI_PANEL, "", 200, 76)
		b.pressed.connect(func():
			var now_on: bool = float(Game.setting(key)) > 0.01
			Game.set_setting(key, 0.0 if now_on else (0.6 if key == "music" else 0.9))
			b.text = names[not now_on])
		toggles.add_child(b)


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
	var cap := "%s %s" % [level.data.get("id", ""), tr(str(level.data.get("name", "")))] if level.mode == "campaign" else str(level.data.get("name", ""))
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


func _build_lose(box: VBoxContainer, info: Dictionary) -> void:
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
