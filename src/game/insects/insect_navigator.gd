class_name InsectNavigator
extends RefCounted
## Navegação local com folga para o corpo. Consulta física em intervalos limitados,
## guarda o desvio até chegar e nunca altera posição ou camadas de colisão.
const MASK := Layers.TERRAIN | Layers.LINE | Layers.PROP
const REPLAN := 0.22
var waypoint := Vector2.INF
var _goal := Vector2.INF
var _timer := 0.0
var _recent: Array[Vector2] = []


func next_point(bug: Insect, goal: Vector2, delta: float, avoid_ink: bool = true) -> Vector2:
	_timer -= delta
	if waypoint.is_finite() and bug.global_position.distance_to(waypoint) < 6:
		_recent.append(waypoint)
		if _recent.size() > 4: _recent.pop_front()
		waypoint = Vector2.INF
		_timer = 0
	if _goal.distance_to(goal) > 100:
		waypoint = Vector2.INF
		_recent.clear()
		_timer = 0
	if _timer > 0:
		return waypoint if waypoint.is_finite() else goal
	_timer = REPLAN + (bug.tactic_id % 3) * 0.025
	_goal = goal
	var mask := MASK if avoid_ink else Layers.TERRAIN | Layers.PROP
	var hit := obstacle(bug, bug.global_position, goal, mask)
	if hit.is_empty() or hit["collider"] is HoneyPot:
		waypoint = Vector2.INF
		_recent.clear()
		return goal
	# Não abandonar um canto a meio caminho só porque a visão direta ainda bate nele.
	if waypoint.is_finite() and obstacle(bug, bug.global_position, waypoint, mask).is_empty():
		return waypoint
	waypoint = Vector2.INF
	var body: Node2D = hit["collider"] as Node2D
	var best_score := INF
	for candidate in candidates(body, bug.shape.radius):
		if candidate.x < -100 or candidate.x > 820 or candidate.y < 80 or candidate.y > 1320:
			continue
		var distance := bug.global_position.distance_to(candidate)
		if distance < 18 or not obstacle(bug, bug.global_position, candidate, mask).is_empty():
			continue
		var onward := obstacle(bug, candidate, goal, mask)
		# Um laço fechado continua sendo uma defesa. Um traço aberto, porém,
		# pode exigir mais de um canto até chegar à ponta que deixou uma entrada.
		var closed_loop: bool = body is DrawnLine and body.points_local[0].distance_to(body.points_local[-1]) < DrawnLine.THICKNESS
		if closed_loop and not onward.is_empty():
			continue
		var score := distance + candidate.distance_to(goal) + (180.0 if not onward.is_empty() else 0.0)
		for previous in _recent:
			if previous.distance_to(candidate) < 24: score += 600
		# Desempate estável: parte do enxame explora cada lado.
		score += (candidate.y - bug.global_position.y) * (0.03 if bug.tactic_id % 2 == 0 else -0.03)
		if score < best_score:
			best_score = score
			waypoint = candidate
	return waypoint if waypoint.is_finite() else goal


static func obstacle(bug: Insect, start: Vector2, finish: Vector2, mask: int = MASK) -> Dictionary:
	if start.distance_to(finish) < 2: return {}
	var side := (finish - start).normalized().orthogonal() * (bug.shape.radius + 1.0)
	var nearest: Dictionary = {}
	var distance := INF
	var excluded: Array[RID] = [bug.get_rid()]
	for exception in bug.get_collision_exceptions(): excluded.append(exception.get_rid())
	for offset in [Vector2.ZERO, side, -side]:
		var query := PhysicsRayQueryParameters2D.create(start + offset, finish + offset, mask, excluded)
		var hit := bug.get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var length: float = start.distance_squared_to(hit["position"])
			if length < distance:
				distance = length
				nearest = hit
	return nearest


static func candidates(body: Node2D, body_radius: float) -> Array[Vector2]:
	var vertices := PackedVector2Array()
	var result: Array[Vector2] = []
	var margin := body_radius + 10
	if body is Terrain:
		for point in body.poly: vertices.append(body.to_global(point))
		# Vértices côncavos importam: só os quatro cantos do retângulo não
		# revelam a entrada de uma caverna em L, nem a parte de baixo de um teto.
		for i in vertices.size():
			var incoming := (vertices[i] - vertices[(i - 1 + vertices.size()) % vertices.size()]).normalized()
			var outgoing := (vertices[(i + 1) % vertices.size()] - vertices[i]).normalized()
			var outward := (incoming.orthogonal() + outgoing.orthogonal()).normalized()
			if Geometry2D.is_point_in_polygon(vertices[i] + outward * 2, vertices): outward = -outward
			result.append(vertices[i] + outward * margin * 1.5)
	elif body is Crate:
		var half: Vector2 = body.size / 2
		for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]:
			vertices.append(body.to_global(corner))
	elif body is DrawnLine:
		for point in body.points_local: vertices.append(body.to_global(point))
		margin += DrawnLine.THICKNESS / 2
		if not vertices.is_empty():
			for endpoint in [vertices[0], vertices[-1]]:
				for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
					result.append(endpoint + direction * margin)
	if vertices.is_empty(): return result
	var bounds := Rect2(vertices[0], Vector2.ZERO)
	for point in vertices: bounds = bounds.expand(point)
	bounds = bounds.grow(margin)
	result.append_array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)])
	return result
