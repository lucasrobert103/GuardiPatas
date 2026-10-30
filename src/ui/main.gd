extends Node
## Raiz do jogo: troca de telas com transição suave e trata o botão "voltar" do Android.

var _current: Node
var _fade: ColorRect
var _busy := false
var _cb_filter: ColorRect


func _apply_colorblind() -> void:
	var mode := int(Game.setting("colorblind"))
	_cb_filter.visible = mode > 0
	(_cb_filter.material as ShaderMaterial).set_shader_parameter("mode", mode)


func _ready() -> void:
	# filtro de daltonismo (Ajustes): corrige as cores da tela toda, abaixo da transição
	var cb_layer := CanvasLayer.new()
	cb_layer.layer = 99
	add_child(cb_layer)
	_cb_filter = ColorRect.new()
	_cb_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cb_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://src/core/daltonize.gdshader")
	_cb_filter.material = mat
	cb_layer.add_child(_cb_filter)
	_apply_colorblind()
	Game.settings_changed.connect(_apply_colorblind)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Palette.UI_BG
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_open("title" if Game.splash_shown else "splash", null, false)
	Game.splash_shown = true
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.5)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _current is Level:
			var lv := _current as Level
			if lv.hud != null:
				lv.hud.on_back_pressed()
		elif _current is TitleScreen:
			get_tree().quit()
		else:
			go("title", null)
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		# app minimizado no meio da fase: pausa para o jogador não perder a tentativa
		if _current is Level and (_current as Level).hud != null:
			var lv := _current as Level
			if lv.state == Level.State.RUNNING or lv.state == Level.State.DRAWING:
				lv.hud._open_pause()


func go(screen: String, arg: Variant) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.18)
	await tw.finished
	_open(screen, arg, true)
	_fade.color = Palette.UI_BG
	var tw2 := create_tween()
	tw2.tween_property(_fade, "modulate:a", 0.0, 0.22)
	await tw2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _open(screen: String, arg: Variant, _animated: bool) -> void:
	get_tree().paused = false
	Sfx.stop_all_loops()
	if _current != null:
		_current.queue_free()
		_current = null
	match screen:
		"level":
			if arg is Dictionary:
				_start_custom(arg)
			else:
				Game.current_custom = {}
				_start_level(int(arg))
			return
		"store":
			_current = StoreScreen.new()
		"daily":
			_current = DailyScreen.new()
		"map":
			var m := LevelSelect.new()
			m.setup(int(arg) if arg != null else -1)
			_current = m
		"collection":
			var cs := CollectionScreen.new()
			if arg is String:
				cs._tab = arg
			_current = cs
		"home":
			_current = HomeScreen.new()
		"editor":
			_current = EditorList.new()
		"edit":
			var ed := EditorScreen.new()
			ed.custom_index = int(arg) if arg != null else -1
			_current = ed
		"album":
			_current = AlbumScreen.new()
		"splash":
			_fade.color = SplashScreen.INDIGO
			_current = SplashScreen.new()
		"settings":
			_current = SettingsScreen.new()
		_:
			_current = TitleScreen.new()
	(_current as Control).theme = UiKit.make_theme()
	_current.connect("go", go)
	add_child(_current)


func _start_level(index: int) -> void:
	var data := LevelDB.get_level(index)
	if data.is_empty():
		_open("map", null, false)
		return
	Game.current_index = index
	var lv := Level.new()
	lv.setup(index, data, true)
	lv.navigate.connect(_on_level_nav)
	_current = lv
	add_child(lv)
	Sfx.music(Sfx.level_track(data))
	if Game.pending_hint and lv.hud != null:
		Game.pending_hint = false
		lv.hud._on_hint()


## Fase fora da campanha (Desafio do Dia ou fase do editor): os dados vêm prontos.
func _start_custom(data: Dictionary) -> void:
	Game.current_custom = data
	var lv := Level.new()
	lv.setup(-1, data, true)
	lv.navigate.connect(_on_level_nav)
	_current = lv
	add_child(lv)
	Sfx.music(Sfx.level_track(data))
	if Game.pending_hint and lv.hud != null:
		Game.pending_hint = false
		lv.hud._on_hint()


func _on_level_nav(action: String) -> void:
	if not Game.current_custom.is_empty():
		match action:
			"restart":
				Game.record_retry()
				_open("level", Game.current_custom, false)
			_:
				var daily := str(Game.current_custom.get("mode", "")) == "daily"
				var ci := int(Game.current_custom.get("custom_index", -1))
				Game.current_custom = {}
				if daily:
					go("daily", null)
				else:
					go("edit", ci)
		return
	match action:
		"restart":
			Game.record_retry()
			_open("level", Game.current_index, false)
		"next":
			Game.free_mode = false
			go("level", Game.current_index + 1)
		"menu":
			Game.free_mode = false
			go("map", int(LevelDB.get_level(Game.current_index).get("world", 1)))
