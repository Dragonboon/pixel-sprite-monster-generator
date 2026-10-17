class_name CreatureAnatomyRefiner
extends RefCounted

## Second-generation connected morphology for selected procedural families.
## Keeps the legacy silhouette available for a same-seed A/B comparison.
## The source cellular map modulates the boundary without owning the anatomy.

static func supports(archetype: int) -> bool:
	return archetype in [
		CreatureMorphology.Archetype.INSECTOID,
		CreatureMorphology.Archetype.QUADRUPED,
		CreatureMorphology.Archetype.GOLEM,
		CreatureMorphology.Archetype.SPIRIT
	]


static func refine(source: Array[Variant], archetype: int, strength: float, proportions: Dictionary, seed_value: int) -> Array[Variant]:
	if not supports(archetype) or strength <= 0.0 or source.is_empty() or source[0].is_empty():
		return source.duplicate(true)
	var width: int = source.size()
	var height: int = source[0].size()
	var result: Array[Variant] = []
	for x in width:
		var column: Array[bool] = []
		column.resize(height)
		column.fill(false)
		result.append(column)
	var cx: int = width / 2
	var cy: int = height / 2
	var factor: float = clampf(strength, 0.35, 1.0)
	var rx: int = maxi(3, roundi(float(width) * float(proportions.get("body_width", 0.44)) * 0.5 * factor))
	var ry: int = maxi(3, roundi(float(height) * float(proportions.get("body_height", 0.52)) * 0.5 * factor))
	var head: int = maxi(2, roundi(float(width) * float(proportions.get("head", 0.25)) * 0.5 * factor))
	var length: int = maxi(3, roundi(float(height) * float(proportions.get("appendage", 0.24)) * factor))
	var offset: int = posmod(seed_value, 5) - 2
	match archetype:
		CreatureMorphology.Archetype.INSECTOID:
			# Pronounced three-part segmentation, six articulated legs, antennae.
			_blob(result, source, cx, cy + ry / 2, maxi(3, rx - 1), maxi(3, ry * 2 / 3), seed_value)
			_blob(result, source, cx, cy - ry / 3, maxi(3, rx * 2 / 3), maxi(3, ry * 2 / 3), seed_value + 3)
			_blob(result, source, cx, cy - ry - head / 2, head, head, seed_value + 7)
			_segment(result, cx, cy - ry, cx, cy - ry + head, 2)
			for side in [-1, 1]:
				var antenna_base: int = cx + side * maxi(1, head / 2)
				_segment(result, antenna_base, cy - ry - head, antenna_base + side * 2, cy - ry - head - maxi(3, length / 2), 2)
				for leg_index in 3:
					var attach_y: int = cy - ry / 2 + leg_index * maxi(2, ry / 2)
					var elbow_x: int = cx + side * (rx + maxi(2, length / 3))
					var elbow_y: int = attach_y + (leg_index - 1) * maxi(2, length / 3)
					_segment(result, cx + side * (rx / 2), attach_y, elbow_x, elbow_y, 2)
					_segment(result, elbow_x, elbow_y, elbow_x + side * maxi(2, length / 3), elbow_y + maxi(2, length / 3), 2)
		CreatureMorphology.Archetype.QUADRUPED:
			# Side-reading body, raised neck and head, tail and four visible legs.
			_blob(result, source, cx, cy, maxi(4, rx + length / 4), maxi(3, ry * 2 / 3), seed_value)
			_segment(result, cx + rx / 2, cy - ry / 3, cx + rx, cy - ry, maxi(2, head / 2))
			_blob(result, source, cx + rx, cy - ry, head, maxi(2, head * 2 / 3), seed_value + 7)
			for leg_index in 4:
				var leg_x: int = cx + roundi(float(leg_index * 2 - 3) * float(rx) / 4.0)
				var foot_x: int = leg_x + (1 if leg_index >= 2 else -1) * (1 + posmod(seed_value + leg_index, 2))
				_segment(result, leg_x, cy + ry / 3, foot_x, cy + ry / 2 + length, maxi(2, width / 24))
			_segment(result, cx - rx, cy - ry / 5, cx - rx - maxi(3, length / 2), cy - ry / 2 + offset, 2)
		CreatureMorphology.Archetype.GOLEM:
			# Distinct rectangular chest, heavy shoulders/fists, broad planted feet.
			_block(result, cx - rx, cy - ry / 2, cx + rx, cy + ry / 2)
			_blob(result, source, cx, cy - ry, head, head, seed_value)
			for side in [-1, 1]:
				_blob(result, source, cx + side * rx, cy - ry / 3, maxi(3, head), maxi(3, ry / 2), seed_value + 2)
				_segment(result, cx + side * rx, cy, cx + side * (rx + maxi(2, length / 2)), cy + ry / 2, maxi(3, head / 2))
				_blob(result, source, cx + side * (rx + maxi(2, length / 2)), cy + ry / 2, maxi(2, head / 2), maxi(2, head / 2), seed_value + 5)
				var leg_x: int = cx + side * maxi(2, rx / 2)
				_segment(result, leg_x, cy + ry / 2, leg_x, cy + ry / 2 + length, maxi(3, width / 16))
				_segment(result, leg_x - maxi(1, width / 20), cy + ry / 2 + length, leg_x + maxi(2, width / 20), cy + ry / 2 + length, 3)
		CreatureMorphology.Archetype.SPIRIT:
			# Continuous upper body, trailing floating wisps rather than feet.
			_blob(result, source, cx, cy - ry / 3, rx, ry, seed_value)
			for wisp in 3:
				var start_x: int = cx + (wisp - 1) * maxi(2, rx / 2)
				var end_x: int = start_x + (posmod(seed_value + wisp * 7, 7) - 3) + (wisp - 1) * 2
				var tip_y: int = cy + ry / 2 + maxi(3, length - wisp * 2)
				_segment(result, start_x, cy + ry / 3, end_x, tip_y, maxi(2, width / 24))
				_segment(result, end_x, tip_y, end_x + (1 if wisp % 2 == 0 else -1) * 2, tip_y + maxi(1, length / 5), 2)
	return result


static func _blob(map: Array[Variant], source: Array[Variant], cx: int, cy: int, rx: int, ry: int, seed_value: int) -> void:
	var width: int = map.size()
	var height: int = map[0].size()
	for x in range(maxi(0, cx - rx - 1), mini(width, cx + rx + 2)):
		for y in range(maxi(0, cy - ry - 1), mini(height, cy + ry + 2)):
			var nx: float = float(x - cx) / float(rx)
			var ny: float = float(y - cy) / float(ry)
			# A small seed-dependent boundary perturbation retains the cellular
			# generator's character but never hollows out the body center.
			var boundary: float = 0.93 + 0.065 * sin(float(y) * 0.57 + float(seed_value % 101) * 0.11)
			boundary += 0.055 if source[x][y] else -0.025
			if nx * nx + ny * ny <= boundary:
				map[x][y] = true


static func _block(map: Array[Variant], left: int, top: int, right: int, bottom: int) -> void:
	for x in range(maxi(0, left), mini(map.size(), right + 1)):
		for y in range(maxi(0, top), mini(map[0].size(), bottom + 1)):
			map[x][y] = true


static func _segment(map: Array[Variant], x0: int, y0: int, x1: int, y1: int, thickness: int) -> void:
	var steps: int = maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in range(steps + 1):
		var x: int = roundi(lerpf(float(x0), float(x1), float(i) / float(steps)))
		var y: int = roundi(lerpf(float(y0), float(y1), float(i) / float(steps)))
		for dx in range(-thickness / 2, (thickness + 1) / 2):
			for dy in range(-thickness / 2, (thickness + 1) / 2):
				var px: int = x + dx
				var py: int = y + dy
				if px >= 0 and py >= 0 and px < map.size() and py < map[0].size():
					map[px][py] = true
