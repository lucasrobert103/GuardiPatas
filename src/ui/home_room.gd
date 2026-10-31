class_name HomeRoom
extends Control
## Cenário ilustrado que se reorganiza a partir da área útil da tela.
var home: HomeScreen
var clock := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if not bool(Game.setting("reduce_motion")):
		clock += delta
	queue_redraw()


func _draw() -> void:
	if home == null or home._stage.size.y <= 0:
		return
	var stage := home._stage
	var floor_y := stage.position.y + stage.size.y * 0.48
	var colors: Array = {
		"play": [Color("fbefdf"), Color("ead1b9")],
		"food": [Color("edf4e9"), Color("dfd3bc")],
		"bath": [Color("e9f5f4"), Color("ccdfe0")],
		"sleep": [Color("f0eaf4"), Color("d7c9d9")],
		"clothes": [Color("f6e9ee"), Color("e4ced0")],
	}[home._mode]
	var night := home._mode == "sleep" and bool(PetCare.state(home._selected).get("sleeping", false))
	if night:
		colors = [Color("85849e"), Color("aaa0b8")]
	DrawUtil.vgradient(self, Rect2(0, 0, size.x, floor_y), colors[0].lightened(0.05), colors[0])
	if home._mode == "bath":
		for x in range(0, int(size.x), 84):
			draw_line(Vector2(x, 0), Vector2(x, floor_y), Color("d5e9e6"), 2, true)
		for y in range(0, int(floor_y), 84):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color("d5e9e6"), 2, true)
	else:
		for x in range(0, int(size.x), 60):
			draw_rect(Rect2(x, 0, 24, floor_y), Color(1, 1, 1, 0.09))
	DrawUtil.vgradient(self, Rect2(0, floor_y, size.x, size.y - floor_y), colors[1], colors[1].lightened(0.13))
	HomeArt.box(self, Rect2(0, floor_y - 12, size.x, 20), colors[0].lightened(0.14), 0)
	for i in range(1, 10):
		var y := floor_y + i * (size.y - floor_y) / 9
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.6, 0.43, 0.36, 0.07), 2, true)
	var prop_scale := minf(stage.size.x / 720, stage.size.y / 570)
	var window := Rect2(stage.position + Vector2(stage.size.x * 0.07, 22), Vector2(180, 205) * prop_scale)
	_window(window, night)
	var floor := home._hero_floor()
	var center := Vector2(stage.get_center().x, floor)
	match home._mode:
		"play":
			_couch(Rect2(stage.end.x - 280 * prop_scale, floor_y - 100 * prop_scale, 250 * prop_scale, 112 * prop_scale))
			_plant(Vector2(stage.position.x + 58 * prop_scale, floor_y + 12), prop_scale)
			_rug(center + Vector2(0, 40), Vector2(stage.size.x * 0.4, minf(112, stage.size.y * 0.2)), Color("c3d7c6"))
			var picture := Rect2(stage.get_center().x + 8, stage.position.y + 30, 94 * prop_scale, 116 * prop_scale)
			HomeArt.box(self, picture.grow(5), Color("debd9f"), 24)
			HomeArt.box(self, picture, Color("fffaf2"), 20)
			HomeArt.heart(self, picture.get_center(), prop_scale * 1.4, Color("e6b5bd"))
		"food":
			var cabinet := Rect2(stage.position.x + 20, floor_y - 108 * prop_scale, stage.size.x * 0.48, 120 * prop_scale)
			HomeArt.box(self, cabinet, Color("a9c8b4"), 18)
			HomeArt.box(self, Rect2(cabinet.position - Vector2(6, 6), Vector2(cabinet.size.x + 12, 18)), Color("f7e2c5"), 8)
			for i in 3:
				var x := cabinet.position.x + cabinet.size.x * (i + 0.5) / 3
				draw_line(Vector2(x, cabinet.position.y + 30), Vector2(x, cabinet.end.y - 12), Color("8dac99"), 2, true)
				HomeArt.oval(self, Vector2(x + 18, cabinet.position.y + 36), Vector2(4, 6), Color("f7e8c9"))
			var fridge := Rect2(stage.end.x - 150 * prop_scale, floor_y - 230 * prop_scale, 126 * prop_scale, 244 * prop_scale)
			HomeArt.box(self, fridge, Color("e5b5b3"), 30 * prop_scale)
			HomeArt.box(self, Rect2(fridge.position + Vector2(10, 10), fridge.size - Vector2(20, 20)), Color("f3d8cb"), 24 * prop_scale)
			draw_line(Vector2(fridge.position.x + 10, fridge.position.y + fridge.size.y * 0.35), Vector2(fridge.end.x - 10, fridge.position.y + fridge.size.y * 0.35), Color("d6aeaa"), 2)
			HomeArt.heart(self, fridge.get_center(), prop_scale * 0.8, Color("d9a2ae"))
			_rug(center + Vector2(0, 30), Vector2(stage.size.x * 0.35, 75 * prop_scale), Color("f0d9ac"))
		"bath":
			var tub := Rect2(center - Vector2(minf(stage.size.x * 0.3, 215), 61), Vector2(minf(stage.size.x * 0.6, 430), 118))
			HomeArt.shadow(self, center + Vector2(0, 57), tub.size.x * 0.52)
			HomeArt.box(self, tub, Color("fdfdf4"), 48)
			HomeArt.oval(self, tub.get_center() - Vector2(0, 37), Vector2(tub.size.x / 2, 44), Color("b6dfe1"))
			HomeArt.oval(self, tub.get_center() - Vector2(0, 34), Vector2(tub.size.x / 2 - 14, 30), Color("d2eef0"))
			HomeArt.object(self, "towel", Rect2(stage.position.x + 25, floor_y - 100 * prop_scale, 90 * prop_scale, 100 * prop_scale))
		"sleep":
			var bed := Rect2(center - Vector2(minf(stage.size.x * 0.31, 215), 40), Vector2(minf(stage.size.x * 0.62, 430), 112))
			HomeArt.shadow(self, center + Vector2(0, 78), bed.size.x * 0.52)
			HomeArt.box(self, Rect2(bed.position - Vector2(10, 80), Vector2(64, 177)), Color("c6a98f"), 28)
			HomeArt.box(self, bed.grow(8), Color("d7bba4"), 32)
			HomeArt.box(self, bed, Color("fff6e6"), 30)
			HomeArt.box(self, Rect2(bed.position + Vector2(18, 12), Vector2(110, 72)), Color("fffdf6"), 28)
			for i in 7:
				var p := stage.position + Vector2(stage.size.x * (0.42 + (i % 4) * 0.13), stage.size.y * (0.06 + (i / 4) * 0.15))
				HomeArt.star(self, p, 6 + i % 3 * 3, Color("f7e2ad") if night else Color("d5c4dc"))
		"clothes":
			var wardrobe := Rect2(stage.position.x + 16, floor_y - 220 * prop_scale, 170 * prop_scale, 244 * prop_scale)
			HomeArt.shadow(self, Vector2(wardrobe.get_center().x, wardrobe.end.y + 8), wardrobe.size.x * 0.52)
			HomeArt.box(self, wardrobe, Color("b9a5c6"), 36 * prop_scale)
			HomeArt.box(self, wardrobe.grow(-10 * prop_scale), Color("dfd1e5"), 30 * prop_scale)
			draw_line(Vector2(wardrobe.get_center().x, wardrobe.position.y + 20), Vector2(wardrobe.get_center().x, wardrobe.end.y - 16), Color("c1adc9"), 2)
			for side in [-1, 1]:
				HomeArt.oval(self, wardrobe.get_center() + Vector2(side * 10, 10), Vector2(4, 7), Color("edcf9d"))
			var mirror := Rect2(stage.end.x - 148 * prop_scale, floor_y - 220 * prop_scale, 120 * prop_scale, 225 * prop_scale)
			HomeArt.box(self, mirror.grow(7), Color("c9b395"), 54 * prop_scale)
			HomeArt.box(self, mirror, Color("d0e0df"), 50 * prop_scale)
			draw_line(mirror.position + mirror.size * Vector2(0.3, 0.25), mirror.position + mirror.size * Vector2(0.7, 0.5), Color("ffffff60"), 9 * prop_scale, true)
			_rug(center + Vector2(0, 32), Vector2(stage.size.x * 0.3, 65 * prop_scale), Color("e4bcc4"))


func _window(rect: Rect2, night: bool) -> void:
	HomeArt.box(self, rect.grow(7), Color("d7c4ae"), rect.size.x * 0.48)
	HomeArt.box(self, rect, Color("c1dbde") if not night else Color("646b93"), rect.size.x * 0.45)
	var center := rect.get_center()
	if night:
		HomeArt.object(self, "energy", Rect2(center - Vector2(35, 45), Vector2(70, 70)))
	else:
		var cloud_scale := rect.size.x / 180.0
		var cloud := center + Vector2(sin(clock * 0.2) * 9, -20) * cloud_scale
		HomeArt.oval(self, cloud, Vector2(47, 13) * cloud_scale, Color("f8faf0"))
		HomeArt.oval(self, cloud + Vector2(-12, -8) * cloud_scale, Vector2(22, 16) * cloud_scale, Color("f8faf0"))
	HomeArt.box(self, Rect2(rect.position.x - 15, rect.end.y - 9, rect.size.x + 30, 19), Color("f8efdf"), 8)
	draw_line(Vector2(center.x, rect.position.y + rect.size.y * 0.1), Vector2(center.x, rect.end.y - 9), Color("f7efdf"), 6, true)


func _couch(rect: Rect2) -> void:
	HomeArt.shadow(self, Vector2(rect.get_center().x, rect.end.y + 10), rect.size.x * 0.5)
	HomeArt.box(self, rect, Color("a6c3ba"), 30)
	HomeArt.box(self, Rect2(rect.position + Vector2(15, 15), Vector2(rect.size.x - 30, rect.size.y * 0.5)), Color("c5d9cb"), 22)
	HomeArt.box(self, Rect2(rect.position.x - 8, rect.position.y + 36, 35, rect.size.y - 26), Color("b5cfc0"), 15)
	HomeArt.box(self, Rect2(rect.end.x - 27, rect.position.y + 36, 35, rect.size.y - 26), Color("b5cfc0"), 15)
	HomeArt.box(self, Rect2(rect.get_center().x - 16, rect.position.y + 20, 52, 36), Color("edc1be"), 12)


func _plant(point: Vector2, scale_factor: float) -> void:
	HomeArt.box(self, Rect2(point + Vector2(-24, -41) * scale_factor, Vector2(48, 48) * scale_factor), Color("dfb5a0"), 14)
	for i in 5:
		var leaf := point + Vector2(sin(i * 2.4) * 22, -58 - (i % 2) * 24) * scale_factor
		draw_line(point - Vector2(0, 35) * scale_factor, leaf, Color("8ba58a"), 3, true)
		HomeArt.oval(self, leaf, Vector2(10, 22) * scale_factor, Color("9fbc95"))


func _rug(center: Vector2, radius: Vector2, color: Color) -> void:
	HomeArt.oval(self, center + Vector2(0, 9), radius + Vector2(7, 1), Color("8e786f14"))
	HomeArt.oval(self, center, radius, color)
	HomeArt.oval(self, center, radius - Vector2(12, 10), color.lightened(0.07))
	draw_polyline(DrawUtil.closed(DrawUtil.ellipse(center, radius - Vector2(17, 12))), Color(1, 1, 1, 0.16), 2, true)
