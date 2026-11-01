class_name InfiniteScreen
extends Control
## Tela do Modo Infinito: recorde, corrida atual (corações) e "Começar". Também serve de
## tela de espera enquanto a próxima fase está sendo simulada escondida.

signal go(screen: String, arg: Variant)

var director: InfiniteDirector
var waiting_stage := -1
var _status: Label
var _t := 0.0
var _runner: AnimalArt
var _bees: Array[InsectArt] = []


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
	stage_spacer.custom_minimum_size = Vector2(0, 220)
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
		if cont:
			var fresh := UiKit.button("Nova corrida", Palette.UI_SECONDARY, "restart", 460, 80)
			fresh.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			fresh.pressed.connect(func():
				Infinite.start_run()
				director.clear()
				_wait_for(1))
			col.add_child(fresh)
	# bichinho correndo de abelhas (enquanto prepara)
	_runner = AnimalArt.new()
	_runner.species = "pompom"
	_runner.preview = true
	_runner.mood = "scared"
	add_child(_runner)
	for i in 2:
		var b := InsectArt.new()
		b.kind = "bee"
		b.radius = 14.0
		add_child(b)
		_bees.append(b)
	if waiting_stage >= 0:
		_wait_for(waiting_stage)
	Sfx.music("music_menu")


func _wait_for(stage: int) -> void:
	waiting_stage = stage
	_status.text = tr("Preparando a Fase %d…\nTestando se ela tem solução!") % stage
	if director.is_ready(stage):
		_launch(stage)
		return
	director.prepared.connect(func(s: int):
		if s == waiting_stage and is_inside_tree():
			_launch(s))
	director.prepare(stage)


func _launch(stage: int) -> void:
	var data := director.take(stage)
	# espera a transição de tela terminar antes de pedir a próxima
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_inside_tree():
			waiting_stage = -1
			go.emit("level", data))


func _process(delta: float) -> void:
	_t += delta
	var y := size.y * 0.62
	var x := fmod(_t * 160.0, size.x + 200.0) - 100.0
	_runner.position = Vector2(x, y + absf(sin(_t * 10.0)) * -8.0)
	_runner.facing = 1.0
	_runner.visible = waiting_stage >= 0
	for i in _bees.size():
		_bees[i].position = _runner.position + Vector2(-90.0 - i * 50.0, -40.0 + sin(_t * 6.0 + i) * 12.0)
		_bees[i].visible = _runner.visible
