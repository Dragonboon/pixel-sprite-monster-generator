class_name CreatureMood
extends RefCounted

enum Mood { NORMAL, COZY, HORROR, EPIC }

## Mood is independent of the anatomy family; no use of global RNG.
static func apply(source: Array[Variant], mood: Mood, seed_value: int) -> Array[Variant]:
	var result: Array[Variant] = source.duplicate(true)
	if mood == Mood.NORMAL or result.is_empty() or result[0].is_empty():
		return result
	var width: int = result.size()
	var height: int = result[0].size()
	var original: Array[Variant] = result.duplicate(true)
	match mood:
		Mood.COZY:
			# Round harsh corners but retain a connected central volume.
			for x in range(1, width - 1):
				for y in range(1, height - 1):
					var count: int = _neighbors(original, x, y)
					if original[x][y] and count <= 2:
						result[x][y] = false
					elif not original[x][y] and count >= 6:
						result[x][y] = true
		Mood.HORROR:
			# Bounded protrusions extending upward from existing solid borders.
			for x in range(2, width - 2):
				for y in range(3, height - 3):
					if original[x][y] and not original[x][y - 1] and _hash(x, y, seed_value) % 11 == 0:
						result[x][y - 1] = true
						if _hash(x + 17, y, seed_value) % 3 == 0:
							result[x][y - 2] = true
		Mood.EPIC:
			# Pair dramatic crown/shoulder protrusions, even on irregular bodies.
			var top: int = height
			var left: int = width
			for x in width:
				for y in height:
					if original[x][y]:
						top = mini(top, y)
						left = mini(left, x)
			if top < height:
				for step in range(1, mini(5, top + 1)):
					_set_pair(result, maxi(1, width / 2 - 5 - step / 2), top - step, true)
				for step in range(1, 4):
					_set_pair(result, maxi(1, left - step), mini(height - 2, top + 7 + step / 2), true)
	return result


static func _hash(x: int, y: int, seed_value: int) -> int:
	return posmod(x * 7919 + y * 104729 + posmod(seed_value, 2147483647), 2147483647)


static func _neighbors(map: Array[Variant], x: int, y: int) -> int:
	var count: int = 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			if map[x + dx][y + dy]:
				count += 1
	return count


static func _set_pair(map: Array[Variant], x: int, y: int, filled: bool) -> void:
	if x >= 0 and x < map.size() and y >= 0 and y < map[0].size():
		map[x][y] = filled
		map[map.size() - 1 - x][y] = filled
