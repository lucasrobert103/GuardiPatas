extends Node
## Vídeo de divulgação do GuardiPatas (vertical 9:16), gravado pelo próprio jogo.
## Um "dedo virtual" joga de verdade: desenha as linhas, cuida dos bichinhos na Casinha
## e monta uma fase no editor. Tudo passa pelos mesmos toques que o jogador faria.
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1080x1920 \
##       --fixed-fps 30 --write-movie /pasta/promo.avi res://tools/promo.tscn
##   (depois tools/make_promo.sh converte para MP4)

const BG := Color("fff6e6")
const CAPTION_BG := Color("5b4b8a")

var _screen: Node
var _overlay: CanvasLayer
var _caption: PanelContainer
var _caption_label: Label
var _finger: Finger
var _fade: ColorRect
var _music: AudioStreamPlayer
var _pointer := Vector2.ZERO


func _ready() -> void:
	Game.persist = false
	Game.load_save()
	Legal.accept()
	Game.set_setting("lang", "pt_BR")
	Game.set_setting("difficulty", 0)
	Game.set_setting("vibration", false)
	Game.data["met"] = Cast.ORDER.duplicate()
	Game.data["seen_insects"] = Nest.KINDS.duplicate() + ["termite_queen"]
	Game.data["coins"] = 1250
	for i in LevelDB.count():
		Game.data["levels"][str(LevelDB.get_level(i)["id"])] = {"stars": 3, "best": 9.0}
	Game.splash_shown = true
	_build_overlay()
	await _run()
	get_tree().quit()


# ------------------------------------------------------------------ roteiro
func _run() -> void:
	# 1) abertura RetroNexa (com o som original)
	var splash := SplashScreen.new()
	await _show(splash, false)
	await _wait(SplashScreen.DURATION - 0.35)
	await _fade_to(Color("1b1534"), 0.3)
	_start_music()

	# 2) tela inicial com a turma passando
	await _show(TitleScreen.new())
	await _wait(0.5)
	await _say("Os bichinhos precisam de você!")
	await _wait(1.6)
	var title := _screen as TitleScreen
	var play := _find_button(title, "Jogar")
	if play != null:
		await _tap(play.get_global_rect().get_center(), false)
	await _hide_caption()

	# 3) jogabilidade: desenhar o abrigo e segurar os insetos
	var lv := await _level("1-1")
	await _say("Desenhe um abrigo com o dedo")
	await _wait(0.6)
	for st in lv.solution_strokes():
		await _draw_stroke(lv, st, 1.1)
		await _wait(0.25)
	await _hide_caption()
	await _wait(0.9)
	await _say("Os insetos atacam… segure firme!")
	lv.set_simulation_speed(2)
	await _until(func(): return lv.state != Level.State.RUNNING, 9.0)
	await _hide_caption()
	await _wait(2.2)

	# 4) mapa: muitas fases
	var map := LevelSelect.new()
	map.setup(9)
	await _show(map)
	await _say("123 fases em 14 mundos")
	await _wait(2.0)
	await _hide_caption()

	# 5) montagem rápida: mundos, poderes e chefões
	for spec in [["8-6", "Mergulhe no fundo do mar"], ["10-3", "Insetos com poderes especiais"], ["13-10", "Enfrente chefões gigantes!"]]:
		var clip := await _level(spec[0])
		await _say(spec[1])
		for st in clip.solution_strokes():
			await _draw_stroke(clip, st, 0.55)
			await _wait(0.1)
		if clip.state == Level.State.DRAWING:
			clip.start_simulation()
		clip.set_simulation_speed(2)
		await _wait(3.0)
		await _hide_caption()

	# 6) Casinha: comida, banho e carinho
	var home := HomeScreen.new()
	await _show(home)
	await _say("Cuide da turma na Casinha")
	await _wait(0.6)
	await _tap(home._dock["food"].get_global_rect().get_center())
	await _wait(0.4)
	await _drag(home._objects["fruit"].get_global_rect().get_center(), home._hero().art.position, 0.8)
	await _wait(0.8)
	await _tap(home._dock["bath"].get_global_rect().get_center())
	await _wait(0.4)
	await _drag(home._objects["soap"].get_global_rect().get_center(), home._hero().art.position, 0.6)
	for i in 3:
		await _tap(home._hero().art.position + Vector2(-20 + i * 20, -10))
	await _wait(0.3)
	await _tap(home._objects["shower"].get_global_rect().get_center())
	await _wait(1.0)
	await _hide_caption()

	# 7) editor: monte sua própria fase e jogue
	var ed := EditorScreen.new()
	ed.custom_index = -1
	await _show(ed)
	await _say("Crie suas próprias fases!")
	await _wait(0.5)
	await _tap(Vector2(360, 955))                       # bichinho
	await _tap(ed._tool_btns["insect"].get_global_rect().get_center())
	await _wait(0.4)
	var cell := _find_label_button(ed._modal, str(Cast.INSECTS.get("ladybug", {}).get("name", "")))
	if cell == null:
		cell = _find_label_button(ed._modal, "Abelha")
	if cell != null:
		await _tap(cell.get_global_rect().get_center())
	await _wait(0.3)
	await _tap(Vector2(560, 420))                        # ninho no céu
	await _tap(ed._tool_btns["block"].get_global_rect().get_center())
	await _tap(Vector2(150, 980))                        # bloco
	await _tap(ed._tool_btns["rock"].get_global_rect().get_center())
	await _tap(Vector2(600, 960))                        # pedra
	await _wait(0.4)
	var draft: Dictionary = ed.draft.duplicate(true)
	await _hide_caption()
	var custom := EditorScreen.playable(draft, -1)
	var mine := await _level_data(custom)
	await _say("…e jogue na hora")
	var a: Dictionary = draft["animals"][0]
	var cx := float(a["pos"][0])
	await _draw_stroke(mine, PackedVector2Array(Tutorials.dome(cx, Animal.half_height(str(a["type"])) * 0 + 60.0, float(a["pos"][1]) - Animal.half_height(str(a["type"]))).map(func(p): return Vector2(p[0], p[1]))), 0.9)
	if mine.state == Level.State.DRAWING:
		mine.start_simulation()
	mine.set_simulation_speed(2)
	await _wait(3.2)
	await _hide_caption()

	# 8) final
	await _show(EndCard.new())
	await _wait(4.6)
	_fade_music(1.2)
	await _fade_to(Color.BLACK, 1.0)
	await _wait(0.3)


# ------------------------------------------------------------------ telas
func _show(node: Node, fade := true) -> void:
	if fade:
		await _fade_to(BG, 0.22)
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	if _screen != null:
		_screen.queue_free()
		await get_tree().process_frame
	_screen = node
	if node is Control:
		(node as Control).theme = UiKit.make_theme()
	add_child(node)
	move_child(node, 0)
	await get_tree().process_frame
	if fade:
		await _fade_from(0.25)


func _level(id: String) -> Level:
	var idx := LevelDB.index_of(id)
	return await _level_data(LevelDB.get_level(idx), idx)


func _level_data(data: Dictionary, idx: int = -1) -> Level:
	var lv := Level.new()
	lv.setup(idx, data, true)
	await _show(lv)
	await get_tree().physics_frame
	return lv


# ------------------------------------------------------------------ dedo virtual
func _send_move(p: Vector2, held: bool) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	e.relative = p - _pointer
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	_pointer = p
	get_viewport().push_input(e, true)


func _send_button(down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.position = _pointer
	e.global_position = _pointer
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	get_viewport().push_input(e, true)


## Leva o dedo até o ponto (sem tocar), num movimento suave.
func _glide(target: Vector2, duration: float = 0.3) -> void:
	_finger.show_finger()
	var start := _finger.position if _finger.visible_amount > 0.05 else target + Vector2(90, 160)
	var t := 0.0
	while t < duration:
		t += get_process_delta_time()
		var k := smoothstep(0.0, 1.0, minf(t / duration, 1.0))
		_finger.position = start.lerp(target, k)
		_send_move(_finger.position, false)
		await get_tree().process_frame


func _tap(p: Vector2, really := true) -> void:
	await _glide(p, 0.28)
	_finger.press(true)
	if really:
		_send_button(true)
	await _wait(0.08)
	if really:
		_send_button(false)
	_finger.press(false)
	await _wait(0.12)


func _drag(a: Vector2, b: Vector2, duration: float) -> void:
	await _glide(a, 0.28)
	_finger.press(true)
	_send_button(true)
	var t := 0.0
	while t < duration:
		t += get_process_delta_time()
		var k := smoothstep(0.0, 1.0, minf(t / duration, 1.0))
		_finger.position = a.lerp(b, k)
		_send_move(_finger.position, true)
		await get_tree().process_frame
	_send_button(false)
	_finger.press(false)


## Desenha um traço da fase com o dedo, ponto a ponto, na velocidade de uma pessoa.
func _draw_stroke(lv: Level, pts: PackedVector2Array, duration: float) -> void:
	if pts.size() < 2 or lv.state != Level.State.DRAWING:
		return
	var xf := lv.get_global_transform_with_canvas()
	var screen := PackedVector2Array()
	for p in pts:
		screen.append(xf * p)
	var total := 0.0
	for i in range(1, screen.size()):
		total += screen[i].distance_to(screen[i - 1])
	await _glide(screen[0], 0.3)
	_finger.press(true)
	_send_button(true)
	var t := 0.0
	while t < duration:
		t += get_process_delta_time()
		var p := _along(screen, total * minf(t / duration, 1.0))
		_finger.position = p
		_send_move(p, true)
		await get_tree().process_frame
	_send_move(screen[screen.size() - 1], true)
	await get_tree().physics_frame
	_send_button(false)
	_finger.press(false)
	await get_tree().physics_frame
	await get_tree().physics_frame


func _along(pts: PackedVector2Array, dist: float) -> Vector2:
	for i in range(1, pts.size()):
		var seg := pts[i].distance_to(pts[i - 1])
		if dist <= seg:
			return pts[i - 1].lerp(pts[i], dist / maxf(seg, 0.001))
		dist -= seg
	return pts[pts.size() - 1]


# ------------------------------------------------------------------ legendas, fade, música
func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 90
	add_child(_overlay)
	_caption = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(CAPTION_BG, 0.92)
	st.set_corner_radius_all(34)
	st.border_color = Color("ffffff")
	st.set_border_width_all(4)
	st.content_margin_left = 30
	st.content_margin_right = 30
	st.content_margin_top = 14
	st.content_margin_bottom = 18
	st.shadow_color = Color(0, 0, 0, 0.25)
	st.shadow_size = 10
	st.shadow_offset = Vector2(0, 5)
	_caption.add_theme_stylebox_override("panel", st)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_label = UiKit.label("", 40, Color.WHITE, 0, Color.WHITE, true)
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.custom_minimum_size.x = 560
	_caption.add_child(_caption_label)
	_caption.modulate.a = 0.0
	_overlay.add_child(_caption)
	_finger = Finger.new()
	_overlay.add_child(_finger)
	var fl := CanvasLayer.new()
	fl.layer = 95
	add_child(fl)
	_fade = ColorRect.new()
	_fade.color = Color(BG, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.size = Vector2(720, 1280)
	fl.add_child(_fade)


func _say(text: String) -> void:
	_caption_label.text = text
	_caption.size = Vector2.ZERO
	await get_tree().process_frame
	_caption.size = _caption.get_combined_minimum_size()
	_caption.position = Vector2(360 - _caption.size.x / 2, 1090 - _caption.size.y / 2)
	_caption.pivot_offset = _caption.size / 2
	_caption.scale = Vector2(0.7, 0.7)
	var tw := create_tween().set_parallel()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.18)
	tw.tween_property(_caption, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("pop", -6.0, 1.2)
	await _wait(0.2)


func _hide_caption() -> void:
	_finger.hide_finger()
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 0.0, 0.15)
	await tw.finished


func _fade_to(color: Color, duration: float) -> void:
	_fade.color = Color(color, _fade.color.a)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, duration)
	await tw.finished


func _fade_from(duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, duration)
	await tw.finished


func _start_music() -> void:
	# a trilha do vídeo é contínua: as músicas de cada tela ficam mudas
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
	var wav: AudioStreamWAV = load("res://assets/audio/music_camp.wav").duplicate()
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = int(wav.get_length() * wav.mix_rate)
	_music = AudioStreamPlayer.new()
	_music.stream = wav
	_music.volume_db = -30.0
	add_child(_music)
	_music.play()
	create_tween().tween_property(_music, "volume_db", -3.0, 1.0)


func _fade_music(duration: float) -> void:
	if _music != null:
		create_tween().tween_property(_music, "volume_db", -40.0, duration)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _until(cond: Callable, limit: float) -> void:
	var t := 0.0
	while t < limit and not cond.call():
		t += get_process_delta_time()
		await get_tree().process_frame


func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text and (n as Button).is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find_button(c, text)
		if r != null:
			return r
	return null


func _find_label_button(n: Node, text: String) -> Button:
	if n == null:
		return null
	if n is Button:
		for c in n.get_children():
			if c is Label and (c as Label).text == text:
				return n
	for c in n.get_children():
		var r := _find_label_button(c, text)
		if r != null:
			return r
	return null


# ------------------------------------------------------------------ peças visuais
class Finger:
	extends Node2D
	var visible_amount := 0.0
	var _target := 0.0
	var _down := 0.0
	var _ripple := 1.0
	func show_finger() -> void:
		_target = 1.0
	func hide_finger() -> void:
		_target = 0.0
	func press(on: bool) -> void:
		_down = 1.0 if on else 0.0
		if on:
			_ripple = 0.0
	func _process(delta: float) -> void:
		visible_amount = move_toward(visible_amount, _target, delta * 6.0)
		_ripple = minf(_ripple + delta * 2.6, 1.0)
		queue_redraw()
	func _draw() -> void:
		if visible_amount <= 0.01:
			return
		var a := visible_amount
		if _ripple < 1.0:
			draw_circle(Vector2.ZERO, 26 + 46 * _ripple, Color(1, 1, 1, (1.0 - _ripple) * 0.7 * a), false, 5, true)
		var r := 30.0 - 5.0 * _down
		draw_circle(Vector2(0, 4), r + 4, Color(0, 0, 0, 0.18 * a), true, -1, true)
		draw_circle(Vector2.ZERO, r + 4, Color(1, 1, 1, 0.95 * a), true, -1, true)
		draw_circle(Vector2.ZERO, r, Color(1, 0.86, 0.55, (0.55 + 0.3 * _down) * a), true, -1, true)


## Cartão final: logo, turma pulando e chamada para baixar.
class EndCard:
	extends Control
	var _t := 0.0
	var _pets: Array[AnimalArt] = []
	var _logo: Label
	var _tag: Label
	var _cta: PanelContainer
	var _by: Label
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var species := ["capi", "pingo", "lulu", "tuca", "brasa", "nino", "bolota"]
		for i in species.size():
			var a := AnimalArt.new()
			a.species = species[i] if Animal.SPECIES.has(species[i]) else "capi"
			a.preview = true
			a.mood = "happy"
			a.accessory = Game.equipped(a.species)
			add_child(a)
			_pets.append(a)
		_logo = UiKit.title("GuardiPatas", 104)
		_logo.size = Vector2(720, 140)
		_logo.position = Vector2(0, 250)
		_logo.pivot_offset = _logo.size / 2
		add_child(_logo)
		_tag = UiKit.label("Desenhe. Proteja. Divirta-se!", 38, Palette.WHITE, 10, Palette.OUTLINE)
		_tag.size = Vector2(720, 60)
		_tag.position = Vector2(0, 410)
		add_child(_tag)
		_cta = PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Palette.UI_GOOD
		st.set_corner_radius_all(40)
		st.border_color = Palette.OUTLINE
		st.set_border_width_all(5)
		st.border_width_bottom = 11
		st.content_margin_left = 40
		st.content_margin_right = 40
		st.content_margin_top = 16
		st.content_margin_bottom = 18
		_cta.add_theme_stylebox_override("panel", st)
		var cta_label := UiKit.label("Jogue grátis no Google Play", 38, Palette.OUTLINE)
		_cta.add_child(cta_label)
		add_child(_cta)
		_by = UiKit.label("RetroNexa", 30, Palette.WHITE, 8, Palette.OUTLINE)
		_by.size = Vector2(720, 50)
		_by.position = Vector2(0, 1150)
		add_child(_by)
		UiKit.pop_in(_logo, 0.05)
		UiKit.pop_in(_tag, 0.35)
		UiKit.pop_in(_cta, 0.7)
		Sfx.play("win")
	func _process(delta: float) -> void:
		_t += delta
		_cta.size = _cta.get_combined_minimum_size()
		_cta.position = Vector2(360 - _cta.size.x / 2, 960)
		_cta.pivot_offset = _cta.size / 2
		if _t > 1.2:
			_cta.scale = Vector2.ONE * (1.0 + 0.04 * sin(_t * 6.0))
		for i in _pets.size():
			var x := 90.0 + i * 90.0
			var hop := absf(sin(_t * 4.0 + i * 0.9)) * 38.0
			_pets[i].position = Vector2(x, 820 - hop)
			_pets[i].scale = Vector2.ONE * 0.8
		queue_redraw()
	func _draw() -> void:
		DrawUtil.vgradient(self, Rect2(Vector2.ZERO, size), Color("8fd3ff"), Color("c9f0d6"))
		for i in 6:
			var c := Vector2(fmod(i * 170.0 + _t * 30.0, 900.0) - 90.0, 120 + (i % 3) * 120)
			draw_circle(c, 46, Color(1, 1, 1, 0.75), true, -1, true)
			draw_circle(c + Vector2(44, 10), 36, Color(1, 1, 1, 0.75), true, -1, true)
			draw_circle(c + Vector2(-40, 14), 30, Color(1, 1, 1, 0.75), true, -1, true)
		draw_rect(Rect2(0, 880, 720, 400), Color("7cc46b"))
		draw_rect(Rect2(0, 880, 720, 14), Color("5ea852"))
		for i in 18:
			var p := Vector2(20 + i * 40, 905 + (i % 2) * 8)
			draw_circle(p, 6, Color("ffd23f") if i % 3 == 0 else Color("ff8fb1"), true, -1, true)
