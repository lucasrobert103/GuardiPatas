class_name Animal
extends RigidBody2D
## Bichinho protegido. Corpo rígido com forma simples e estável; a arte fica em AnimalArt.
## Cada espécie tem uma característica que muda a física da fase (ver docs/05-personagens.md).

signal stung(animal: Animal, insect: Node)

const SPECIES := {
	# shape: "hcapsule" (deitado), "vcapsule" (em pé) ou "circle"
	"capi": {"name": "Capitu", "shape": "hcapsule", "r": 30.0, "h": 112.0, "mass": 4.0, "rolls": false, "shell": 0, "swims": false},
	"brasa": {"name": "Brasa", "shape": "vcapsule", "r": 26.0, "h": 92.0, "mass": 1.6, "rolls": false, "shell": 0, "swims": false},
	"pingo": {"name": "Pingo", "shape": "circle", "r": 28.0, "h": 0.0, "mass": 1.4, "rolls": true, "shell": 0, "swims": false},
	"lulu": {"name": "Lulu", "shape": "hcapsule", "r": 18.0, "h": 74.0, "mass": 0.9, "rolls": false, "shell": 0, "swims": true},
	"tuca": {"name": "Tuca", "shape": "hcapsule", "r": 24.0, "h": 92.0, "mass": 5.0, "rolls": false, "shell": 1, "swims": true},
	"nino": {"name": "Nino", "shape": "circle", "r": 22.0, "h": 0.0, "mass": 0.6, "rolls": false, "shell": 0, "swims": false},
	"gelinho": {"name": "Gelinho", "shape": "vcapsule", "r": 22.0, "h": 72.0, "mass": 1.4, "rolls": false, "shell": 0, "swims": true, "friction": 0.05},
	"tata": {"name": "Tatá", "shape": "circle", "r": 24.0, "h": 0.0, "mass": 1.6, "rolls": true, "shell": 0, "swims": false},
	"pompom": {"name": "Pompom", "shape": "vcapsule", "r": 22.0, "h": 84.0, "mass": 0.8, "rolls": false, "shell": 0, "swims": false},
	"nuvem": {"name": "Nuvem", "shape": "circle", "r": 32.0, "h": 0.0, "mass": 2.2, "rolls": false, "shell": 2, "swims": false},
	"fofa": {"name": "Fofa", "shape": "hcapsule", "r": 24.0, "h": 100.0, "mass": 3.0, "rolls": false, "shell": 0, "swims": true},
	"tito": {"name": "Tito", "shape": "circle", "r": 24.0, "h": 0.0, "mass": 1.0, "rolls": false, "shell": 0, "swims": true},
	"patinha": {"name": "Patinha", "shape": "circle", "r": 22.0, "h": 0.0, "mass": 0.5, "rolls": false, "shell": 0, "swims": true},
	"kiko": {"name": "Kiko", "shape": "vcapsule", "r": 24.0, "h": 76.0, "mass": 0.7, "rolls": false, "shell": 0, "swims": false},
}

const SCARE_RADIUS := 210.0
## Som do susto de cada bichinho: [efeito, tom].
const SCARE_VOICE := {
	"capi": ["gasp", 0.75], "brasa": ["gasp", 1.2], "pingo": ["gasp", 1.45], "nino": ["gasp", 1.7],
	"tuca": ["gasp", 0.6], "lulu": ["bloop", 1.2], "gelinho": ["gasp", 1.3], "nuvem": ["baa", 1.0],
	"kiko": ["gasp", 0.9], "tata": ["gasp", 1.1], "pompom": ["gasp", 1.6], "patinha": ["quack", 1.0],
	"fofa": ["gasp", 0.8], "tito": ["bloop", 0.9],
}

var species := "capi"
var art: AnimalArt
var shell_hits := 0
var alive := true
var level: Level = null
var _scared_announced := false
## Medroso: corre para longe quando VÊ um inseto (a tinta é transparente; terreno esconde).
var skittish := false
## Escondido numa toca segura: insetos não o encontram mais.
var in_burrow := false
var _panic := 0.0
var _run_dir := 1.0
var _jump_cd := 0.0
const FLEE_SIGHT := 290.0
const RUN_SPEED := 250.0
## Espécies medrosas por natureza (a fase pode mudar com "flee").
const SKITTISH := ["pompom", "nino", "patinha"]


static func half_height(sp: String) -> float:
	var cfg: Dictionary = SPECIES[sp]
	if cfg["shape"] == "vcapsule":
		return float(cfg["h"]) * 0.5
	return float(cfg["r"])


func setup(p_species: String, p_level: Level, flip: bool, flee: Variant = null) -> void:
	species = p_species if SPECIES.has(p_species) else "capi"
	level = p_level
	skittish = bool(flee) if flee != null else SKITTISH.has(species)
	var cfg: Dictionary = SPECIES[species]
	mass = cfg["mass"]
	lock_rotation = not cfg["rolls"]
	shell_hits = cfg["shell"]
	collision_layer = Layers.ANIMAL
	collision_mask = Layers.ANIMAL_MASK
	contact_monitor = true
	max_contacts_reported = 8
	can_sleep = false
	freeze = true
	var mat := PhysicsMaterial.new()
	mat.friction = float(cfg.get("friction", 0.9))
	mat.bounce = 0.0
	physics_material_override = mat
	var cs := CollisionShape2D.new()
	match cfg["shape"]:
		"circle":
			var c := CircleShape2D.new()
			c.radius = cfg["r"]
			cs.shape = c
		"vcapsule":
			var c := CapsuleShape2D.new()
			c.radius = cfg["r"]
			c.height = cfg["h"]
			cs.shape = c
		_:
			var c := CapsuleShape2D.new()
			c.radius = cfg["r"]
			c.height = cfg["h"]
			cs.shape = c
			cs.rotation = PI / 2.0
	add_child(cs)
	art = AnimalArt.new()
	art.species = species
	art.facing = -1.0 if flip else 1.0
	art.accessory = Game.equipped(species)
	add_child(art)
	body_entered.connect(_on_body_entered)


func display_name() -> String:
	return SPECIES[species]["name"]


func can_swim() -> bool:
	return SPECIES[species]["swims"]


func _physics_process(delta: float) -> void:
	if not alive or level == null or in_burrow:
		return
	if skittish and level.is_running():
		_flee(delta)
	if art.mood in ["happy", "sad", "ouch"]:
		return
	var nearest: Insect = level.nearest_insect(global_position)
	if nearest != null:
		var to := nearest.global_position - global_position
		art.look = (to / maxf(to.length(), 1.0)) * Vector2(art.facing, 1.0)
		if to.length() < SCARE_RADIUS:
			art.mood = "scared"
			if not _scared_announced:
				_scared_announced = true
				var voice: Array = SCARE_VOICE.get(species, ["gasp", 1.0])
				Sfx.play(voice[0], -6.0, voice[1], 0.08)
			return
	art.mood = "idle"


## Fuga: vê um inseto (sem terreno no meio) → corre para o lado oposto e pula o que
## estiver na frente. Dentro de um abrigo solto ele empurra e pula até sair.
func _flee(delta: float) -> void:
	_jump_cd = maxf(_jump_cd - delta, 0.0)
	var seen := level.visible_insect(global_position, FLEE_SIGHT)
	if seen != null:
		if _panic <= 0.0 or absf(seen.global_position.x - global_position.x) > 24.0:
			var dx := global_position.x - seen.global_position.x
			if absf(dx) > 8.0:
				_run_dir = signf(dx)
		_panic = 1.5
	if _panic <= 0.0:
		return
	_panic -= delta
	art.facing = _run_dir
	var dv := _run_dir * RUN_SPEED - linear_velocity.x
	apply_central_force(Vector2(clampf(dv * mass * 14.0, -mass * 3200.0, mass * 3200.0), 0.0))
	if _jump_cd > 0.0:
		return
	var space := get_world_2d().direct_space_state
	var hh := half_height(species)
	var reach := (float(SPECIES[species]["h"]) * 0.5 if SPECIES[species]["shape"] == "hcapsule" else float(SPECIES[species]["r"])) + 12.0
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(_run_dir * reach, 0), Layers.TERRAIN | Layers.LINE | Layers.PROP, [get_rid()])
	var down := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, hh + 6.0), Layers.TERRAIN | Layers.LINE | Layers.PROP, [get_rid()])
	var grounded := not space.intersect_ray(down).is_empty()
	if not grounded:
		return
	if not space.intersect_ray(q).is_empty():
		_jump_cd = 0.8
		apply_central_impulse(Vector2(_run_dir * 0.35, -1.0).normalized() * mass * 560.0)
		return
	# degrau baixo no pé (ex.: uma linha deitada no chão): sobe com um pulinho
	var foot := global_position + Vector2(0, hh - 6.0)
	var qf := PhysicsRayQueryParameters2D.create(foot, foot + Vector2(_run_dir * reach, 0), Layers.TERRAIN | Layers.LINE | Layers.PROP, [get_rid()])
	if not space.intersect_ray(qf).is_empty():
		_jump_cd = 0.35
		linear_velocity.y = -sqrt(2.0 * 980.0 * 34.0)


func hide_in_burrow() -> void:
	if in_burrow:
		return
	in_burrow = true
	_panic = 0.0
	linear_velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = Layers.TERRAIN
	art.mood = "happy"
	art.modulate = Color(1, 1, 1, 0.55)
	Sfx.play("pop", -2.0, 1.3)
	Fx.popup_text(level.fx_layer, global_position + Vector2(0, -60), "A salvo!", Palette.UI_GOOD)


func _on_body_entered(body: Node) -> void:
	if body is Insect:
		on_insect_touch(body)
	elif body is Terrain and (body as Terrain).style == "thorns" and level != null:
		level.on_animal_thorn(self)


func on_insect_touch(insect: Insect) -> void:
	if not alive or in_burrow or insect.calmed or not level.is_running():
		return
	if shell_hits > 0:
		# o casco da Tuca aguenta uma picadinha
		shell_hits -= 1
		art.shell_flash = 1.0
		Sfx.play("bonk", 0.0, 0.7)
		var away := (insect.global_position - global_position).normalized()
		insect.apply_central_impulse(away * 120.0 * insect.mass)
		insect.daze(1.2)
		return
	alive = false
	art.mood = "ouch"
	stung.emit(self, insect)


func celebrate() -> void:
	art.mood = "happy"


func be_sad() -> void:
	if art.mood != "ouch":
		art.mood = "sad"
