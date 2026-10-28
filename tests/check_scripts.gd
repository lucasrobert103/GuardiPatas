extends Node
## Compila todos os scripts do projeto e falha se algum tiver erro.
##   godot --headless --path . res://tests/check_scripts.tscn


func _ready() -> void:
	var bad := 0
	var files := _collect("res://src") + _collect("res://tests")
	for f in files:
		var s: GDScript = load(f)
		if s == null or not s.can_instantiate():
			print("ERRO ao compilar: ", f)
			bad += 1
	print("%d scripts verificados, %d com erro" % [files.size(), bad])
	get_tree().quit(1 if bad > 0 else 0)


func _collect(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_collect(dir.path_join(d)))
	return out
