class_name AttemptReplay
extends RefCounted
## Histórico visual limitado. Guarda valores, nunca corpos físicos ou texturas.
const INTERVAL := 0.1
const WINDOW := 3.0
const MAX_FRAMES := 32
var frames: Array[Dictionary] = []
var terrain: Array[Dictionary] = []
var waters: Array[Rect2] = []
var geometry: Dictionary = {}
var goal := Rect2()
var finished := false
var _wait := 0.0


func begin(level: Level) -> void:
	frames.clear()
	terrain.clear()
	waters.clear()
	geometry.clear()
	finished = false
	_wait = 0
	for child in level.world.get_children():
		if child is Terrain:
			terrain.append({"points": child.poly.duplicate(), "transform": child.global_transform, "style": child.style})
		elif child is Water:
			waters.append(child.rect)
	goal = level.goal.rect if level.goal != null else Rect2()
	record(level, 0, true)


func record(level: Level, delta: float, force: bool = false) -> void:
	if finished: return
	_wait -= delta
	if not force and _wait > 0: return
	_wait = INTERVAL if force else _wait + INTERVAL
	var frame := {"time": level._sim_time, "actors": [], "lines": [], "blocks": [], "nests": [], "shots": [], "lamps": [], "bosses": [], "winds": []}
	for animal in level.animals:
		if not is_instance_valid(animal): continue
		frame["actors"].append({"id": animal.get_instance_id(), "animal": true, "kind": animal.species, "position": animal.global_position, "rotation": animal.rotation, "facing": animal.art.facing, "mood": animal.art.mood, "accessory": animal.art.accessory, "clock": animal.art._t})
	for bug in level.insects:
		if not is_instance_valid(bug): continue
		frame["actors"].append({"id": bug.get_instance_id(), "animal": false, "kind": bug.kind, "position": bug.global_position, "rotation": bug.rotation, "facing": bug.art.facing, "radius": bug.art.radius, "aiming": bug.art.aiming, "dazed": bug.art.dazed, "excited": bug.art.excited, "thread": bug.art.thread, "work": bug.art.work_progress, "aim_vector": bug.art.aim_vector, "aim_progress": bug.art.aim_progress, "jump_velocity": bug.art.jump_velocity, "squash": bug.art.squash, "clock": bug.art._t})
	for line in level.lines:
		if not is_instance_valid(line): continue
		var id := line.get_instance_id()
		if not geometry.has(id): geometry[id] = line.points_local.duplicate()
		frame["lines"].append({"id": id, "transform": line.global_transform, "static": line.static_ink, "holes": line.holes.duplicate()})
	for body in level.props + level.platforms:
		if is_instance_valid(body): frame["blocks"].append({"id": body.get_instance_id(), "transform": body.global_transform, "size": body.size, "wood": body is Crate})
	for nest in level.nests:
		frame["nests"].append({"id": nest.get_instance_id(), "position": nest.global_position, "hole": nest.hole, "remaining": nest.remaining, "plugged": nest.hole and nest._is_plugged()})
	for shot in level.projectiles:
		if is_instance_valid(shot): frame["shots"].append({"id": shot.get_instance_id(), "position": shot.global_position, "radius": shot.radius, "kind": shot.kind})
	for coconut in level.coconuts:
		if is_instance_valid(coconut): frame["shots"].append({"id": coconut.get_instance_id(), "position": coconut.global_position, "radius": 18, "kind": "coconut"})
	for wind in level.winds:
		if wind.active: frame["winds"].append({"rect": wind.rect, "dir": wind.dir})
	for lamp in level.lamps:
		frame["lamps"].append({"id": lamp.get_instance_id(), "position": lamp.global_position, "lit": lamp.lit})
	for boss in level.bosses:
		frame["bosses"].append({"id": boss.get_instance_id(), "position": boss.global_position, "kind": boss.kind, "clock": boss._t, "phase": boss._phase, "phase_time": boss._phase_t, "marks": boss._marks.duplicate(), "ground": boss._ground_y.duplicate(), "aim": boss._aim, "launch": boss._launch_v, "ink": boss._ink, "ink_position": boss._ink_pos, "flap": boss._flap})
	for queen in level.queens:
		frame["bosses"].append({"id": queen.get_instance_id(), "position": queen.global_position, "kind": "queen", "clock": queen._t, "puff": queen._puff, "blow": queen._blow})
	frames.append(frame)
	while frames.size() > MAX_FRAMES or (frames.size() > 1 and level._sim_time - float(frames[0]["time"]) > WINDOW):
		frames.pop_front()


func finish(level: Level) -> void:
	record(level, 0, true)
	finished = true


func clear() -> void:
	frames.clear()
	geometry.clear()
	terrain.clear()
	waters.clear()
	finished = true


func duration() -> float:
	return float(frames[-1]["time"]) - float(frames[0]["time"]) if frames.size() > 1 else 0.0


func at(seconds: float) -> Dictionary:
	if frames.is_empty(): return {}
	var target := float(frames[0]["time"]) + clampf(seconds, 0, duration())
	for i in range(frames.size()-1, -1, -1):
		if float(frames[i]["time"]) <= target + 0.0001:
			if i == frames.size()-1: return frames[i]
			var fraction := clampf((target-float(frames[i]["time"])) / maxf(0.0001, float(frames[i+1]["time"])-float(frames[i]["time"])), 0, 1)
			return _between(frames[i], frames[i+1], fraction)
	return frames[0]


func _between(before: Dictionary, after: Dictionary, fraction: float) -> Dictionary:
	var result := before.duplicate()
	result["time"] = lerpf(float(before["time"]), float(after["time"]), fraction)
	for category in ["actors", "lines", "blocks", "nests", "shots", "lamps", "bosses"]:
		var next_by_id := {}
		for item in after[category]: next_by_id[item["id"]] = item
		var items: Array = []
		for item in before[category]:
			var sample: Dictionary = item.duplicate()
			if next_by_id.has(item["id"]):
				var next: Dictionary = next_by_id[item["id"]]
				if item.has("position"): sample["position"] = (item["position"] as Vector2).lerp(next["position"], fraction)
				if item.has("rotation"): sample["rotation"] = lerp_angle(item["rotation"], next["rotation"], fraction)
				if item.has("transform"): sample["transform"] = (item["transform"] as Transform2D).interpolate_with(next["transform"], fraction)
			items.append(sample)
		result[category] = items
	return result
