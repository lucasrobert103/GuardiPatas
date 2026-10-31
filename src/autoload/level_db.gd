extends Node
## Banco de fases: carrega data/levels.json (fases 100% configuráveis por dados).
## Formato documentado em docs/09-arquitetura.md (seção "Formato de fase").

const LEVELS_PATH := "res://data/levels.json"

var worlds: Array = []
var levels: Array = []


func _ready() -> void:
	reload()


func reload(path: String = LEVELS_PATH) -> void:
	worlds.clear()
	levels.clear()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("levels.json não encontrado")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		push_error("levels.json inválido")
		return
	worlds = parsed.get("worlds", [])
	levels = parsed.get("levels", [])


func count() -> int:
	return levels.size()


func get_level(index: int) -> Dictionary:
	if index < 0 or index >= levels.size():
		return {}
	return levels[index]


func index_of(id: String) -> int:
	for i in levels.size():
		if str(levels[i]["id"]) == id:
			return i
	return -1


func world_info(world_id: int) -> Dictionary:
	for w in worlds:
		if int(w["id"]) == world_id:
			return w
	return {"id": world_id, "name": "Mundo %d" % world_id}


func levels_in_world(world_id: int) -> Array:
	var out: Array = []
	for i in levels.size():
		if int(levels[i]["world"]) == world_id:
			out.append(i)
	return out
