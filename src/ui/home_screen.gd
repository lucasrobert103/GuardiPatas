class_name HomeScreen
extends Control
## Casinha dos bichinhos: os amigos já salvos passeiam pela sala (com os acessórios equipados).
## Toque num bichinho = carinho (pulinho + coração + a voz dele). "Petisco" chama todo mundo
## para o meio da sala. Na parede ficam as últimas fotos do Álbum.

signal go(screen: String, arg: Variant)

const FLOOR_Y := 0.72
var _pets: Array[Pet] = []
var _room: Room
var _treat := 0.0
var _hearts: Node2D


class Pet:
	extends RefCounted
	var art: AnimalArt
	var x := 0.0
	var depth := 0.0      # 0 = fundo, 1 = frente (desenha maior e mais embaixo)
	var target := 0.0
	var wait := 0.0
	var happy := 0.0
	var hop := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_room = Room.new()
	add_child(_room)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var met: Array = Game.data["met"]
	if met.is_empty():
		met = ["capi"]
	for sp in met:
		var p := Pet.new()
		p.art = AnimalArt.new()
		p.art.species = sp
		p.art.preview = true
		p.art.accessory = Game.equipped(sp)
		p.x = rng.randf_range(80, 640)
		p.depth = rng.randf()
		p.target = p.x
		p.wait = rng.randf_range(0.5, 3.0)
		add_child(p.art)
		_pets.append(p)
	_hearts = Node2D.new()
	add_child(_hearts)
	_build_ui()
	Sfx.music("music_menu")


func _build_ui() -> void:
	var top := UiKit.hbox(14)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_top = 24
	top.offset_right = -20
	add_child(top)
	var back := UiKit.icon_button("back")
	back.pressed.connect(func(): go.emit("title", null))
	top.add_child(back)
	var t := UiKit.label("Casinha da Turma", 44, Palette.WHITE, 12, Palette.OUTLINE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var bottom := UiKit.hbox(16)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.position.y -= 40
	add_child(bottom)
	var treat := UiKit.tile("Petisco", "heart", Color("ffb3c7"), 150)
	treat.pressed.connect(_give_treat)
	bottom.add_child(treat)
	var album := UiKit.tile("Álbum (%d)" % Game.data["album"].size(), "camera", Palette.UI_SECONDARY, 150)
	album.pressed.connect(func(): go.emit("album", null))
	bottom.add_child(album)
	var friends := UiKit.tile("Roupinhas", "paw", Palette.UI_PRIMARY, 150)
	friends.pressed.connect(func(): go.emit("collection", "wardrobe"))
	bottom.add_child(friends)
	var hint := UiKit.label("Toque num bichinho para fazer carinho!", 24, Palette.WHITE, 8, Palette.OUTLINE)
	hint.anchor_right = 1.0
	hint.offset_top = 130
	hint.offset_bottom = 170
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)


func _give_treat() -> void:
	_treat = 3.0
	Sfx.play("coin", -2.0, 1.4)
	for p in _pets:
		p.target = 360.0 + randf_range(-140, 140)
		p.wait = 0.0


func _floor_y(depth: float) -> float:
	return size.y * FLOOR_Y + depth * 150.0


func _process(delta: float) -> void:
	_treat = maxf(_treat - delta, 0.0)
	var reduce: bool = Game.setting("reduce_motion")
	for p in _pets:
		p.happy = maxf(p.happy - delta, 0.0)
		p.hop = maxf(p.hop - delta * 3.0, 0.0)
		var d := p.target - p.x
		if absf(d) > 4.0:
			var speed := 70.0 + 40.0 * (1.0 if _treat > 0.0 else 0.0)
			p.x += signf(d) * minf(absf(d), speed * delta)
			p.art.facing = signf(d)
		else:
			p.wait -= delta
			if p.wait <= 0.0 and _treat <= 0.0:
				p.target = clampf(p.x + randf_range(-220, 220), 70, size.x - 70)
				p.wait = randf_range(1.5, 4.5)
		var sc := 0.85 + p.depth * 0.3
		p.art.scale = Vector2(sc, sc)
		var bob := 0.0 if reduce else -sin(p.hop * PI) * 30.0
		var half := Animal.half_height(p.art.species) * sc
		p.art.position = Vector2(p.x, _floor_y(p.depth) - half + bob)
		p.art.z_index = int(p.depth * 10.0)
		p.art.mood = "happy" if p.happy > 0.0 or _treat > 0.0 else "idle"


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	var best: Pet = null
	var bd := 90.0
	for p in _pets:
		var d := p.art.position.distance_to(mb.position)
		if d < bd:
			bd = d
			best = p
	if best == null:
		return
	best.happy = 1.6
	best.hop = 1.0
	var voice: Array = Animal.SCARE_VOICE.get(best.art.species, ["gasp", 1.0])
	Sfx.play("pop" if voice[0] == "gasp" else voice[0], -2.0, float(voice[1]) * 1.15, 0.05)
	Game.add_stat("pets", 1)
	Game.save()
	var h := FloatingHeart.new()
	h.position = best.art.position + Vector2(0, -60)
	_hearts.add_child(h)


class FloatingHeart:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		position.y -= 60.0 * delta
		modulate.a = clampf(1.2 - _t, 0.0, 1.0)
		if _t > 1.2:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 32:
			var t := TAU * i / 32.0
			pts.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * 1.3)
		DrawUtil.shape(self, pts, Color("ff6b8a"), Palette.OUTLINE, 3.0)


## A sala: parede listrada, janela com o céu do último mundo, tapete, sofá e fotos na parede.
class Room:
	extends Control
	var _photos: Array[Texture2D] = []
	var _t := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var album: Array = Game.data["album"]
		for i in range(maxi(album.size() - 3, 0), album.size()):
			var img := Image.load_from_file(str(album[i].get("file", "")))
			if img != null and not img.is_empty():
				_photos.append(ImageTexture.create_from_image(img))

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var o := Palette.OUTLINE
		var floor_y := h * HomeScreen.FLOOR_Y - 40.0
		# parede
		draw_rect(Rect2(0, 0, w, floor_y), Color("ffe9c9"), true)
		for i in int(w / 60.0) + 1:
			draw_rect(Rect2(i * 60.0, 0, 30.0, floor_y), Color("fff3dd"), true)
		draw_rect(Rect2(0, floor_y - 26, w, 26), Color("d79a5b"), true)
		draw_line(Vector2(0, floor_y - 26), Vector2(w, floor_y - 26), o, 4.0, true)
		# chão de madeira
		draw_rect(Rect2(0, floor_y, w, h - floor_y), Color("c98a57"), true)
		for i in 8:
			var y := floor_y + 30.0 + i * 46.0
			draw_line(Vector2(0, y), Vector2(w, y), Color("a86c3a"), 3.0, true)
		DrawUtil.oval(self, Vector2(w * 0.5, floor_y + 150.0), Vector2(w * 0.44, 96.0), Color("ff9ec7"), o, 4.0)
		DrawUtil.oval(self, Vector2(w * 0.5, floor_y + 150.0), Vector2(w * 0.33, 66.0), Color("ffc2dc"), o, 0.0)
		# janela com céu do mundo mais avançado
		var wid := 1
		for i in LevelDB.count():
			if Game.is_unlocked(i):
				wid = int(LevelDB.get_level(i)["world"])
		var pal := Palette.world(wid)
		var win := Rect2(w * 0.08, h * 0.2, w * 0.34, h * 0.2)
		DrawUtil.vgradient(self, win, pal["sky_top"], pal["sky_bottom"])
		DrawUtil.cloud(self, win.position + Vector2(win.size.x * (0.3 + 0.1 * sin(_t * 0.3)), win.size.y * 0.35), 18.0, Color(1, 1, 1, 0.9))
		draw_rect(Rect2(win.position.x, win.end.y - win.size.y * 0.25, win.size.x, win.size.y * 0.25), pal["near"], true)
		draw_rect(win, o, false, 6.0)
		draw_line(Vector2(win.get_center().x, win.position.y), Vector2(win.get_center().x, win.end.y), o, 5.0, true)
		draw_line(Vector2(win.position.x, win.get_center().y), Vector2(win.end.x, win.get_center().y), o, 5.0, true)
		# fotos do álbum na parede (molduras)
		for i in 3:
			var fr := Rect2(w * (0.5 + i * 0.16), h * (0.2 + (i % 2) * 0.05), w * 0.13, w * 0.17)
			draw_rect(fr.grow(6), Color("fffaf2"), true)
			draw_rect(fr.grow(6), o, false, 4.0)
			if i < _photos.size():
				draw_texture_rect(_photos[_photos.size() - 1 - i], fr, false)
			else:
				draw_rect(fr, Color("e8dccb"), true)
				DrawUtil.disc(self, fr.get_center(), fr.size.x * 0.18, Color("f4c77a"), o, 2.0)
		# sofá
		var sofa := Rect2(w * 0.55, floor_y - 120.0, w * 0.4, 100.0)
		DrawUtil.shape(self, PackedVector2Array([sofa.position, Vector2(sofa.end.x, sofa.position.y), sofa.end, Vector2(sofa.position.x, sofa.end.y)]), Color("6fb0e8"), o, 4.0)
		draw_rect(Rect2(sofa.position.x - 14, sofa.position.y + 30, 28, 72), Color("4f8fc8"), true)
		draw_rect(Rect2(sofa.end.x - 14, sofa.position.y + 30, 28, 72), Color("4f8fc8"), true)
		# vaso de planta
		DrawUtil.shape(self, PackedVector2Array([Vector2(w * 0.47, floor_y - 2), Vector2(w * 0.51, floor_y - 2), Vector2(w * 0.505, floor_y - 40), Vector2(w * 0.475, floor_y - 40)]), Color("e07a5f"), o, 3.0)
		for k in 3:
			DrawUtil.oval(self, Vector2(w * 0.49 + (k - 1) * 12.0, floor_y - 58.0), Vector2(8, 20), Palette.GRASS, o, 2.5, (k - 1) * 0.5)
