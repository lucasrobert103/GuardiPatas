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
}

const SCARE_RADIUS := 210.0

var species := "capi"
var art: AnimalArt
var shell_hits := 0
var alive := true
var level: Level = null
var _scared_announced := false


static func half_height(sp: String) -> float:
	var cfg: Dictionary = SPECIES[sp]
	if cfg["shape"] == "vcapsule":
		return float(cfg["h"]) * 0.5
	return float(cfg["r"])


func setup(p_species: String, p_level: Level, flip: bool) -> void:
	species = p_species if SPECIES.has(p_species) else "capi"
	level = p_level
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
	mat.friction = 0.9
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


func _physics_process(_delta: float) -> void:
	if not alive or level == null:
		return
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
				Sfx.play("gasp", -6.0, 1.0, 0.15)
			return
	art.mood = "idle"


func _on_body_entered(body: Node) -> void:
	if body is Insect:
		on_insect_touch(body)


func on_insect_touch(insect: Insect) -> void:
	if not alive or insect.calmed or not level.is_running():
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
