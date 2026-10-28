extends Node
## Áudio do jogo: efeitos (pool de players), loops (zumbidos, rabisco) e música com crossfade.
## Nenhuma informação depende só do som: todo evento sonoro também tem feedback visual.

const SFX_DIR := "res://assets/audio/"
const POOL_SIZE := 12
const SOUNDS := [
	"ui_click", "ui_back", "ui_locked", "draw_loop", "draw_end", "ink_empty", "draw_blocked",
	"line_land", "buzz_bee", "buzz_mosquito", "wasp_charge", "wasp_dash", "ant_step", "beetle_step",
	"moth_flutter", "bonk", "sting", "gasp", "splash", "star1", "star2", "star3", "coin", "tick",
	"pop", "hint", "win", "lose", "unlock", "music_menu", "music_level", "retro_jingle", "quack", "baa", "bloop",
	"music_forest", "music_valley", "music_pond", "music_camp", "music_mountain", "music_beach", "music_sea",
	"music_boss",
]
## Trilha de cada mundo (tools/gen_audio.py → world_music); fases com chefão usam "music_boss".
const WORLD_MUSIC := {
	1: "music_level", 2: "music_forest", 3: "music_valley", 4: "music_pond",
	5: "music_camp", 6: "music_mountain", 7: "music_beach", 8: "music_sea",
}

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _loops: Dictionary = {}
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_name := ""
var _last_play: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for s in SOUNDS:
		var path: String = SFX_DIR + s + ".wav"
		if ResourceLoader.exists(path):
			_streams[s] = load(path)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)
	_music_a = _make_music_player()
	_music_b = _make_music_player()


func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = &"Music"
	p.volume_db = -80.0
	add_child(p)
	return p


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")


func set_volumes(music: float, sfx: float) -> void:
	_ensure_buses()
	_set_bus_linear("Music", music)
	_set_bus_linear("SFX", sfx)


func _set_bus_linear(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))


## Toca um efeito. `pitch_jitter` varia o tom para sons repetidos não cansarem.
## `min_gap` evita empilhar o mesmo som dezenas de vezes no mesmo instante.
func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0, pitch_jitter: float = 0.0, min_gap: float = 0.03) -> void:
	if not _streams.has(sound):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_play.get(sound, -10.0)) < min_gap:
		return
	_last_play[sound] = now
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = _streams[sound]
	p.volume_db = volume_db
	p.pitch_scale = maxf(0.05, pitch + randf_range(-pitch_jitter, pitch_jitter))
	p.play()


## Inicia (ou ajusta) um som contínuo identificado por `key`.
func loop(key: String, sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _streams.has(sound):
		return
	var p: AudioStreamPlayer = _loops.get(key)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = &"SFX"
		p.stream = _streams[sound]
		add_child(p)
		_loops[key] = p
	p.volume_db = volume_db
	p.pitch_scale = maxf(0.05, pitch)
	if not p.playing:
		p.play()


func stop_loop(key: String) -> void:
	var p: AudioStreamPlayer = _loops.get(key)
	if p != null:
		p.stop()
		p.queue_free()
		_loops.erase(key)


func stop_all_loops() -> void:
	for k in _loops.keys():
		stop_loop(k)


static func level_track(data: Dictionary) -> String:
	if not (data.get("bosses", []) as Array).is_empty():
		return "music_boss"
	return WORLD_MUSIC.get(int(data.get("world", 1)), "music_level")


## Troca de música com crossfade suave.
func music(track: String, fade: float = 0.8) -> void:
	if track == _music_name or not _streams.has(track):
		return
	_music_name = track
	var old := _music_a
	_music_a = _music_b
	_music_b = old
	_music_a.stream = _streams[track]
	_music_a.volume_db = -40.0
	_music_a.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_music_a, "volume_db", -6.0, fade)
	tw.tween_property(_music_b, "volume_db", -80.0, fade)
	tw.chain().tween_callback(_music_b.stop)


func vibrate(ms: int) -> void:
	if Game.setting("vibration"):
		Input.vibrate_handheld(ms)
