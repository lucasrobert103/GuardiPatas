class_name InfiniteScreen
extends Control
## Tela do Modo Infinito: recorde, corrida atual (corações) e "Começar". Ao começar (ou ao
## ir para a próxima), mostra o carregamento enquanto a fase é montada; o jogador só entra
## quando ela está pronta.

signal go(screen: String, arg: Variant)

const STEPS := ["Escolhendo o cenário…", "Chamando os bichinhos…", "Espalhando os ninhos de insetos…",
	"Ajeitando pedras e plataformas…", "Deixando tudo prontinho…", "Quase lá!"]

var director: InfiniteDirector
var waiting_stage := -1
var _status: Label
var _loader: Control
var _bar: LoadBar
var _step: Label
var _stage_label: Label
var _start_ms := 0
var _runner: AnimalArt
var _bees: Array[InsectArt] = []
var _buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := MenuBg.new()
	bg.world_id = 9
	add_child(bg)
	var col := UiKit.vbox(18)
	UiKit.keep_safe(col, 24, 24, 24, 24)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	var top := UiKit.hbox(10)
	col.add_child(top)
	var back := UiKit.icon_button("back")
	back.pressed.connect(func(): go.emit("title", null))
	top.add_child(back)
	_buttons.append(back)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	col.add_child(UiKit.title("Modo Infinito", 64))
	col.add_child(UiKit.label("Fases novas sem parar, cada vez mais difíceis.\nTrês corações: perdeu, tenta de novo. Acabaram, fim da corrida!", 24, Palette.WHITE, 8, Palette.OUTLINE, true))
	var rec := UiKit.panel(Palette.CREAM)
	col.add_child(rec)
	var rbox := UiKit.vbox(6)
	rec.add_child(rbox)
	rbox.add_child(UiKit.label(tr("Recorde: %d fases seguidas") % Infinite.best(), 34, Palette.UI_TEXT))
	rbox.add_child(UiKit.label(tr("Corridas: %d  ·  Fases vencidas no total: %d") % [int(Game.data["infinite"]["runs"]), int(Game.data["infinite"]["cleared"])], 20, Color(Palette.UI_TEXT, 0.7)))
	rbox.add_child(UiKit.label("A cada 5 fases: baú com 40 moedas e petiscos!", 20, Palette.UI_PRIMARY.darkened(0.3)))
	var stage_spacer := Control.new()
	stage_spacer.custom_minimum_size = Vector2(0, 160)
	col.add_child(stage_spacer)
	_status = UiKit.label("", 26, Palette.WHITE, 8, Palette.OUTLINE, true)
	col.add_child(_status)
	if waiting_stage < 0:
		var cont := Infinite.active()
		var start := UiKit.button(tr("Continuar · Fase %d") % int(Infinite.run["stage"]) if cont else "Começar corrida", Palette.UI_GOOD, "play", 460, 110)
		start.add_theme_font_size_override("font_size", UiKit.fs(32))
		start.pressed.connect(func():
			if not Infinite.active():
				Infinite.start_run()
				director.clear()
			_wait_for(int(Infinite.run["stage"])))
		start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(start)
		_buttons.append(start)
		if cont:
			var fresh := UiKit.button("Nova corrida", Palette.UI_SECONDARY, "restart", 460, 80)
			fresh.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			fresh.pressed.connect(func():
				Infinite.start_run()
				director.clear()
				_wait_for(1))
			col.add_child(fresh)
			_buttons.append(fresh)
	_build_loader()
	if waiting_stage >= 0:
		_wait_for(waiting_stage)
	Sfx.music("music_menu")


## Cartão de carregamento: cobre a tela (nada pode ser tocado até a fase ficar pronta).
func _build_loader() -> void:
	_loader = Control.new()
	_loader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loader.visible = false
	add_child(_loader)
	_loader.add_child(UiKit.dim(0.55))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loader.add_child(center)
	var card := UiKit.panel(Palette.CREAM)
	card.custom_minimum_size = Vector2(560, 0)
	center.add_child(card)
	var box := UiKit.vbox(16)
	card.add_child(box)
	_stage_label = UiKit.title("", 54)
	box.add_child(_stage_label)
	var art := Control.new()
	art.custom_minimum_size = Vector2(0, 150)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)
	_runner = AnimalArt.new()
	_runner.species = "pompom"
	_runner.preview = true
	_runner.mood = "happy"
	art.add_child(_runner)
	for i in 2:
		var b := InsectArt.new()
		b.kind = "bee"
		b.radius = 14.0
		art.add_child(b)
		_bees.append(b)
	_bar = LoadBar.new()
	_bar.custom_minimum_size = Vector2(480, 44)
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_bar)
	_step = UiKit.label("", 26, Palette.UI_TEXT, 0, Palette.WHITE, true)
	_step.custom_minimum_size = Vector2(480, 70)
	box.add_child(_step)


func loading() -> bool:
	return waiting_stage >= 0


func _wait_for(stage: int) -> void:
	waiting_stage = stage
	_start_ms = Time.get_ticks_msec()
	for b in _buttons:
		b.disabled = true
	_status.text = ""
	_stage_label.text = tr("Fase %d") % stage
	_loader.visible = true
	UiKit.pop_in(_loader.get_child(1).get_child(0))
	if director.is_ready(stage):
		_launch(stage)
		return
	if not director.prepared.is_connected(_on_prepared):
		director.prepared.connect(_on_prepared)
	director.prepare(stage)


func _on_prepared(s: int) -> void:
	if s == waiting_stage and is_inside_tree():
		_launch(s)


func _launch(stage: int) -> void:
	var data := director.take(stage)
	# a barra chega ao fim e a fase abre (sem pressa demais nem espera à toa)
	var shown := (Time.get_ticks_msec() - _start_ms) / 1000.0
	get_tree().create_timer(maxf(0.35, 0.9 - shown), true, false, true).timeout.connect(func():
		if is_inside_tree():
			go.emit("level", data)
			waiting_stage = -1)


func _exit_tree() -> void:
	if director != null and director.prepared.is_connected(_on_prepared):
		director.prepared.disconnect(_on_prepared)


func _process(_delta: float) -> void:
	if _loader == null or not _loader.visible:
		return
	# tempo real: a física pode estar acelerada enquanto prepara
	var t := (Time.get_ticks_msec() - _start_ms) / 1000.0
	var frac := director.progress(waiting_stage) if director != null else 0.0
	_bar.value = frac
	_bar.queue_redraw()
	var idx := mini(int(frac * (STEPS.size() - 1) + 0.25), STEPS.size() - 1)
	_step.text = tr(STEPS[idx])
	var w := _runner.get_parent() as Control
	var span := maxf(w.size.x, 200.0)
	var x := fmod(t * 170.0, span + 160.0) - 60.0
	_runner.position = Vector2(x, 110 - absf(sin(t * 10.0)) * 14.0)
	_runner.facing = 1.0
	for i in _bees.size():
		_bees[i].position = _runner.position + Vector2(-80.0 - i * 46.0, -46.0 + sin(t * 6.0 + i) * 12.0)


## Barra arredondada com brilho correndo.
class LoadBar:
	extends Control
	var value := 0.0
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.9)
		sb.set_corner_radius_all(int(size.y / 2))
		sb.set_border_width_all(4)
		sb.border_color = Palette.OUTLINE
		draw_style_box(sb, r)
		var w := (size.x - 12) * clampf(value, 0.0, 1.0)
		if w > 4:
			var fill := StyleBoxFlat.new()
			fill.bg_color = Color("b18cff")
			fill.set_corner_radius_all(int(size.y / 2) - 6)
			draw_style_box(fill, Rect2(6, 6, w, size.y - 12))
			var t := Time.get_ticks_msec() / 1000.0
			var gx := 6 + fmod(t * 260.0, maxf(w, 1.0))
			draw_rect(Rect2(gx, 9, minf(26.0, 6 + w - gx), 6), Color(1, 1, 1, 0.55))
