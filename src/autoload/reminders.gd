extends Node
## Recados dos bichinhos: notificações LOCAIS agendadas no próprio aparelho (sem internet,
## sem servidor, sem coletar dados). Pedidos de ajuda dos bichinhos, Desafio do Dia, Casinha,
## progresso, Modo Infinito e Ateliê, com o texto montado a partir do progresso do jogador.
##
## Usa o plugin Android "NotificationSchedulerPlugin" (godot-notification-scheduler) quando ele
## está no APK; sem o plugin (computador, testes, APK sem ele) tudo continua funcionando e os
## lembretes ficam desligados.
##
## Regras: só depois de aceitar os termos e de o Android permitir notificações; nunca à noite
## (9h30 às 20h); a primeira só 2 horas depois da última vez que o jogo foi aberto; sem
## propaganda nem convite para comprar; o jogador escolhe a frequência (ou desliga) nos Ajustes.

signal permission_changed(granted: bool)

const SINGLETON := "NotificationSchedulerPlugin"
const CHANNEL := "bichinhos"
const ICON := "ic_default_notification"
const BASE_ID := 7000
const MAX_IDS := 40
const DAYS := 3
## Recados por dia para cada opção dos Ajustes (índice salvo em settings.reminders).
const FREQUENCIES := [0, 1, 3, 5]
const OPTION_NAMES := ["Desligados", "1 por dia", "3 por dia", "5 por dia"]
const WINDOW_START := 9.5
const WINDOW_END := 20.0
const MIN_DELAY := 2 * 3600

var _plugin: Object
var _initialized := false


func _ready() -> void:
	if Engine.has_singleton(SINGLETON):
		_plugin = Engine.get_singleton(SINGLETON)
		_plugin.connect("initialization_completed", _on_initialized)
		_plugin.connect("post_notifications_permission_granted", func(_p): _on_permission(true))
		_plugin.connect("post_notifications_permission_denied", func(_p): _on_permission(false))
		_plugin.initialize()
	Game.settings_changed.connect(reschedule)


## O plugin de notificações está neste APK?
func available() -> bool:
	return _plugin != null


func has_permission() -> bool:
	return available() and bool(_plugin.has_post_notifications_permission())


func request_permission() -> void:
	if available():
		_plugin.request_post_notifications_permission()


func open_system_settings() -> void:
	if available():
		_plugin.open_app_info_settings()


func per_day() -> int:
	return FREQUENCIES[clampi(int(Game.setting("reminders")), 0, FREQUENCIES.size() - 1)]


## Mostrar o convite na tela inicial? (uma vez, depois de algumas fases vencidas)
func should_ask() -> bool:
	return available() and not has_permission() and per_day() > 0 and Legal.accepted() \
		and not bool(Game.data.get("reminders", {}).get("asked", false)) and Game.completed_count() >= 3


func mark_asked() -> void:
	if not Game.data.get("reminders") is Dictionary:
		Game.data["reminders"] = {}
	Game.data["reminders"]["asked"] = true
	Game.save()


func _on_initialized() -> void:
	_initialized = true
	_plugin.create_notification_channel({
		"channel_id": CHANNEL,
		"channel_name": UiKit.tr_text("Recados dos bichinhos"),
		"channel_description": UiKit.tr_text("Os bichinhos pedem ajuda e lembram do Desafio do Dia e da Casinha."),
		"channel_importance": 3,
		"badge_enabled": true,
	})
	reschedule()


func _on_permission(granted: bool) -> void:
	permission_changed.emit(granted)
	reschedule()


func _notification(what: int) -> void:
	# ao sair do jogo, os próximos recados são montados com o progresso mais recente
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		reschedule()


## Cancela os recados agendados e agenda os próximos dias de novo.
func reschedule() -> void:
	if not available() or not _initialized:
		return
	for i in MAX_IDS:
		_plugin.cancel(BASE_ID + i)
	if per_day() == 0 or not Legal.accepted() or not has_permission():
		return
	var plan := make_plan(Time.get_datetime_dict_from_system(false), per_day(), randi(), messages())
	for i in plan.size():
		var item: Dictionary = plan[i]
		_plugin.schedule({
			"notification_id": BASE_ID + i,
			"channel_id": CHANNEL,
			"title": item["title"],
			"content": item["content"],
			"small_icon_name": ICON,
			"delay": int(item["delay"]),
		})


## Horários e textos dos próximos DAYS dias. Função pura (testada no computador).
## `now` é o horário LOCAL (Time.get_datetime_dict_from_system(false)).
static func make_plan(now: Dictionary, count_per_day: int, seed_value: int, pool: Array) -> Array:
	var out: Array = []
	if count_per_day <= 0 or pool.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var now_sec := int(now.get("hour", 12)) * 3600 + int(now.get("minute", 0)) * 60 + int(now.get("second", 0))
	var order := range(pool.size())
	_shuffle(order, rng)
	var k := 0
	var span := (WINDOW_END - WINDOW_START) / count_per_day
	for day in DAYS:
		for slot in count_per_day:
			var hour := WINDOW_START + span * (slot + rng.randf_range(0.15, 0.85))
			var delay := day * 86400 + int(hour * 3600.0) - now_sec
			if delay < MIN_DELAY:
				continue
			if k >= order.size():
				_shuffle(order, rng)
				k = 0
			var msg: Array = pool[order[k]]
			k += 1
			out.append({"delay": delay, "title": msg[0], "content": msg[1]})
			if out.size() >= MAX_IDS:
				return out
	return out


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


## Recados possíveis agora, já traduzidos e com o nome dos bichinhos e o progresso.
static func messages() -> Array:
	var tr_ := func(s: String) -> String: return UiKit.tr_text(s)
	var pets: Array = []
	for sp in Game.data.get("met", []):
		if Animal.SPECIES.has(sp):
			pets.append(str(Animal.SPECIES[sp]["name"]))
	if pets.is_empty():
		pets = ["Capitu"]
	var pet := func(i: int) -> String: return pets[i % pets.size()]
	var out: Array = []
	# pedidos de ajuda
	out.append([tr_.call("%s precisa de ajuda!") % pet.call(0), tr_.call("Tem abelhas rondando a toca. Vem desenhar um abrigo?")])
	out.append([tr_.call("Socorro!"), tr_.call("%s está cercado de insetos. Só você pode proteger!") % pet.call(1)])
	out.append([tr_.call("%s está te chamando") % pet.call(2), tr_.call("Bora jogar mais uma fase juntos?")])
	out.append([tr_.call("Zum zum zum…"), tr_.call("As vespas voltaram! %s conta com você.") % pet.call(3)])
	out.append([tr_.call("%s sentiu saudade") % pet.call(4), tr_.call("Faz tempo que vocês não brincam. Volta logo!")])
	out.append([tr_.call("Os insetos estão chegando!"), tr_.call("Desenhe rápido: %s está sozinho no campo.") % pet.call(9)])
	out.append([tr_.call("Missão de resgate"), tr_.call("%s ficou preso entre as pedras. Vem ajudar?") % pet.call(10)])
	# progresso
	var done := Game.completed_count()
	var next := Game.next_level_index() + 1
	if done < LevelDB.count():
		out.append([tr_.call("Próxima: Fase %d") % next, tr_.call("Você já venceu %d fases. A próxima está esperando!") % done])
	var stars := 0
	for i in LevelDB.count():
		stars += Game.stars_of(str(LevelDB.get_level(i)["id"]))
	var missing := LevelDB.count() * 3 - stars
	if done > 0 and missing > 0:
		out.append([tr_.call("%d estrelas esperando") % missing, tr_.call("Volte a uma fase vencida e gaste menos tinta para ganhar mais estrelas.")])
	# Desafio do Dia
	out.append([tr_.call("Desafio do Dia"), tr_.call("O desafio de hoje já está pronto. Consegue vencer?")])
	var streak := int(Game.data.get("daily", {}).get("streak", 0))
	if streak > 1:
		out.append([tr_.call("%d dias seguidos!") % streak, tr_.call("Não perca a sequência do Desafio do Dia.")])
	# Casinha
	out.append([tr_.call("%s está com fome") % pet.call(5), tr_.call("Leva um petisco na Casinha?")])
	out.append([tr_.call("Hora do banho!"), tr_.call("%s quer um banho de bolhas na Casinha.") % pet.call(6)])
	out.append([tr_.call("%s está com sono") % pet.call(7), tr_.call("Põe para dormir na caminha da Casinha?")])
	# Modo Infinito
	var best := Infinite.best()
	if best > 0:
		out.append([tr_.call("Recorde: %d fases") % best, tr_.call("Será que você passa do seu recorde no Modo Infinito?")])
	else:
		out.append([tr_.call("Modo Infinito"), tr_.call("Fases novas sem parar. Quantas você aguenta?")])
	# Ateliê
	out.append([tr_.call("Ateliê"), tr_.call("Que tal pintar um desenho fofo hoje?")])
	out.append([tr_.call("%s quer um retrato") % pet.call(8), tr_.call("Pinte um desenho no Ateliê e salve no Álbum!")])
	return out
