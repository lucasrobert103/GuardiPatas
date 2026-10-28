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
	"flores": {"name": "Coroa de Flores", "price": 120},
	"cachecol": {"name": "Cachecol Quentinho", "price": 120},
	"coroa": {"name": "Coroa Dourada", "price": 250},
}

const ACHIEVEMENTS := {
	"first_win": {"name": "Primeiro Abraço", "desc": "Vença a primeira fase."},
	"stars_10": {"name": "Céu Estrelado", "desc": "Junte 10 estrelas."},
	"stars_30": {"name": "Constelação", "desc": "Junte 30 estrelas."},
	"perfect_5": {"name": "Traço Mestre", "desc": "Consiga 3 estrelas em 5 fases."},
	"saver": {"name": "Pouca Tinta, Muito Amor", "desc": "Vença usando até 25% da tinta."},
	"world_1": {"name": "Jardineiro", "desc": "Complete o Jardim dos Bichinhos."},
	"world_2": {"name": "Guardião da Floresta", "desc": "Complete a Floresta Encantada."},
	"friends_6": {"name": "Turma Completa", "desc": "Conheça os seis bichinhos."},
	"stylist": {"name": "Estilista", "desc": "Equipe um acessório."},
	"persistent": {"name": "Nunca Desista", "desc": "Tente de novo 10 vezes."},
}

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
		"stats": {"wins": 0, "losses": 0, "retries": 0, "lines": 0},
		"settings": DEFAULT_SETTINGS.duplicate(),
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
func complete_level(id: String, stars: int, ink_used: float, animals: Array) -> Dictionary:
	var prev := stars_of(id)
	var rec := level_record(id).duplicate()
	rec["stars"] = maxi(prev, stars)
	rec["best_ink"] = minf(float(rec.get("best_ink", 1.0)), ink_used)
	data["levels"][id] = rec
	var gained := Scoring.coins_for(prev, stars)
	data["coins"] = coins() + gained
	data["stats"]["wins"] = int(data["stats"]["wins"]) + 1
	var new_friends: Array = []
	for a in animals:
		if not data["met"].has(a):
			data["met"].append(a)
			new_friends.append(a)
	var unlocked := _check_achievements(stars, ink_used)
	save()
	coins_changed.emit(coins())
	return {"coins": gained, "prev_stars": prev, "new_friends": new_friends, "achievements": unlocked}


func record_loss() -> void:
	data["stats"]["losses"] = int(data["stats"]["losses"]) + 1
	save()


func record_retry() -> void:
	data["stats"]["retries"] = int(data["stats"]["retries"]) + 1
	_check_achievements(0, 1.0)
	save()


func _check_achievements(stars: int, ink_used: float) -> Array:
	var got: Array = []
	var perfect := 0
	for id in data["levels"].keys():
		if int(data["levels"][id].get("stars", 0)) == 3:
			perfect += 1
	var checks := {
		"first_win": int(data["stats"]["wins"]) >= 1,
		"stars_10": total_stars() >= 10,
		"stars_30": total_stars() >= 30,
		"perfect_5": perfect >= 5,
		"saver": stars > 0 and ink_used <= 0.25,
		"world_1": world_completed(1),
		"world_2": world_completed(2),
		"friends_6": data["met"].size() >= 6,
		"stylist": not data["equipped"].is_empty(),
		"persistent": int(data["stats"]["retries"]) >= 10,
	}
	for k in checks.keys():
		if checks[k] and not data["achievements"].has(k):
			data["achievements"].append(k)
			got.append(k)
	return got


# ------------------------------------------------------------------ economia
func coins() -> int:
	return int(data.get("coins", 0))


func hints() -> int:
	return int(data.get("hints", 0))


func use_hint() -> bool:
	if hints() <= 0:
		return false
	data["hints"] = hints() - 1
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
