class_name InfiniteDirector
extends Node
## Prepara as fases do Modo Infinito com antecedência: gera, valida escondido e guarda.
## Se uma variação falhar na validação, tenta outra (até MAX_TRIES); no último caso usa a
## variação mais simples, também validada.

signal prepared(stage: int)

const MAX_TRIES := 6
var ready_levels: Dictionary = {}
var _working := {}


func is_ready(stage: int) -> bool:
	return ready_levels.has(stage)


func take(stage: int) -> Dictionary:
	return ready_levels.get(stage, {})


func prepare(stage: int) -> void:
	if ready_levels.has(stage) or _working.has(stage):
		return
	_working[stage] = true
	for variant in MAX_TRIES:
		var data := Infinite.generate(stage, variant)
		var v := InfiniteValidator.new()
		add_child(v)
		v.check(data)
		var res: Array = await v.done
		v.queue_free()
		if res[1]:
			ready_levels[stage] = data
			_working.erase(stage)
			prepared.emit(stage)
			return
	# todas falharam: fase mais simples (arco contra abelhas), também simulada
	var simple := Infinite.generate(maxi(1, stage % 3), 0)
	simple["stage"] = stage
	simple["name"] = UiKit.tr_text("Infinito · Fase %d") % stage
	simple["id"] = "infinito-%d" % stage
	ready_levels[stage] = simple
	_working.erase(stage)
	prepared.emit(stage)


func clear() -> void:
	ready_levels.clear()
