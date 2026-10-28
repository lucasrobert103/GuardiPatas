class_name LineMath
## Matemática pura do traço desenhado (sem dependência de cena → fácil de testar).


static func length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total


## Ramer–Douglas–Peucker: remove pontos que quase não mudam a forma.
static func simplify(points: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if points.size() < 3:
		return points.duplicate()
	var keep := PackedByteArray()
	keep.resize(points.size())
	keep.fill(0)
	keep[0] = 1
	keep[points.size() - 1] = 1
	var stack: Array[Vector2i] = [Vector2i(0, points.size() - 1)]
	while not stack.is_empty():
		var seg: Vector2i = stack.pop_back()
		var a := points[seg.x]
		var b := points[seg.y]
		var best := -1.0
		var best_i := -1
		for i in range(seg.x + 1, seg.y):
			var d := distance_to_segment(points[i], a, b)
			if d > best:
				best = d
				best_i = i
		if best > epsilon and best_i != -1:
			keep[best_i] = 1
			stack.append(Vector2i(seg.x, best_i))
			stack.append(Vector2i(best_i, seg.y))
	var out := PackedVector2Array()
	for i in points.size():
		if keep[i] == 1:
			out.append(points[i])
	return out


static func distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


## Funde pontos muito próximos (evita segmentos minúsculos que deixam a física instável).
static func merge_close(points: PackedVector2Array, min_dist: float) -> PackedVector2Array:
	if points.size() < 2:
		return points.duplicate()
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size() - 1):
		if points[i].distance_to(out[out.size() - 1]) >= min_dist:
			out.append(points[i])
	var last := points[points.size() - 1]
	if out.size() > 1 and last.distance_to(out[out.size() - 1]) < min_dist:
		out[out.size() - 1] = last
	else:
		out.append(last)
	return out


## Suavização de Chaikin preservando as pontas.
static func smooth(points: PackedVector2Array, iterations: int = 1) -> PackedVector2Array:
	var pts := points.duplicate()
	for _it in iterations:
		if pts.size() < 3:
			return pts
		var out := PackedVector2Array([pts[0]])
		for i in range(pts.size() - 1):
			var p := pts[i]
			var q := pts[i + 1]
			out.append(p.lerp(q, 0.25))
			out.append(p.lerp(q, 0.75))
		out.append(pts[pts.size() - 1])
		pts = out
	return pts


## Pipeline usado ao soltar o dedo: simplifica e limita o número de segmentos
## (cada segmento vira uma cápsula de colisão). Não suavizamos por padrão porque a
## suavização "corta cantos" e poderia aproximar a linha de um obstáculo já validado.
static func prepare_stroke(raw: PackedVector2Array, max_segments: int = 40, min_seg: float = 10.0, smooth_iterations: int = 0) -> PackedVector2Array:
	if raw.size() < 2:
		return raw.duplicate()
	var pts := smooth(raw, smooth_iterations)
	var eps := 1.5
	var out := merge_close(simplify(pts, eps), min_seg)
	while out.size() - 1 > max_segments and eps < 64.0:
		eps *= 1.5
		out = merge_close(simplify(pts, eps), min_seg)
	return out


## Retorna o centroide ponderado pelo comprimento (útil para posicionar o corpo).
static func centroid(points: PackedVector2Array) -> Vector2:
	if points.size() == 1:
		return points[0]
	var total := 0.0
	var acc := Vector2.ZERO
	for i in range(1, points.size()):
		var l := points[i - 1].distance_to(points[i])
		acc += (points[i - 1] + points[i]) * 0.5 * l
		total += l
	if total <= 0.0:
		return points[0]
	return acc / total


## Corta uma polilinha para caber num orçamento de tinta.
static func clip_to_length(points: PackedVector2Array, max_len: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.is_empty():
		return out
	out.append(points[0])
	var used := 0.0
	for i in range(1, points.size()):
		var seg := points[i - 1].distance_to(points[i])
		if used + seg <= max_len:
			out.append(points[i])
			used += seg
		else:
			var remain := max_len - used
			if remain > 0.01:
				out.append(points[i - 1].move_toward(points[i], remain))
			break
	return out
