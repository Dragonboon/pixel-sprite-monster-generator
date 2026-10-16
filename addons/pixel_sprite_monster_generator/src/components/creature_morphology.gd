class_name CreatureMorphology
extends RefCounted

## Explicit, optional anatomy rules applied after cellular smoothing.
## Operates on the same x-major boolean map as MapGenerator.
enum Archetype { ORIGINAL, BIPED, INSECTOID, SLIME, WINGED }


static func apply(source: Array[Variant], archetype: Archetype, amount: float, seed_value: int, eyes: bool = false) -> Array[Variant]:
	var result: Array[Variant] = source.duplicate(true)
	if result.is_empty() or result[0].is_empty():
		return result
	amount = clampf(amount, 0.0, 1.0)
	if archetype == Archetype.ORIGINAL or amount <= 0.0:
		return result
	var width: int = result.size()
	var height: int = result[0].size()
	var left: int = width
	var right: int = -1
	var top: int = height
	var bottom: int = -1
	for x in width:
		for y in height:
			if result[x][y]:
				left = mini(left, x)
				right = maxi(right, x)
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if right < left:
		return result
	var span_x: int = right - left + 1
	var span_y: int = bottom - top + 1
	var middle: int = width / 2
	var length: int = maxi(1, roundi(float(mini(span_x, span_y)) * amount * 0.19))
	var variation: int = posmod(seed_value, 3)

	match archetype:
		Archetype.BIPED:
			# Separate lower legs, then grow connected arms from the mid-body.
			var gap: int = maxi(1, roundi(float(span_x) * 0.08 * amount))
			for y in range(top + roundi(float(span_y) * 0.73), bottom + 1):
				for dx in range(-gap, gap + 1):
					_write(result, middle + dx, y, false)
			for y in range(top + roundi(float(span_y) * 0.45), top + roundi(float(span_y) * 0.45) + 2):
				for step in length:
					_pair(result, left - step, y + step / 3, true)
		Archetype.INSECTOID:
			# Antennae and three paired legs, with a small seeded variation.
			for offset in [2 + variation, 5 + variation]:
				for step in range(1, length + 2):
					_pair(result, middle - offset, top - step, true)
				_write(result, middle - offset, top, true)
				_write(result, width - 1 - (middle - offset), top, true)
			for leg in 3:
				var y: int = top + roundi(float(span_y) * (0.42 + 0.16 * float(leg)))
				for step in length + 1:
					_pair(result, left - step, y + (leg - 1) * step / 2, true)
		Archetype.SLIME:
			# Dome: central crown, tapered shoulders and a stable flat base.
			var radius: float = maxf(1.0, float(span_x - 1) * 0.5)
			for x in range(left, right + 1):
				var normalized: float = absf(float(x) - float(left + right) * 0.5) / radius
				var cap: int = top + roundi(pow(normalized, 1.7) * float(span_y) * 0.4 * amount)
				for y in range(top, mini(bottom + 1, cap)):
					_write(result, x, y, false)
			for x in range(left + 1, right):
				_write(result, x, bottom, true)
		Archetype.WINGED:
			# Wings remain connected to the torso and widen away from the body.
			var wing_y: int = top + roundi(float(span_y) * 0.32)
			for step in range(length + 3):
				var wing_height: int = maxi(1, roundi(float(length + 2 - step) * 0.8))
				for dy in wing_height:
					_pair(result, left - step, wing_y - dy + step / 3, true)
		_:
			pass
	if eyes:
		_add_eye_pockets(result, top, bottom, left, right)
	return result


static func _write(map: Array[Variant], x: int, y: int, value: bool) -> void:
	if x >= 0 and x < map.size() and y >= 0 and y < map[0].size():
		map[x][y] = value


static func _pair(map: Array[Variant], left_x: int, y: int, value: bool) -> void:
	_write(map, left_x, y, value)
	_write(map, map.size() - 1 - left_x, y, value)


static func _add_eye_pockets(map: Array[Variant], top: int, bottom: int, left: int, right: int) -> void:
	if bottom - top < 11 or right - left < 11:
		return
	var width: int = map.size()
	var y: int = top + roundi(float(bottom - top) * 0.35)
	var x: int = width / 2 - maxi(2, roundi(float(right - left) * 0.13))
	# Only remove interior pixels, never punch holes through an external contour.
	for eye_x in [x, width - 1 - x]:
		if eye_x <= 1 or eye_x >= width - 2 or y <= 1 or y >= map[0].size() - 2:
			continue
		var enclosed: bool = true
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not map[eye_x + offset.x][y + offset.y]:
				enclosed = false
		if enclosed:
			map[eye_x][y] = false
