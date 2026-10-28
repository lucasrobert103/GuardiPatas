class_name DailyScreen
extends Control
## Desafio do Dia: mostra a regra de hoje, o prêmio, a sequência de dias e quanto falta
## para o próximo desafio.

signal go(screen: String, arg: Variant)

var _data: Dictionary
var _countdown: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_data = Daily.today()
	var bg := MenuBg.new()
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var box := UiKit.vbox(18)
	panel.add_child(box)
	var head := UiKit.hbox(10)
	var cal := UiIcon.new()
	cal.icon = "calendar"
	cal.custom_minimum_size = Vector2(70, 70)
	head.add_child(cal)
	head.add_child(UiKit.label("Desafio do Dia", 48))
	box.add_child(head)
	var d := Time.get_date_dict_from_system()
	box.add_child(UiKit.label("%02d/%02d/%04d" % [d["day"], d["month"], d["year"]], 26, Color(Palette.UI_TEXT, 0.7)))

	var mod := Daily.mod_info(str(_data["daily_mod"]))
	var card := UiKit.panel(Palette.world(int(_data.get("world", 1)))["sky_bottom"])
	box.add_child(card)
	var cbox := UiKit.vbox(10)
	card.add_child(cbox)
	var mrow := UiKit.hbox(12)
	var mi := UiIcon.new()
	mi.icon = mod["icon"]
	mi.custom_minimum_size = Vector2(80, 80)
	mrow.add_child(mi)
	var mtext := UiKit.vbox(2)
	mtext.add_child(UiKit.label(mod["name"], 40, Palette.UI_PRIMARY))
	var desc := UiKit.label(mod["desc"], 24, Palette.UI_TEXT, 0, Palette.WHITE, true)
	desc.custom_minimum_size = Vector2(400, 0)
	mtext.add_child(desc)
	mrow.add_child(mtext)
	cbox.add_child(mrow)
	UiKit.pop_in(mi, 0.2)
	cbox.add_child(UiKit.label("Fase %s · %s" % [_data["base_id"], _data["base_name"]], 26))
	var animals := UiKit.hbox(4)
	animals.alignment = BoxContainer.ALIGNMENT_CENTER
	for a in _data.get("animals", []):
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(110, 110)
		var art := AnimalArt.new()
		art.species = str(a["type"])
		art.preview = true
		art.mood = "scared"
		art.position = Vector2(55, 70)
		art.scale = Vector2(0.8, 0.8)
		holder.add_child(art)
		animals.add_child(holder)
	cbox.add_child(animals)

	var key := str(_data["daily_key"])
	var done := Game.daily_done_today(key)
	var streak := int(Game.data["daily"].get("streak", 0))
	var alive := done or str(Game.data["daily"].get("last", "")) == Daily.previous_key(key)
	var srow := UiKit.hbox(8)
	var fi := UiIcon.new()
	fi.icon = "flame"
	fi.custom_minimum_size = Vector2(48, 48)
	fi.modulate = Color.WHITE if alive and streak > 0 else Color(1, 1, 1, 0.3)
	srow.add_child(fi)
	var shown := streak if alive else 0
	srow.add_child(UiKit.label("Sequência: %d %s" % [shown, "dia" if shown == 1 else "dias"], 28))
	box.add_child(srow)
	if done:
		var ok := UiKit.hbox(8)
		var ci := UiIcon.new()
		ci.icon = "check"
		ci.color = Palette.UI_GOOD
		ci.custom_minimum_size = Vector2(44, 44)
		ok.add_child(ci)
		ok.add_child(UiKit.label("Feito hoje! Jogue de novo só por diversão.", 24, Palette.UI_GOOD))
		box.add_child(ok)
	else:
		var prize := UiKit.hbox(8)
		var coin := UiIcon.new()
		coin.icon = "coin"
		coin.custom_minimum_size = Vector2(44, 44)
		prize.add_child(coin)
		prize.add_child(UiKit.label("Prêmio: +%d moedas" % Daily.reward(streak + 1 if alive else 1), 28))
		box.add_child(prize)
	_countdown = UiKit.label("", 22, Color(Palette.UI_TEXT, 0.7))
	box.add_child(_countdown)

	var row := UiKit.hbox(16)
	box.add_child(row)
	var back := UiKit.icon_button("back", Palette.UI_PANEL, 96)
	back.pressed.connect(func(): go.emit("title", null))
	row.add_child(back)
	var play := UiKit.button("Jogar" if not done else "Jogar de novo", Palette.UI_GOOD, "play", 340, 96)
	play.pressed.connect(func(): go.emit("level", _data))
	row.add_child(play)
	UiKit.pop_in(panel)
	Sfx.music("music_menu")


func _process(_delta: float) -> void:
	var t := Time.get_time_dict_from_system()
	var left := 86400 - (int(t["hour"]) * 3600 + int(t["minute"]) * 60 + int(t["second"]))
	_countdown.text = "Novo desafio em %02d:%02d:%02d" % [left / 3600, (left / 60) % 60, left % 60]
