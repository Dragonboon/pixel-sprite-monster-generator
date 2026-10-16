class_name SilhouetteRefiner
extends RefCounted

## Optional post-process for x-major maps from MapGenerator.
static func refine(source: Array[Variant], strength: float, largest_only: bool, symmetry: float = 0.0) -> Array[Variant]:
	var result: Array[Variant] = source.duplicate(true)
	if result.is_empty() or result[0].is_empty():
		return result
	var width: int = result.size()
	var height: int = result[0].size()
	strength = clampf(strength, 0.0, 1.0)
	if strength > 0.0:
		for x in width:
			for y in height:
				if not result[x][y]:
					continue
				var nx: float = (float(x) - float(width - 1) * 0.5) / maxf(1.0, float(width) * 0.5)
				var ny: float = (float(y) - float(height - 1) * 0.5) / maxf(1.0, float(height) * 0.5)
				# Row-wise irregularity preserves bilateral symmetry.
				var ripple: float = sin(float(y) * 0.71) * 0.06 + sin(float(y) * 1.37 + 0.8) * 0.04
				var radius_limit: float = lerpf(2.0, 0.78 + ripple, strength)
				if nx * nx * 0.82 + ny * ny * 0.95 > radius_limit:
					result[x][y] = false
	if largest_only:
		return _keep_largest_component(result, symmetry >= 99.999)
	return result


static func _keep_largest_component(source: Array[Variant], mirror: bool) -> Array[Variant]:
	var width: int = source.size()
	var height: int = source[0].size()
	var visited: Dictionary = {}
	var largest: Array[Vector2i] = []
	for x in width:
		for y in height:
			var start := Vector2i(x, y)
			if not source[x][y] or visited.has(start):
				continue
			var pending: Array[Vector2i] = [start]
			var component: Array[Vector2i] = []
			visited[start] = true
			while not pending.is_empty():
				var point: Vector2i = pending.pop_back()
				component.append(point)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbor: Vector2i = point + offset
					if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height:
						continue
					if source[neighbor.x][neighbor.y] and not visited.has(neighbor):
						visited[neighbor] = true
						pending.append(neighbor)
			if component.size() > largest.size():
				largest = component
	var result: Array[Variant] = source.duplicate(true)
	for x in width:
		for y in height:
			result[x][y] = false
	for point in largest:
		result[point.x][point.y] = true
		if mirror:
			result[width - 1 - point.x][point.y] = true
	return result
