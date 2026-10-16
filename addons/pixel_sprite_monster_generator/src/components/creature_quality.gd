class_name CreatureQuality
extends RefCounted

## Deterministic morphological metrics. Heuristics guide seed selection, not anatomy.
static func measure(map: Array[Variant]) -> Dictionary:
	if map.is_empty() or map[0].is_empty():
		return {"score": 0.0, "occupied": 0, "width": 0, "height": 0, "connected_ratio": 0.0}
	var width: int = map.size()
	var height: int = map[0].size()
	var left: int = width
	var right: int = -1
	var top: int = height
	var bottom: int = -1
	var count: int = 0
	var sum_x: float = 0.0
	for x in width:
		for y in height:
			if map[x][y]:
				count += 1
				sum_x += float(x)
				left = mini(left, x)
				right = maxi(right, x)
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if count == 0:
		return {"score": 0.0, "occupied": 0, "width": 0, "height": 0, "connected_ratio": 0.0}
	var body_width: int = right - left + 1
	var body_height: int = bottom - top + 1
	var occupancy: float = float(count) / float(body_width * body_height)
	var visited: Dictionary = {}
	var largest: int = 0
	for x in width:
		for y in height:
			var start := Vector2i(x, y)
			if not map[x][y] or visited.has(start):
				continue
			var stack: Array[Vector2i] = [start]
			visited[start] = true
			var area: int = 0
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				area += 1
				for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbor: Vector2i = point + delta
					if neighbor.x < 0 or neighbor.x >= width or neighbor.y < 0 or neighbor.y >= height:
						continue
					if map[neighbor.x][neighbor.y] and not visited.has(neighbor):
						visited[neighbor] = true
						stack.append(neighbor)
			largest = maxi(largest, area)
	var connected_ratio: float = float(largest) / float(count)
	var horizontal_extent: float = minf(1.0, float(body_width) / maxf(1.0, float(width) * 0.48))
	var vertical_extent: float = minf(1.0, float(body_height) / maxf(1.0, float(height) * 0.48))
	# Very sparse tangles and solid rectangles are both harder to read.
	var occupancy_fitness: float = clampf(1.0 - absf(occupancy - 0.55) / 0.55, 0.0, 1.0)
	var center_fitness: float = clampf(1.0 - absf(sum_x / float(count) - float(width - 1) * 0.5) / maxf(1.0, float(width) * 0.5), 0.0, 1.0)
	var score: float = 100.0 * (0.22 * horizontal_extent + 0.22 * vertical_extent + 0.18 * occupancy_fitness + 0.30 * connected_ratio + 0.08 * center_fitness)
	return {"score": score, "occupied": count, "width": body_width, "height": body_height, "connected_ratio": connected_ratio}
