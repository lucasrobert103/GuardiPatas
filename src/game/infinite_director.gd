class_name InfiniteDirector
extends Node
## Prepara as fases do Modo Infinito na tela de carregamento: gera, simula escondido (em
## silêncio e com a física acelerada) e entrega. Se uma variação falhar, tenta outra (até
## MAX_TRIES); no último caso usa a variação mais simples.
## Nada roda escondido enquanto o jogador está jogando: a fase só começa depois de pronta.

signal prepared(stage: int)

const MAX_TRIES := 6
## Quantas vezes mais rápido a física roda enquanto prepara (mesmo passo de 1/60 s: o
## resultado é idêntico ao do jogo, só termina antes).
const SPEED := 8
var ready_levels: Dictionary = {}
var _working := {}
var _validator: InfiniteValidator
var _variant := 0
var _shown := 0.0
var _boosted := false
var _saved := {}
var _gen := 0


func is_ready(stage: int) -> bool:
	return ready_levels.has(stage)


func is_working() -> bool:
	return not _working.is_empty()


func take(stage: int) -> Dictionary:
	return ready_levels.get(stage, {})


## 0..1 para a barra de carregamento (só avança).
func progress(stage: int) -> float:
	if ready_levels.has(stage):
		return 1.0
	if not _working.has(stage):
		return _shown
	var f := 0.0
	if _validator != null and is_instance_valid(_validator):
		f = _validator.fraction()
	var target := 0.06 + 0.9 * (1.0 - pow(0.45, _variant)) + 0.9 * pow(0.45, _variant) * 0.55 * f
	_shown = maxf(_shown, minf(target, 0.97))
	return _shown


func prepare(stage: int) -> void:
	if ready_levels.has(stage) or _working.has(stage):
		return
	halt()   # uma fase de cada vez
	var gen := _gen
	_working[stage] = true
	_shown = 0.0
	_boost(true)
	for variant in MAX_TRIES:
		_variant = variant
		var data := Infinite.generate(stage, variant)
		_validator = InfiniteValidator.new()
		add_child(_validator)
		_validator.check(data)
		var v := _validator
		var res: Array = await v.done
		if gen != _gen:
			return   # cancelada (saiu da tela ou começou outra)
		v.queue_free()
		_validator = null
		if res[1]:
			_finish(stage, data)
			return
	# todas falharam: fase mais simples (arco contra abelhas), também já testada pelo molde
	var simple := Infinite.generate(maxi(1, stage % 3), 0)
	simple["stage"] = stage
	simple["name"] = UiKit.tr_text("Infinito · Fase %d") % stage
	simple["id"] = "infinito-%d" % stage
	_finish(stage, simple)


func _finish(stage: int, data: Dictionary) -> void:
	ready_levels[stage] = data
	_working.erase(stage)
	if _working.is_empty():
		_boost(false)
	_shown = 1.0
	prepared.emit(stage)


func _boost(on: bool) -> void:
	if on == _boosted:
		return
	_boosted = on
	if on:
		Sfx.quiet += 1
		_saved = {"scale": Engine.time_scale, "ticks": Engine.physics_ticks_per_second, "steps": Engine.max_physics_steps_per_frame}
		Engine.time_scale = float(_saved["scale"]) * SPEED
		Engine.physics_ticks_per_second = int(_saved["ticks"]) * SPEED
		Engine.max_physics_steps_per_frame = maxi(int(_saved["steps"]), SPEED * 2)
	else:
		Sfx.quiet = maxi(0, Sfx.quiet - 1)
		Engine.time_scale = float(_saved.get("scale", 1.0))
		Engine.physics_ticks_per_second = int(_saved.get("ticks", 60))
		Engine.max_physics_steps_per_frame = int(_saved.get("steps", 8))


## Cancela qualquer preparação em andamento e devolve a física ao normal.
func halt() -> void:
	_gen += 1
	_working.clear()
	if _validator != null and is_instance_valid(_validator):
		_validator.queue_free()
	_validator = null
	_boost(false)


func _exit_tree() -> void:
	_boost(false)


func clear() -> void:
	ready_levels.clear()
