extends Node
## Estado global: progresso, moedas, cosméticos, conquistas e configurações.
## Salva tudo localmente em JSON (user://save.json). Nenhum dado sai do aparelho.

signal coins_changed(coins: int)
signal settings_changed
signal hints_changed(hints: int)

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const HINT_PRICE := 40
const START_HINTS := 3

## Cosméticos: apenas visuais, nunca alteram a jogabilidade.
const ITEMS := {
	"bone": {"name": "Boné Listrado", "price": 60},
	"laco": {"name": "Laço de Bolinhas", "price": 60},
	"oculos": {"name": "Óculos de Sol", "price": 90},
	"palha": {"name": "Chapéu de Palha", "price": 90},
	"estrela": {"name": "Presilha Estrela-do-mar", "price": 100},
	"flores": {"name": "Coroa de Flores", "price": 120},
	"cachecol": {"name": "Cachecol Quentinho", "price": 120},
	"touca": {"name": "Touca de Lã", "price": 140},
	"coroa": {"name": "Coroa Dourada", "price": 250},
}

## Conquistas: [id, nome, descrição]. As condições estão em _achievement_checks().
const ACHIEVEMENT_LIST := [
	["first_win", "Primeiro Abraço", "Vença a primeira fase."],
	["wins_10", "Protetor de Plantão", "Vença 10 fases."],
	["wins_50", "Herói do Quintal", "Vença 50 fases."],
	["stars_10", "Céu Estrelado", "Junte 10 estrelas."],
	["stars_30", "Constelação", "Junte 30 estrelas."],
	["stars_60", "Via Láctea", "Junte 60 estrelas."],
	["stars_100", "Chuva de Estrelas", "Junte 100 estrelas."],
	["stars_150", "Universo Fofo", "Junte 150 estrelas."],
	["perfect_5", "Traço Mestre", "Consiga 3 estrelas em 5 fases."],
	["perfect_15", "Mão de Artista", "Consiga 3 estrelas em 15 fases."],
	["perfect_30", "Perfeição Pura", "Consiga 3 estrelas em 30 fases."],
	["saver", "Pouca Tinta, Muito Amor", "Vença usando até 25% da tinta."],
	["super_saver", "Uma Gotinha Só", "Vença usando até 15% da tinta."],
	["world_1", "Jardineiro", "Complete o Jardim dos Bichinhos."],
	["world_2", "Guardião da Floresta", "Complete a Floresta Encantada."],
	["world_3", "Amigo das Formigas", "Complete o Vale das Formigas."],
	["world_4", "Mestre da Lagoa", "Complete a Lagoa Misteriosa."],
	["world_5", "Rei do Acampamento", "Complete o Acampamento no Quintal."],
	["world_6", "Alpinista", "Complete a Montanha Gelada."],
	["world_7", "Rei da Praia", "Complete a Praia do Sol."],
	["world_8", "Explorador dos Mares", "Complete o Fundo do Mar."],
	["queen", "Amiga da Rainha", "Vença a Rainha Zumbina."],
	["owl", "Abraço Quentinho", "Vença a Coruja Nevasca."],
	["crab_king", "Rei da Areia", "Vença o Caranguejo Rei."],
	["octopus", "Oito Braços", "Vença o Polvo Gigante."],
	["all_bosses", "Domador de Chefões", "Vença os quatro chefões."],
	["paws_10", "Caçador de Pegadas", "Pegue 10 pegadas douradas."],
	["paws_30", "Rastro Dourado", "Pegue 30 pegadas douradas."],
	["first_10", "De Primeira!", "Vença 10 fases sem perder nenhuma vez."],
	["quick_10", "Mão Ligeira", "Ganhe 10 medalhas Relâmpago."],
	["triple_10", "Medalha Tripla", "Ganhe as 3 medalhas em 10 fases."],
	["builder_1", "Arquiteto Fofo", "Crie e vença uma fase no editor."],
	["builder_5", "Mestre de Obras", "Crie e vença 5 fases no editor."],
	["photo_1", "Sorria!", "Tire uma foto da vitória."],
	["photo_10", "Fotógrafo da Turma", "Tenha tirado 10 fotos."],
	["pet_20", "Muito Carinho", "Faça carinho nos bichinhos 20 vezes na Casinha."],
	["daily_1", "Desafiante", "Vença um Desafio do Dia."],
	["daily_7", "Semana de Desafios", "Vença 7 Desafios do Dia."],
	["daily_streak_3", "Três Dias Seguidos", "Vença o Desafio do Dia 3 dias seguidos."],
	["daily_streak_7", "Uma Semana Seguida", "Vença o Desafio do Dia 7 dias seguidos."],
	["friends_6", "Turma Reunida", "Conheça 6 bichinhos."],
	["friends_10", "Bando Animado", "Conheça 10 bichinhos."],
	["friends_14", "Turma Completa", "Conheça os 14 bichinhos."],
	["stylist", "Estilista", "Equipe um acessório."],
	["shopper", "Comprinhas", "Tenha 3 acessórios."],
	["wardrobe", "Guarda-roupa Lotado", "Tenha todos os acessórios."],
	["rich", "Cofrinho Cheio", "Tenha 500 moedas de uma vez."],
	["plumber", "Tampa-Buracos", "Tampe 5 buracos de insetos."],
	["delivery", "Entrega Fofa", "Leve bichinhos até a toca 3 vezes."],
	["artist", "Artista Livre", "Vença uma fase no Modo Livre."],
	["hint_1", "Pedindo Ajuda", "Use uma dica."],
	["lines_100", "Rabiscador", "Desenhe 100 linhas."],
	["lines_500", "Mestre do Giz", "Desenhe 500 linhas."],
	["streak_5", "Embalado", "Vença 5 fases seguidas sem perder."],
	["streak_15", "Imparável", "Vença 15 fases seguidas sem perder."],
	["persistent", "Nunca Desista", "Tente de novo 10 vezes."],
	["stubborn", "Teimosia do Bem", "Tente de novo 50 vezes."],
]

const DEFAULT_SETTINGS := {
	"music": 0.6,
	"sfx": 0.9,
	"vibration": true,
	"reduce_motion": false,
	"high_contrast": false,
}

var data: Dictionary = {}
## Testes automatizados desligam a persistência para não tocar no save real.
var persist := true
## Índice da fase atual (usado pela navegação entre telas).
var current_index := 0
## Fases em que a dica já foi paga nesta sessão (recomeçar não cobra de novo).
var hinted := {}
## Pedido de dica vindo da tela de derrota (aplicado ao recomeçar a fase).
var pending_hint := false
## Modo Livre pedido pelo jogador (vale só para fases já vencidas).
var free_mode := false
## Fase fora da campanha em jogo agora (Desafio do Dia / editor); vazio = campanha.
var current_custom: Dictionary = {}
## Mostra a abertura (RetroNexa) só uma vez por execução.
var splash_shown := false


func _ready() -> void:
	load_save()
	apply_settings()


func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"levels": {},
		"coins": 0,
		"hints": START_HINTS,
		"owned": [],
		"equipped": {},
		"met": [],
		"achievements": [],
		"stats": {"wins": 0, "losses": 0, "retries": 0, "lines": 0, "streak": 0, "plugs": 0, "goals": 0, "free_wins": 0, "hints_used": 0, "queen": 0, "owl": 0, "crab_king": 0, "octopus": 0},
		"settings": DEFAULT_SETTINGS.duplicate(),
		"daily": {"last": "", "streak": 0, "best_streak": 0, "done": 0},
		"custom": [],
		"album": [],
	}


func load_save() -> void:
	data = _default_data()
	if not persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		# mescla com os padrões para tolerar saves antigos / campos novos
		for k in parsed.keys():
			if data.has(k) and typeof(data[k]) == TYPE_DICTIONARY and typeof(parsed[k]) == TYPE_DICTIONARY:
				data[k].merge(parsed[k], true)
			elif data.has(k):
				data[k] = parsed[k]


func save() -> void:
	if not persist:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Não foi possível salvar o progresso: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "\t"))


func reset_progress() -> void:
	var keep_settings: Dictionary = data.get("settings", DEFAULT_SETTINGS).duplicate()
	data = _default_data()
	data["settings"] = keep_settings
	save()
	coins_changed.emit(coins())
	hints_changed.emit(hints())


# ------------------------------------------------------------------ progresso
func level_record(id: String) -> Dictionary:
	return data["levels"].get(id, {})


func stars_of(id: String) -> int:
	return int(level_record(id).get("stars", 0))


func is_completed(id: String) -> bool:
	return level_record(id).has("stars")


func is_unlocked(index: int) -> bool:
	if index <= 0:
		return true
	var prev := LevelDB.get_level(index - 1)
	return not prev.is_empty() and is_completed(str(prev["id"]))


func total_stars() -> int:
	var total := 0
	for id in data["levels"].keys():
		total += int(data["levels"][id].get("stars", 0))
	return total


func world_completed(world_id: int) -> bool:
	var any := false
	for i in LevelDB.count():
		var lv := LevelDB.get_level(i)
		if int(lv["world"]) == world_id:
			any = true
			if not is_completed(str(lv["id"])):
				return false
	return any


## Registra vitória. Retorna um resumo para a tela de resultado.
func complete_level(id: String, stars: int, ink_used: float, animals: Array, boss: String = "", medals: Dictionary = {}) -> Dictionary:
	var prev := stars_of(id)
	var rec := level_record(id).duplicate()
	rec["stars"] = maxi(prev, stars)
	rec["best_ink"] = minf(float(rec.get("best_ink", 1.0)), ink_used)
	# medalhas extras: ganhas uma vez, ficam para sempre (+5 moedas cada)
	var new_medals: Array = []
	for m in MEDALS:
		if bool(medals.get(m, false)) and not bool(rec.get(m, false)):
			rec[m] = true
			new_medals.append(m)
	data["levels"][id] = rec
	var gained := Scoring.coins_for(prev, stars) + 5 * new_medals.size()
	data["coins"] = coins() + gained
	data["stats"]["wins"] = int(data["stats"]["wins"]) + 1
	add_stat("streak", 1, false)
	if boss != "":
		add_stat(boss, 1, false)
	var new_friends: Array = []
	for a in animals:
		if not data["met"].has(a):
			data["met"].append(a)
			new_friends.append(a)
	var unlocked := _check_achievements(stars, ink_used)
	save()
	coins_changed.emit(coins())
	return {"coins": gained, "prev_stars": prev, "new_friends": new_friends, "achievements": unlocked, "new_medals": new_medals}


func record_loss(id: String = "") -> void:
	data["stats"]["losses"] = int(data["stats"]["losses"]) + 1
	data["stats"]["streak"] = 0
	if id != "" and LevelDB.index_of(id) >= 0:
		var rec := level_record(id).duplicate()
		rec["fails"] = int(rec.get("fails", 0)) + 1
		data["levels"][id] = rec
	save()


# ------------------------------------------------------------------ medalhas
const MEDALS := ["paw", "first", "quick"]
const MEDAL_INFO := {
	"paw": {"name": "Pegada Dourada", "desc": "Passe a linha pela pegada dourada.", "icon": "gold_paw"},
	"first": {"name": "De Primeira", "desc": "Vença sem perder nenhuma vez.", "icon": "check"},
	"quick": {"name": "Relâmpago", "desc": "Termine o desenho em até 6 segundos.", "icon": "bolt"},
}


func has_medal(id: String, medal: String) -> bool:
	return bool(level_record(id).get(medal, false))


## Fase ainda sem nenhuma derrota registrada (vale para a medalha "De Primeira").
func never_failed(id: String) -> bool:
	return int(level_record(id).get("fails", 0)) == 0


func medal_count(medal: String) -> int:
	var n := 0
	for id in data["levels"].keys():
		if bool(data["levels"][id].get(medal, false)):
			n += 1
	return n


func triple_medal_count() -> int:
	var n := 0
	for id in data["levels"].keys():
		var rec: Dictionary = data["levels"][id]
		if MEDALS.all(func(m): return bool(rec.get(m, false))):
			n += 1
	return n


# ------------------------------------------------------------------ álbum de fotos
const ALBUM_DIR := "user://album"
const ALBUM_MAX := 40


## Guarda a foto da vitória (PNG no aparelho) e o que aconteceu nela. As mais antigas saem
## quando passa de ALBUM_MAX.
func add_photo(img: Image, caption: String) -> Dictionary:
	if img == null or img.is_empty():
		return {}
	DirAccess.make_dir_recursive_absolute(ALBUM_DIR)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var file := "%s/%s_%d.png" % [ALBUM_DIR, stamp, randi() % 1000]
	var w := img.get_width()
	if w > 540:
		img.resize(540, int(img.get_height() * 540.0 / w), Image.INTERPOLATE_BILINEAR)
	img.save_png(file)
	var entry := {"file": file, "caption": caption, "date": Time.get_date_string_from_system()}
	var album: Array = data["album"]
	album.append(entry)
	while album.size() > ALBUM_MAX:
		var old: Dictionary = album.pop_front()
		DirAccess.remove_absolute(str(old.get("file", "")))
	add_stat("photos", 1, false)
	var got := _check_achievements(0, 1.0)
	save()
	return {"entry": entry, "achievements": got}


func remove_photo(i: int) -> void:
	var album: Array = data["album"]
	if i < 0 or i >= album.size():
		return
	var old: Dictionary = album[i]
	album.remove_at(i)
	DirAccess.remove_absolute(str(old.get("file", "")))
	save()


# ------------------------------------------------------------------ fases do editor
const CUSTOM_MAX := 12


func custom_levels() -> Array:
	return data["custom"]


func save_custom(i: int, draft: Dictionary) -> int:
	var list: Array = data["custom"]
	if i >= 0 and i < list.size():
		list[i] = draft
	else:
		list.append(draft)
		i = list.size() - 1
	save()
	return i


func delete_custom(i: int) -> void:
	var list: Array = data["custom"]
	if i >= 0 and i < list.size():
		list.remove_at(i)
		save()


## A fase do editor foi vencida pelo próprio autor: ganha o selo "testada".
func verify_custom(i: int) -> Array:
	var list: Array = data["custom"]
	if i < 0 or i >= list.size():
		return []
	var first := not bool(list[i].get("verified", false))
	list[i]["verified"] = true
	if first:
		add_stat("custom_verified", 1, false)
	var got := _check_achievements(0, 1.0)
	save()
	return got


# ------------------------------------------------------------------ desafio do dia
func daily_done_today(key: String) -> bool:
	return str(data["daily"].get("last", "")) == key


## Registra o desafio do dia vencido. Só o primeiro do dia dá prêmio e conta na sequência.
func complete_daily(key: String) -> Dictionary:
	var d: Dictionary = data["daily"]
	if str(d.get("last", "")) == key:
		return {"daily": true, "coins": 0, "repeat": true, "streak": int(d.get("streak", 0)), "achievements": []}
	var streak := int(d.get("streak", 0)) + 1 if str(d.get("last", "")) == Daily.previous_key(key) else 1
	d["last"] = key
	d["streak"] = streak
	d["best_streak"] = maxi(int(d.get("best_streak", 0)), streak)
	d["done"] = int(d.get("done", 0)) + 1
	var gained := Daily.reward(streak)
	data["coins"] = coins() + gained
	data["stats"]["wins"] = int(data["stats"]["wins"]) + 1
	var got := _check_achievements(0, 1.0)
	save()
	coins_changed.emit(coins())
	return {"daily": true, "coins": gained, "repeat": false, "streak": streak, "achievements": got}


func record_free_win() -> Array:
	add_stat("free_wins", 1, false)
	var got := _check_achievements(0, 1.0)
	save()
	return got


func stat(key: String) -> int:
	return int(data["stats"].get(key, 0))


## Soma em uma estatística (ex.: buracos tampados) e confere conquistas.
func add_stat(key: String, amount: int, check: bool = true) -> void:
	data["stats"][key] = stat(key) + amount
	if check:
		_check_achievements(0, 1.0)


func record_retry() -> void:
	data["stats"]["retries"] = int(data["stats"]["retries"]) + 1
	_check_achievements(0, 1.0)
	save()


func _check_achievements(stars: int, ink_used: float) -> Array:
	var got: Array = []
	var checks := _achievement_checks(stars, ink_used)
	for k in checks.keys():
		if checks[k] and not data["achievements"].has(k):
			data["achievements"].append(k)
			got.append(k)
	return got


func _achievement_checks(stars: int, ink_used: float) -> Dictionary:
	var perfect := 0
	for id in data["levels"].keys():
		if int(data["levels"][id].get("stars", 0)) == 3:
			perfect += 1
	var ts := total_stars()
	var wins := stat("wins")
	var met: int = data["met"].size()
	var c := {
		"first_win": wins >= 1, "wins_10": wins >= 10, "wins_50": wins >= 50,
		"stars_10": ts >= 10, "stars_30": ts >= 30, "stars_60": ts >= 60, "stars_100": ts >= 100, "stars_150": ts >= 150,
		"perfect_5": perfect >= 5, "perfect_15": perfect >= 15, "perfect_30": perfect >= 30,
		"saver": stars > 0 and ink_used <= 0.25, "super_saver": stars > 0 and ink_used <= 0.15,
		"queen": stat("queen") >= 1,
		"owl": stat("owl") >= 1, "crab_king": stat("crab_king") >= 1, "octopus": stat("octopus") >= 1,
		"all_bosses": stat("queen") >= 1 and stat("owl") >= 1 and stat("crab_king") >= 1 and stat("octopus") >= 1,
		"friends_6": met >= 6, "friends_10": met >= 10, "friends_14": met >= 14,
		"stylist": not data["equipped"].is_empty(),
		"shopper": data["owned"].size() >= 3, "wardrobe": data["owned"].size() >= ITEMS.size(),
		"rich": coins() >= 500,
		"plumber": stat("plugs") >= 5, "delivery": stat("goals") >= 3, "artist": stat("free_wins") >= 1,
		"hint_1": stat("hints_used") >= 1,
		"lines_100": stat("lines") >= 100, "lines_500": stat("lines") >= 500,
		"streak_5": stat("streak") >= 5, "streak_15": stat("streak") >= 15,
		"persistent": stat("retries") >= 10, "stubborn": stat("retries") >= 50,
		"paws_10": medal_count("paw") >= 10, "paws_30": medal_count("paw") >= 30,
		"first_10": medal_count("first") >= 10, "quick_10": medal_count("quick") >= 10,
		"triple_10": triple_medal_count() >= 10,
		"builder_1": stat("custom_verified") >= 1, "builder_5": stat("custom_verified") >= 5,
		"photo_1": stat("photos") >= 1, "photo_10": stat("photos") >= 10, "pet_20": stat("pets") >= 20,
		"daily_1": int(data["daily"].get("done", 0)) >= 1, "daily_7": int(data["daily"].get("done", 0)) >= 7,
		"daily_streak_3": int(data["daily"].get("best_streak", 0)) >= 3,
		"daily_streak_7": int(data["daily"].get("best_streak", 0)) >= 7,
	}
	for w in range(1, 9):
		c["world_%d" % w] = world_completed(w)
	return c


func achievement_info(id: String) -> Dictionary:
	for a in ACHIEVEMENT_LIST:
		if a[0] == id:
			return {"name": a[1], "desc": a[2]}
	return {"name": id, "desc": ""}


# ------------------------------------------------------------------ economia
func coins() -> int:
	return int(data.get("coins", 0))


func hints() -> int:
	return int(data.get("hints", 0))


func use_hint() -> bool:
	if hints() <= 0:
		return false
	data["hints"] = hints() - 1
	add_stat("hints_used", 1)
	save()
	hints_changed.emit(hints())
	return true


func buy_hint() -> bool:
	if coins() < HINT_PRICE:
		return false
	data["coins"] = coins() - HINT_PRICE
	data["hints"] = hints() + 1
	save()
	coins_changed.emit(coins())
	hints_changed.emit(hints())
	return true


func owns(item: String) -> bool:
	return data["owned"].has(item)


func buy_item(item: String) -> bool:
	if not ITEMS.has(item) or owns(item):
		return false
	var price: int = ITEMS[item]["price"]
	if coins() < price:
		return false
	data["coins"] = coins() - price
	data["owned"].append(item)
	save()
	coins_changed.emit(coins())
	return true


func equipped(animal: String) -> String:
	return str(data["equipped"].get(animal, ""))


func equip(animal: String, item: String) -> void:
	if item == "" or item == equipped(animal):
		data["equipped"].erase(animal)
	elif owns(item):
		data["equipped"][animal] = item
	_check_achievements(0, 1.0)
	save()


func has_met(animal: String) -> bool:
	return data["met"].has(animal)


# ------------------------------------------------------------------ configurações
func setting(key: String) -> Variant:
	return data["settings"].get(key, DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	apply_settings()
	save()
	settings_changed.emit()


func apply_settings() -> void:
	Sfx.set_volumes(float(setting("music")), float(setting("sfx")))
