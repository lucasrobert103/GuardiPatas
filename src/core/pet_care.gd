class_name PetCare
extends RefCounted
## Cuidados locais e gratuitos. O tempo só passa enquanto a Casinha está aberta.
const NEEDS := ["food", "clean", "energy", "love"]
const DEFAULTS := {"food": 70.0, "clean": 75.0, "energy": 80.0, "love": 65.0, "sleeping": false, "care_count": 0}
const FOODS := {
	"meal": {"name": "Refeição", "food": 30.0, "love": 3.0},
	"fruit": {"name": "Frutinhas", "food": 20.0, "love": 6.0},
	"snack": {"name": "Petisco", "food": 12.0, "love": 10.0},
}


static func roster() -> Array:
	var out: Array = []
	for pet in Game.data.get("met", []):
		if Cast.ORDER.has(pet) and not out.has(pet):
			out.append(pet)
	for pet in Store.companions():
		if not out.has(pet):
			out.append(pet)
	return out if not out.is_empty() else ["capi"]


static func pet_name(pet: String) -> String:
	return str(Store.PETS[pet]["name"]) if Store.PETS.has(pet) else str(Animal.SPECIES.get(pet, {"name": "Bichinho"})["name"])


static func sanitize(raw: Variant) -> Dictionary:
	var state := DEFAULTS.duplicate()
	if not raw is Dictionary:
		return state
	for key in NEEDS:
		var value: Variant = raw.get(key)
		if (value is float or value is int) and is_finite(float(value)):
			state[key] = clampf(float(value), 0.0, 100.0)
	if raw.get("sleeping") is bool:
		state["sleeping"] = raw["sleeping"]
	var count: Variant = raw.get("care_count", 0)
	if count is float or count is int:
		state["care_count"] = clampi(int(count), 0, 1000000)
	return state


static func state(pet: String) -> Dictionary:
	if not roster().has(pet):
		return {}
	if not Game.data["care"].has(pet):
		Game.data["care"][pet] = DEFAULTS.duplicate()
	return Game.data["care"][pet]


static func tick(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	var elapsed := minf(delta, 2.0)
	for pet in roster():
		var needs := state(pet)
		var sleeping: bool = needs["sleeping"]
		# Não há morte, doença ou perda de progresso quando uma barra chega a zero.
		for key in ["food", "clean", "love"]:
			needs[key] = maxf(0.0, float(needs[key]) - elapsed * (0.012 if sleeping else 0.025))
		needs["energy"] = clampf(float(needs["energy"]) + elapsed * (2.0 if sleeping else -0.018), 0.0, 100.0)


static func act(pet: String, action: String, food: String = "meal") -> Dictionary:
	var needs := state(pet)
	if needs.is_empty():
		return {"ok": false, "message": "Escolha um bichinho disponível."}
	if action == "sleep":
		needs["sleeping"] = not needs["sleeping"]
		return {"ok": true, "message": "Boa soneca!" if needs["sleeping"] else "Bom dia! Vamos brincar?"}
	if needs["sleeping"] and action != "pet":
		return {"ok": false, "message": "Acorde o bichinho primeiro. Ele está descansando."}
	match action:
		"feed":
			if not FOODS.has(food):
				return {"ok": false, "message": "Escolha uma comida."}
			if float(needs["food"]) >= 100.0:
				return {"ok": false, "message": "Barriguinha cheia! Que tal outro cuidado?"}
			needs["food"] = minf(100.0, float(needs["food"]) + FOODS[food]["food"])
			needs["love"] = minf(100.0, float(needs["love"]) + FOODS[food]["love"])
		"bath":
			needs["clean"] = 100.0
			needs["love"] = minf(100.0, float(needs["love"]) + 8.0)
		"play":
			if float(needs["energy"]) < 10.0:
				return {"ok": false, "message": "Uma soneca primeiro vai fazer bem!"}
			needs["energy"] = maxf(0.0, float(needs["energy"]) - 5.0)
			needs["love"] = minf(100.0, float(needs["love"]) + 12.0)
			needs["clean"] = maxf(0.0, float(needs["clean"]) - 2.0)
		"pet":
			needs["love"] = minf(100.0, float(needs["love"]) + 5.0)
		_:
			return {"ok": false, "message": "Cuidado indisponível."}
	needs["care_count"] = mini(1000000, int(needs["care_count"]) + 1)
	return {"ok": true, "message": "Que delícia!" if action == "feed" else "Adorei esse cuidado!"}
