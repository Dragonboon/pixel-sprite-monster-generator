class_name CreatureSilhouetteIntegrity
extends RefCounted

## Conservative cleanup of x-major boolean silhouettes. Does not touch color,
## enclosed facial holes or user-authored sprites. Keeps long thin appendages.
const CARDINAL = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


static func repair(source: Array[Variant], preserve_uncanny: bool = false) -> Array[Variant]:
	var result: Array[Variant] = source.duplicate(true)
	if result.is_empty() or result[0].is_empty():
		return result
	var width: int = result.size()
	var height: int = result[0].size()
	if width < 12 or height < 12:
		return result
	var groups: Array[Dictionary] = _components(result)
	if groups.is_empty():
		return result
	groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["area"]) > int(b["area"]))
	var main_cells: Array[Vector2i] = groups[0]["cells"]
	# Multi-source four-neighbor BFS gives the shortest *orthogonal* bridge
	# to the main silhouette. One BFS suffices for every detached piece.
	var distances := PackedInt32Array()
	distances.resize(width * height)
	distances.fill(-1)
	var predecessors := PackedInt32Array()
	predecessors.resize(width * height)
	predecessors.fill(-1)
	var queue: Array[int] = []
	for point in main_cells:
		var at: int = point.x * height + point.y
		distances[at] = 0
		queue.append(at)
	var cursor: int = 0
	while cursor < queue.size():
		var at: int = queue[cursor]
		cursor += 1
		var x: int = at / height
		var y: int = at % height
		for delta in CARDINAL:
			var px: int = x + delta.x
			var py: int = y + delta.y
			if px < 0 or py < 0 or px >= width or py >= height:
				continue
			var neighbor: int = px * height + py
			if distances[neighbor] >= 0:
				continue
			distances[neighbor] = distances[at] + 1
			predecessors[neighbor] = at
			queue.append(neighbor)

	for group_index in range(1, groups.size()):
		var cells: Array[Vector2i] = groups[group_index]["cells"]
		var best: int = -1
		var gap: int = width + height
		for point in cells:
			var at: int = point.x * height + point.y
			if distances[at] < gap:
				gap = distances[at]
				best = at
		# Join deliberate appendages detached by one or two edge pixels.
		# Tiny distant particles are noise; significant distant bodies are
		# kept so the quality gate can reject/reroll rather than disguise them.
		var connectable: bool = cells.size() >= 2 and gap <= 4
		if connectable:
			var at: int = best
			while at >= 0 and distances[at] > 0:
				result[at / height][at % height] = true
				at = predecessors[at]
		elif cells.size() <= maxi(2, main_cells.size() / 60):
			for point in cells:
				result[point.x][point.y] = false

	if not preserve_uncanny:
		# Fill only single-cell concave notches with three solid orthogonal
		# neighbors. Deliberate enclosed eye sockets (four) are untouched.
		# Never erode tips: long antennae, fingers and tails remain intact.
		var before: Array[Variant] = result.duplicate(true)
		for x in range(1, width - 1):
			for y in range(1, height - 1):
				if before[x][y]:
					continue
				var connected: int = 0
				for delta in CARDINAL:
					if before[x + delta.x][y + delta.y]:
						connected += 1
				if connected == 3:
					result[x][y] = true
	return result


## Family-aware validity and explainable score; no modifications to the map.
## Reuse CreatureQuality.measure() to avoid a second component traversal.
static func inspect(map: Array[Variant], archetype: int, quality: Dictionary, uncanny: bool = false) -> Dictionary:
	if map.is_empty() or map[0].is_empty():
		return {"valid": false, "score": 0.0, "isolated": 0, "thin_ratio": 1.0, "core_ratio": 0.0}
	var w: int = map.size()
	var h: int = map[0].size()
	var occupied: int = int(quality.get("occupied", 0))
	if occupied == 0:
		return {"valid": false, "score": 0.0, "isolated": 0, "thin_ratio": 1.0, "core_ratio": 0.0}
	var isolated: int = 0
	var thin: int = 0
	var core: int = 0
	var body_left: int = roundi(float(w) * 0.27)
	var body_right: int = roundi(float(w) * 0.73)
	var body_top: int = roundi(float(h) * 0.31)
	var body_bottom: int = roundi(float(h) * 0.72)
	for x in w:
		for y in h:
			if not map[x][y]:
				continue
			var adjacent: int = 0
			for delta in CARDINAL:
				var px: int = x + delta.x
				var py: int = y + delta.y
				if px >= 0 and py >= 0 and px < w and py < h and map[px][py]:
					adjacent += 1
			if adjacent == 0:
				isolated += 1
			if adjacent <= 2:
				thin += 1
			if x >= body_left and x <= body_right and y >= body_top and y <= body_bottom:
				core += 1
	var connected: float = float(quality.get("connected_ratio", 0.0))
	var fragments: int = int(quality.get("components", 0))
	var thin_ratio: float = float(thin) / float(occupied)
	var core_ratio: float = float(core) / float(occupied)
	var extent_x: float = float(quality.get("width", 0)) / float(w)
	var extent_y: float = float(quality.get("height", 0)) / float(h)
	var is_small: bool = occupied < maxi(8, roundi(float(w * h) * 0.045))
	var readable: bool = extent_x >= 0.22 and extent_y >= 0.22
	if archetype == CreatureMorphology.Archetype.QUADRUPED:
		readable = readable and extent_x >= 0.39 and core_ratio >= 0.18
	elif archetype == CreatureMorphology.Archetype.GOLEM:
		readable = readable and core_ratio >= 0.25
	elif archetype == CreatureMorphology.Archetype.SPIRIT:
		readable = readable and core_ratio >= 0.18
	elif archetype == CreatureMorphology.Archetype.BIPED and not uncanny:
		readable = readable and core_ratio >= 0.20
	# Uncanny figures have intentional narrow limbs and asymmetric faces;
	# penalize real fragmentation, but not long limbs or unusual head ratios.
	var thin_limit: float = 0.46 if archetype == CreatureMorphology.Archetype.INSECTOID or uncanny else 0.36
	var valid: bool = connected >= 0.965 and fragments <= 1 and isolated == 0 and not is_small and readable and thin_ratio <= thin_limit
	var score: float = 100.0
	score -= (1.0 - connected) * 115.0
	score -= float(maxi(0, fragments - 1)) * 16.0
	score -= float(isolated) * 6.0
	score -= maxf(0.0, thin_ratio - 0.16) * (32.0 if uncanny else 50.0)
	score -= maxf(0.0, 0.28 - core_ratio) * 45.0
	if not readable or is_small:
		score -= 25.0
	return {
		"valid": valid,
		"score": clampf(score, 0.0, 100.0),
		"isolated": isolated,
		"thin_ratio": thin_ratio,
		"core_ratio": core_ratio,
		"components": fragments,
		"connected_ratio": connected
	}


static func _components(map: Array[Variant]) -> Array[Dictionary]:
	var width: int = map.size()
	var height: int = map[0].size()
	var visited := PackedByteArray()
	visited.resize(width * height)
	visited.fill(0)
	var groups: Array[Dictionary] = []
	for x in width:
		for y in height:
			var first: int = x * height + y
			if not map[x][y] or visited[first] != 0:
				continue
			var pending: Array[Vector2i] = [Vector2i(x, y)]
			var cells: Array[Vector2i] = []
			visited[first] = 1
			while not pending.is_empty():
				var point: Vector2i = pending.pop_back()
				cells.append(point)
				for delta in CARDINAL:
					var nx: int = point.x + delta.x
					var ny: int = point.y + delta.y
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						continue
					var at: int = nx * height + ny
					if visited[at] == 0 and map[nx][ny]:
						visited[at] = 1
						pending.append(Vector2i(nx, ny))
			groups.append({"cells": cells, "area": cells.size()})
	return groups
