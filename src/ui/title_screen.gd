class_name TitleScreen
extends Control
## Tela inicial limpa: logo, a turma protegida por um escudo de tinta (abelhas batem e
## quicam nele), um botão grande de Jogar e quatro atalhos. Embaixo, na trilha de grama,
## bichinhos passam andando — às vezes correndo de uma abelha curiosa.
## Toque em qualquer bichinho para ele dar um pulinho.

signal go(screen: String, arg: Variant)

const STAGE_COUNT := 5
const JUMP_TIME := 0.45
const JUMP_HEIGHT := 70.0
## Bichinhos andando na trilha ao mesmo tempo.
const MAX_WALKERS := 3

var _stage_art: Array[AnimalArt] = []
var _stage_jump: Array[float] = []
var _happy_until: Array[float] = []
var _bees: Array[InsectArt] = []
var _walkers: Array[Dictionary] = []
var _spawn_timer := 0.8
var _walk_serial := 0
var _t := 0.0
var _reduce := false

var _shield: TitleShield
var _logo: Label
var _menu: VBoxContainer
var _settings_btn: Button
var _store_btn: Button
var _safe := Rect2()
## Aviso de Termos e Privacidade (primeira abertura ou termos atualizados).
var consent: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reduce = bool(Game.setting("reduce_motion"))
	add_child(MenuBg.new())
	_shield = TitleShield.new()
	add_child(_shield)
	for sp in _stage_species():
		var a := AnimalArt.new()
		a.species = sp
		a.preview = true
		a.accessory = Game.equipped(sp)
		add_child(a)
		_stage_art.append(a)
		_stage_jump.append(0.0)
		_happy_until.append(0.0)
	for i in 2:
		var bee := InsectArt.new()
		bee.kind = "bee" if i == 0 else "wasp"
		bee.radius = 15.0 if i == 0 else 14.0
		add_child(bee)
		_bees.append(bee)

	_logo = UiKit.title("GuardiPatas", 84)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)
	UiKit.pop_in(_logo, 0.05)

	_settings_btn = UiKit.icon_button("gear", Palette.UI_PANEL, 76)
	_settings_btn.pressed.connect(func(): go.emit("settings", null))
	add_child(_settings_btn)
	# moedas = entrada da Loja (padrão dos jogos de celular)
	_store_btn = UiKit.button(str(Game.coins()), Palette.GOLD, "coin", 170, 76)
	_store_btn.add_theme_font_size_override("font_size", UiKit.fs(28))
	_store_btn.pressed.connect(func(): go.emit("store", null))
	add_child(_store_btn)
	UiKit.badge(_store_btn, "+")

	_menu = UiKit.vbox(16)
	add_child(_menu)
	# quantas já foram e qual é a próxima (a campanha é numerada sem parar)
	var done := Game.completed_count()
	var next_n := Game.next_level_index() + 1
	var prog := UiKit.label(tr("Próxima: Fase %d  ·  %d de %d vencidas") % [next_n, done, LevelDB.count()], 22, Palette.WHITE, 8, Palette.OUTLINE)
	_menu.add_child(prog)
	var play := UiKit.button("Jogar", Palette.UI_GOOD, "play", 420, 112)
	play.add_theme_font_size_override("font_size", UiKit.fs(44))
	play.pressed.connect(func(): go.emit("map", -1))
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu.add_child(play)
	UiKit.pop_in(play, 0.2)
	var inf := InfiniteCard.new()
	inf.best = Infinite.best()
	inf.running = Infinite.active()
	inf.reduce = _reduce
	inf.custom_minimum_size = Vector2(420, 92)
	inf.tooltip_text = tr("Modo Infinito")
	inf.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inf.pressed.connect(func(): go.emit("infinite", null))
	_menu.add_child(inf)
	UiKit.pop_in(inf, 0.25)
	var row := UiKit.hbox(12)
	_menu.add_child(row)
	var tiles := [
		["Desafio", "calendar", Color("ffb340"), "daily"],
		["Bichinhos", "paw", Palette.UI_PRIMARY, "collection"],
		["Casinha", "house", Color("8fd3a0"), "home"],
		["Criar", "pencil", Color("b18cff"), "editor"],
		["Pintar", "palette", Color("ff9ec4"), "paint"],
	]
	for i in tiles.size():
		var spec: Array = tiles[i]
		var b := UiKit.tile(spec[0], spec[1], spec[2], 124, 118)
		var dest: String = spec[3]
		b.pressed.connect(func(): go.emit(dest, null))
		row.add_child(b)
		UiKit.pop_in(b, 0.3 + i * 0.06)
		if dest == "daily" and not Game.daily_done_today(Daily.today_key()):
			UiKit.badge(b)

	resized.connect(_layout)
	_layout()
	Sfx.music("music_menu")
	if not Legal.accepted():
		_show_consent()


## "Ao usar, você concorda": cartão na primeira abertura (e quando os termos mudam).
## Bloqueia o menu até tocar em "Concordar e continuar"; os documentos abrem completos.
func _show_consent() -> void:
	consent = Control.new()
	consent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(consent)
	consent.add_child(UiKit.dim(0.5))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	consent.add_child(center)
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color("fffaf3")
	st.set_corner_radius_all(32)
	st.border_color = Color("e5d9d6")
	st.set_border_width_all(2)
	st.content_margin_left = 30
	st.content_margin_right = 30
	st.content_margin_top = 26
	st.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size.x = minf(size.x - 48, 600) if size.x > 0 else 600
	center.add_child(panel)
	var col := UiKit.vbox(14)
	panel.add_child(col)
	var pet := AnimalArt.new()
	pet.species = "capi"
	pet.preview = true
	pet.mood = "happy"
	pet.scale = Vector2.ONE * 0.9
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 96)
	holder.add_child(pet)
	holder.resized.connect(func(): pet.position = Vector2(holder.size.x / 2, 70))
	col.add_child(holder)
	var ink := Color("5c5669")
	var head := UiKit.label("Atualizamos os termos" if Legal.is_update() else "Boas-vindas ao GuardiPatas!", 32, ink, 0, Color.WHITE, true)
	col.add_child(head)
	var lines := [
		"O GuardiPatas não coleta dados pessoais, não tem anúncios e não compartilha nada. Seu progresso fica salvo só neste aparelho.",
		"Ao continuar e usar o jogo, você concorda com os Termos de Uso e a Política de Privacidade da RetroNexa.",
		"Se você tem menos de 18 anos, leia com um adulto responsável.",
	]
	for i in lines.size():
		var l := UiKit.label(lines[i], 21 if i < 2 else 19, ink if i < 2 else Color("847e8d"), 0, Color.WHITE, true)
		col.add_child(l)
	var row := UiKit.hbox(10)
	col.add_child(row)
	for spec in [["Termos de Uso", "terms"], ["Privacidade", "privacy"]]:
		var doc: String = spec[1]
		var b := UiKit.button(tr(spec[0]), Color("e8e0ef"), "", 0, 64)
		b.add_theme_font_size_override("font_size", UiKit.fs(22))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): go.emit("legal", {"doc": doc, "back": "title"}))
		row.add_child(b)
	var ok := UiKit.button(tr("Concordar e continuar"), Palette.UI_GOOD, "", 0, 80)
	ok.add_theme_font_size_override("font_size", UiKit.fs(28))
	ok.pressed.connect(_accept_consent)
	col.add_child(ok)
	UiKit.pop_in(panel, 0.1)
	ok.grab_focus.call_deferred()


func _accept_consent() -> void:
	Legal.accept()
	Sfx.play("ui_click")
	if consent != null:
		consent.queue_free()
		consent = null


## Turma do palco: os já conhecidos primeiro (sorteados), completando com a turma inicial.
func _stage_species() -> Array:
	var met: Array = Game.data["met"].duplicate()
	met.shuffle()
	var out: Array = []
	for sp in met:
		if out.size() < STAGE_COUNT and Cast.ORDER.has(sp) and not out.has(sp):
			out.append(sp)
	for sp in Cast.ORDER:
		if out.size() < STAGE_COUNT and not out.has(sp):
			out.append(sp)
	return out


## Largura aproximada do desenho de cada espécie (a capivara é bem mais larga que o esquilo).
static func art_width(sp: String) -> float:
	var cfg: Dictionary = Animal.SPECIES.get(sp, {})
	match str(cfg.get("shape", "circle")):
		"hcapsule": return float(cfg.get("h", 80.0)) + 8.0
		"vcapsule": return float(cfg.get("r", 24.0)) * 2.0 + 22.0
	return float(cfg.get("r", 24.0)) * 2.0 + 24.0


func _layout() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	_safe = Rect2(Vector2.ZERO, size)
	if OS.has_feature("Android"):
		var area := DisplayServer.get_display_safe_area()
		var window_size := Vector2(get_window().size)
		if area.size.x > 0 and area.size.y > 0 and window_size.x > 0 and window_size.y > 0:
			var factor := size / window_size
			_safe = _safe.intersection(Rect2(Vector2(area.position) * factor, Vector2(area.size) * factor))
	var h := size.y
	_settings_btn.position = _safe.position + Vector2(18, 18)
	_store_btn.size = _store_btn.get_combined_minimum_size()
	_store_btn.position = Vector2(_safe.end.x - _store_btn.size.x - 30, _safe.position.y + 18)
	_logo.size = Vector2(size.x, 120)
	_logo.position = Vector2(0, _logo_y())
	_logo.pivot_offset = _logo.size * 0.5
	# distribui o palco (escudo + morrinho) e o menu no espaço entre o logo e a trilha
	_menu.size = _menu.get_combined_minimum_size()
	var logo_bottom := _logo_y() + 110.0
	var lane_top := h * 0.9 - 100.0
	var dome := _shield.radius().y + 90.0
	var free := maxf(0.0, lane_top - logo_bottom - dome - 60.0 - _menu.size.y)
	_shield.ground_y = logo_bottom + free * 0.4 + dome
	_shield.queue_redraw()
	_menu.position = Vector2((size.x - _menu.size.x) * 0.5, _shield.ground_y + 60.0 + free * 0.2)


func _logo_y() -> float:
	return _safe.position.y + maxf(96.0, size.y * 0.085)


func _process(delta: float) -> void:
	_t += delta
	var now := Time.get_ticks_msec() / 1000.0
	_update_stage(delta, now)
	_update_bees()
	_update_walkers(delta, now)
	if not _reduce:
		_logo.rotation = sin(_t * 1.3) * 0.02
		_logo.position.y = _logo_y() + sin(_t * 1.8) * 5.0


func _update_stage(delta: float, now: float) -> void:
	var w := size.x
	var ground := _shield.ground_y - 4.0
	var widths: Array[float] = []
	var total := 0.0
	var max_w := w * 0.74
	for a in _stage_art:
		widths.append(art_width(a.species))
		total += widths[-1]
	var sc := clampf(max_w / maxf(total + 14.0 * (_stage_art.size() - 1), 1.0), 0.7, 1.15)
	var gap := clampf((max_w - total * sc) / maxf(_stage_art.size() - 1, 1), 4.0, 26.0)
	var x := w * 0.5 - (total * sc + gap * (_stage_art.size() - 1)) * 0.5
	for i in _stage_art.size():
		var a := _stage_art[i]
		a.scale = Vector2(sc, sc)
		var jump := 0.0
		if _stage_jump[i] > 0.0:
			_stage_jump[i] = maxf(_stage_jump[i] - delta, 0.0)
			jump = sin((1.0 - _stage_jump[i] / JUMP_TIME) * PI) * JUMP_HEIGHT * (0.4 if _reduce else 1.0)
		a.position = Vector2(x + widths[i] * sc * 0.5, ground - Animal.half_height(a.species) * sc - jump)
		x += widths[i] * sc + gap
		var closest := _bees[0].position
		if _bees[1].position.distance_to(a.position) < closest.distance_to(a.position):
			closest = _bees[1].position
		a.mood = "happy" if _happy_until[i] > now else ("scared" if closest.distance_to(a.position) < 150.0 else "idle")
		a.look = (closest - a.position).normalized() * Vector2(a.facing, 1)


## Abelhas rondam o escudo e dão "toc" nele de vez em quando (o escudo segura!).
func _update_bees() -> void:
	var c := _shield.center()
	var r := _shield.radius()
	for i in _bees.size():
		var bee := _bees[i]
		var speed := 0.55 + i * 0.22
		var a := PI + PI * (0.5 + 0.36 * sin(_t * speed + i * 2.1))
		var dive := pow(maxf(0.0, sin(_t * (1.4 + i * 0.5) + i)), 10.0)
		var dist := 1.0 + (70.0 - dive * 52.0) / r.x
		var prev := bee.position
		bee.position = c + Vector2(cos(a) * r.x, sin(a) * r.y) * dist + Vector2(0, sin(_t * 9.0 + i) * 4.0)
		if absf(bee.position.x - prev.x) > 0.05:
			bee.facing = signf(bee.position.x - prev.x)
		if dive > 0.92 and bee.squash < 0.1:
			bee.squash = 1.0
			_shield.flash = 1.0
			if not _reduce:
				Sfx.play("bonk", -16.0, 1.2 + i * 0.2, 0.1)


func _update_walkers(delta: float, now: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _walkers.size() < MAX_WALKERS:
		_spawn_timer = 2.6 + fmod(_walk_serial * 1.37, 2.2)
		_spawn_walker()
	var lane := size.y * 0.9 - 12.0
	for wk in _walkers.duplicate():
		var art: AnimalArt = wk["art"]
		var dir: float = wk["dir"]
		var speed: float = wk["speed"]
		wk["x"] = float(wk["x"]) + dir * speed * delta
		wk["jump"] = maxf(float(wk["jump"]) - delta, 0.0)
		var step := _t * speed * 0.09 + float(wk["phase"])
		var hop := absf(sin(step)) * (3.0 if _reduce else 9.0)
		var jump := sin((1.0 - float(wk["jump"]) / JUMP_TIME) * PI) * JUMP_HEIGHT if float(wk["jump"]) > 0.0 else 0.0
		art.position = Vector2(float(wk["x"]), lane - Animal.half_height(art.species) * art.scale.y - hop - jump)
		art.rotation = 0.0 if _reduce else sin(step) * 0.05
		var chaser: InsectArt = wk.get("bee")
		if chaser != null:
			chaser.position = art.position + Vector2(-dir * (90.0 + sin(_t * 3.0) * 14.0), -60.0 + sin(_t * 7.0) * 10.0)
			chaser.facing = dir
		art.mood = "happy" if float(wk["happy"]) > now else ("scared" if chaser != null else "idle")
		if float(wk["x"]) < -160.0 or float(wk["x"]) > size.x + 160.0:
			art.queue_free()
			if chaser != null:
				chaser.queue_free()
			_walkers.erase(wk)


func _spawn_walker() -> void:
	_walk_serial += 1
	var pool: Array = Cast.ORDER.duplicate()
	for a in _stage_art:
		pool.erase(a.species)
	for wk in _walkers:
		pool.erase((wk["art"] as AnimalArt).species)
	if pool.is_empty():
		return
	var sp: String = pool[(_walk_serial * 7) % pool.size()]
	var dir := 1.0 if _walk_serial % 2 == 1 else -1.0
	var art := AnimalArt.new()
	art.species = sp
	art.preview = true
	art.accessory = Game.equipped(sp)
	art.facing = dir
	art.scale = Vector2(0.8, 0.8)
	add_child(art)
	move_child(art, _shield.get_index() + 1)
	var chased := _walk_serial % 3 == 0
	var wk := {"art": art, "dir": dir, "x": -120.0 if dir > 0 else size.x + 120.0,
		"speed": 150.0 if chased else 70.0 + (_walk_serial % 3) * 12.0,
		"phase": float(_walk_serial), "jump": 0.0, "happy": 0.0}
	if chased:
		var bee := InsectArt.new()
		bee.kind = "bee"
		bee.radius = 12.0
		add_child(bee)
		wk["bee"] = bee
	_walkers.append(wk)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var now := Time.get_ticks_msec() / 1000.0
	for i in _stage_art.size():
		if _stage_art[i].position.distance_to(mb.position) < 60.0:
			_stage_jump[i] = JUMP_TIME
			_happy_until[i] = now + 1.2
			Sfx.play("pop", -2.0, 0.9 + i * 0.08)
			accept_event()
			return
	for wk in _walkers:
		var art: AnimalArt = wk["art"]
		if art.position.distance_to(mb.position) < 60.0:
			wk["jump"] = JUMP_TIME
			wk["happy"] = now + 1.0
			Sfx.play("pop", -2.0, 1.25)
			accept_event()
			return


class TitleShield:
	extends Control
	## A linha azul de tinta "protegendo" a turma, sobre um morrinho de grama.
	var ground_y := 700.0
	var flash := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func center() -> Vector2:
		return Vector2(size.x * 0.5, ground_y - 6.0)

	func radius() -> Vector2:
		return Vector2(size.x * 0.43, minf(200.0, size.x * 0.3))

	func _process(delta: float) -> void:
		if flash > 0.0:
			flash = maxf(flash - delta * 3.0, 0.0)
			queue_redraw()

	func _draw() -> void:
		var c := center()
		var r := radius()
		# morrinho de grama embaixo da turma
		var hill := PackedVector2Array()
		for i in 21:
			var a := PI * float(i) / 20.0
			hill.append(Vector2(c.x + cos(a) * r.x * 1.12, ground_y + sin(a) * 46.0))
		DrawUtil.shape(self, hill, Color("8fcf84"), Palette.OUTLINE, 5.0)
		draw_line(Vector2(c.x - r.x * 1.1, ground_y), Vector2(c.x + r.x * 1.1, ground_y), Color("6fb86a"), 6.0, true)
		for i in 7:
			var fx := c.x - r.x + r.x * 2.0 * float(i) / 6.0
			DrawUtil.disc(self, Vector2(fx, ground_y + 14.0 + (i % 2) * 8.0), 5.0, Color("ff9ec7") if i % 2 == 0 else Palette.WHITE, Palette.OUTLINE, 2.0)
		# o escudo: arco de tinta com brilho (pisca quando uma abelha bate)
		var pts := PackedVector2Array()
		for i in 33:
			var a := PI + PI * float(i) / 32.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		var ink := Palette.INK.lerp(Palette.WHITE, flash * 0.5)
		draw_polyline(pts, Palette.OUTLINE, 24.0, true)
		draw_polyline(pts, ink, 16.0, true)
		var shine := PackedVector2Array()
		for i in range(6, 15):
			shine.append(pts[i] + Vector2(-2, -3))
		draw_polyline(shine, Palette.INK_HI, 4.0, true)


## Botão do Modo Infinito: cartão roxo com o símbolo ∞ desenhado, brilhinhos e o recorde.
class InfiniteCard:
	extends Button
	var best := 0
	var running := false
	var reduce := false
	var _t := 0.0
	var _title: Label
	var _sub: Label
	func _ready() -> void:
		text = ""
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())
		_title = UiKit.label("Modo Infinito", 30, Palette.WHITE, 8, Palette.OUTLINE)
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_title)
		var sub := tr("Continue sua corrida!") if running else (tr("Recorde: %d fases") % best if best > 0 else tr("Fases novas sem parar"))
		_sub = UiKit.label(sub, 19, Palette.WHITE, 6, Color("5b3fa8"))
		_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_sub)
		resized.connect(_place)
		_place()
	func _place() -> void:
		var left := 112.0
		_title.position = Vector2(left, size.y * 0.5 - 40)
		_title.size = Vector2(size.x - left - 16, 42)
		_sub.position = Vector2(left + 2, size.y * 0.5 + 2)
		_sub.size = Vector2(size.x - left - 16, 28)
	func _process(delta: float) -> void:
		if not reduce:
			_t += delta
			queue_redraw()
	func _draw() -> void:
		var down := 4.0 if is_pressed() else 0.0
		var r := Rect2(Vector2(0, down), size - Vector2(0, 8))
		# sombra/base grossa como os outros botões do jogo
		var base := StyleBoxFlat.new()
		base.bg_color = Palette.OUTLINE
		base.set_corner_radius_all(30)
		draw_style_box(base, Rect2(Vector2(0, 8), size - Vector2(0, 8)))
		var top := Color("9b6bff").lightened(0.06 if is_hovered() else 0.0)
		var bottom := Color("ff7ac8")
		var card := StyleBoxFlat.new()
		card.bg_color = top
		card.set_corner_radius_all(30)
		card.set_border_width_all(5)
		card.border_color = Palette.OUTLINE
		draw_style_box(card, r)
		# faixa de cor (degradê simples) por dentro da borda
		var inner := r.grow(-6)
		var steps := 12
		for i in steps:
			var k := float(i) / steps
			var col := top.lerp(bottom, k)
			var x := inner.position.x + inner.size.x * k
			var seg := StyleBoxFlat.new()
			seg.bg_color = col
			var rr := 24
			seg.corner_radius_top_left = rr if i == 0 else 0
			seg.corner_radius_bottom_left = rr if i == 0 else 0
			seg.corner_radius_top_right = rr if i == steps - 1 else 0
			seg.corner_radius_bottom_right = rr if i == steps - 1 else 0
			draw_style_box(seg, Rect2(x, inner.position.y, inner.size.x / steps + 1, inner.size.y))
		# brilho em cima
		draw_rect(Rect2(inner.position + Vector2(18, 4), Vector2(inner.size.x - 36, 6)), Color(1, 1, 1, 0.25))
		# símbolo ∞ com uma estrelinha correndo por ele
		var c := Vector2(58, r.get_center().y)
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * i / 48.0
			var d := 1.0 + pow(sin(a), 2)
			pts.append(c + Vector2(34 * cos(a) / d, 30 * sin(a) * cos(a) / d))
		draw_polyline(pts, Palette.OUTLINE, 15.0, true)
		draw_polyline(pts, Color.WHITE, 8.0, true)
		var k := fmod(_t * 0.45, 1.0)
		var a2 := TAU * k
		var d2 := 1.0 + pow(sin(a2), 2)
		var p := c + Vector2(34 * cos(a2) / d2, 30 * sin(a2) * cos(a2) / d2)
		DrawUtil.shape(self, DrawUtil.star_points(p, 11.0, 5.0, _t * 2.0), Palette.GOLD, Palette.OUTLINE, 2.5)
		# brilhinhos piscando
		for i in 4:
			var sp := Vector2(r.size.x * (0.55 + 0.13 * i), r.position.y + 16 + (i % 2) * (r.size.y - 34))
			var tw := 0.5 + 0.5 * sin(_t * 3.0 + i * 1.7)
			DrawUtil.shape(self, DrawUtil.star_points(sp, 3.0 + 4.0 * tw, 1.6 + 1.6 * tw), Color(1, 1, 1, 0.4 + 0.5 * tw), Color(1, 1, 1, 0), 0.0)
		# selo "∞" de corrida em andamento
		if running:
			DrawUtil.disc(self, Vector2(r.end.x - 26, r.position.y + 10), 12.0, Palette.DANGER, Palette.OUTLINE, 3.0)
