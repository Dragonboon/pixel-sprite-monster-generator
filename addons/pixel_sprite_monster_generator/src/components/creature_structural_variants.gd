class_name CreatureStructuralVariants
extends RefCounted

## Stable, seed-driven silhouettes. Spirit gets six true body plans; the other
## families receive recognizable appendage/volume variants.
## A separate RNG isolates this pass from geometry and color generation.
const SPIRIT_NAMES: Array[String] = ["Wisp", "Jelly", "Wraith", "Mask", "Flame", "Crowned"]


static func sample(archetype: int, seed_value: int, mood: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x4B1D93
	var subtype_count: int = 6 if archetype == CreatureMorphology.Archetype.SPIRIT else 4
	var subtype: int = posmod(seed_value, subtype_count)
	var stretch: float = rng.randf_range(0.82, 1.23)
	var spread: float = rng.randf_range(0.75, 1.32)
	var trail: float = rng.randf_range(0.72, 1.40)
	match mood:
		CreatureMood.Mood.COZY:
			stretch *= 0.86
			spread *= 1.09
			trail *= 0.74
		CreatureMood.Mood.HORROR:
			stretch *= 1.18
			spread *= 0.87
			trail *= 1.31
		CreatureMood.Mood.EPIC:
			spread *= 1.24
			trail *= 1.18
	return {
		"subtype": subtype,
		"name": SPIRIT_NAMES[subtype] if archetype == CreatureMorphology.Archetype.SPIRIT else "Variant %d" % [subtype + 1],
		"stretch": clampf(stretch, 0.65, 1.55),
		"spread": clampf(spread, 0.62, 1.70),
		"trail": clampf(trail, 0.50, 1.90),
		"bend": rng.randi_range(-4, 4),
		"tilt": rng.randi_range(-3, 3),
		"lobes": rng.randi_range(2, 6),
		"ornament": rng.randi_range(0, 3)
	}


static func apply(source: Array[Variant], archetype: int, amount: float, proportions: Dictionary, shape: Dictionary, seed_value: int) -> Array[Variant]:
	if source.is_empty() or source[0].is_empty() or shape.is_empty() or amount <= 0.0:
		return source.duplicate(true)
	var w: int = source.size()
	var h: int = source[0].size()
	if w < 14 or h < 14:
		return source.duplicate(true)
	if archetype == CreatureMorphology.Archetype.SPIRIT:
		return _spirit(source, amount, proportions, shape, seed_value)
	var map: Array[Variant] = source.duplicate(true)
	var cx: int = w / 2
	var cy: int = h / 2
	var rx: int = maxi(3, roundi(float(w) * float(proportions.get("body_width", 0.44)) * amount * 0.5))
	var ry: int = maxi(3, roundi(float(h) * float(proportions.get("body_height", 0.52)) * amount * 0.5))
	var extend: int = maxi(3, roundi(float(h) * 0.18 * float(shape["trail"]) * amount))
	var subtype: int = int(shape["subtype"])
	var bend: int = int(shape["bend"])
	match archetype:
		CreatureMorphology.Archetype.INSECTOID:
			match subtype:
				0: # Beetle shoulders and broad carapace.
					_ellipse(map, cx, cy + ry / 3, maxi(3, roundi(float(rx) * 1.3)), maxi(2, ry / 2), seed_value)
				1: # Stag beetle mandibles, linked to head.
					for side in [-1, 1]:
						_line(map, cx + side * 3, cy - ry, cx + side * (5 + extend / 2), cy - ry - extend, 2)
						_line(map, cx + side * (5 + extend / 2), cy - ry - extend, cx + side * 3, cy - ry - extend - 2, 1)
				2: # Mantis forearms, wide elbows.
					for side in [-1, 1]:
						_line(map, cx + side * rx / 2, cy - ry / 3, cx + side * (rx + extend), cy - ry / 2, 2)
						_line(map, cx + side * (rx + extend), cy - ry / 2, cx + side * (rx + extend / 2), cy + ry / 4, 2)
				3: # Narrow wasp lower body and abdominal stinger.
					_ellipse(map, cx, cy + ry, maxi(2, rx * 2 / 3), maxi(3, ry * 3 / 4), seed_value)
					_line(map, cx, cy + ry, cx + bend / 2, cy + ry + extend, 2)
		CreatureMorphology.Archetype.QUADRUPED:
			match subtype:
				0: # Thick mammal-like hump.
					_ellipse(map, cx - rx / 4, cy - ry / 2, maxi(3, rx * 2 / 3), maxi(3, ry), seed_value)
				1: # Backward lifted branching tail.
					_line(map, cx - rx, cy, cx - rx - extend, cy - ry / 2 - extend / 2, 2)
					_line(map, cx - rx - extend, cy - ry / 2 - extend / 2, cx - rx - extend - 3, cy - ry / 2 - extend, 2)
				2: # Small horns or ears on the forward head.
					for side in [-1, 1]:
						_line(map, cx + rx + side * 3, cy - ry, cx + rx + side * 5, cy - ry - extend / 2, 2)
				3: # Heavy neck and prominent muzzle.
					_ellipse(map, cx + rx / 2, cy - ry / 2, maxi(2, rx / 2), maxi(2, ry * 3 / 4), seed_value)
					_ellipse(map, cx + rx + extend / 3, cy - ry, maxi(2, extend / 2), maxi(2, ry / 3), seed_value)
		CreatureMorphology.Archetype.GOLEM:
			match subtype:
				0: # Broad slab shoulders.
					_rect(map, cx - rx - extend / 2, cy - ry / 2, cx + rx + extend / 2, cy - ry / 4)
				1: # Raised asymmetric hammer fist, still linked.
					_line(map, cx - rx, cy, cx - rx - extend, cy + ry / 2, maxi(3, w / 14))
					_ellipse(map, cx - rx - extend, cy + ry / 2, maxi(2, extend / 2), maxi(3, ry / 2), seed_value)
				2: # Angular crown/headstone.
					for side in [-1, 1]:
						_line(map, cx + side * maxi(2, rx / 3), cy - ry, cx + side * maxi(3, rx / 2), cy - ry - extend / 2, 3)
				3: # Long pillar arms and broad stone gauntlets.
					for side in [-1, 1]:
						_line(map, cx + side * rx, cy - ry / 3, cx + side * (rx + extend / 2), cy + ry, maxi(3, w / 16))
						_ellipse(map, cx + side * (rx + extend / 2), cy + ry, maxi(3, extend / 2), maxi(3, ry / 2), seed_value)
		CreatureMorphology.Archetype.BIPED:
			match subtype:
				0:
					_ellipse(map, cx, cy - ry, maxi(2, rx / 2), maxi(2, ry / 2), seed_value)
				1:
					for side in [-1, 1]:
						_line(map, cx + side * rx / 2, cy - ry, cx + side * (rx + extend / 2), cy - ry - extend / 2, 2)
				2:
					_ellipse(map, cx, cy + ry / 3, maxi(3, rx + 2), maxi(3, ry / 2), seed_value)
				3:
					for side in [-1, 1]:
						_line(map, cx + side * rx, cy, cx + side * (rx + extend), cy + extend / 3, 2)
		CreatureMorphology.Archetype.SLIME:
			match subtype:
				0:
					_ellipse(map, cx - rx / 2, cy - ry / 3, maxi(3, rx * 3 / 4), maxi(3, ry / 2), seed_value)
				1:
					_ellipse(map, cx + rx / 2, cy + ry / 4, maxi(3, rx * 3 / 4), maxi(3, ry * 3 / 4), seed_value)
				2:
					_line(map, cx - rx / 2, cy + ry / 2, cx - rx / 2 - bend, cy + ry + extend / 2, maxi(2, w / 20))
				3:
					_ellipse(map, cx, cy - ry / 2, maxi(3, rx / 2), maxi(3, ry), seed_value)
		CreatureMorphology.Archetype.WINGED:
			match subtype:
				0:
					for side in [-1, 1]:
						_line(map, cx + side * rx, cy, cx + side * (rx + extend), cy - ry, 3)
				1:
					for side in [-1, 1]:
						_line(map, cx + side * rx, cy, cx + side * (rx + extend), cy + ry / 2, 2)
				2:
					for side in [-1, 1]:
						_ellipse(map, cx + side * (rx + extend / 2), cy - ry / 2, maxi(2, extend / 2), maxi(3, ry / 2), seed_value)
				3:
					_line(map, cx, cy + ry / 2, cx + bend, cy + ry + extend, 2)
	return map


static func _spirit(source: Array[Variant], amount: float, proportions: Dictionary, shape: Dictionary, seed_value: int) -> Array[Variant]:
	var w: int = source.size()
	var h: int = source[0].size()
	var map: Array[Variant] = []
	for x in w:
		var col: Array[bool] = []
		col.resize(h)
		col.fill(false)
		map.append(col)
	var cx: int = w / 2 + int(shape["tilt"]) / 2
	var cy: int = h / 2
	var base_rx: int = maxi(4, roundi(float(w) * float(proportions.get("body_width", 0.44)) * float(shape["spread"]) * amount * 0.5))
	var base_ry: int = maxi(4, roundi(float(h) * float(proportions.get("body_height", 0.52)) * float(shape["stretch"]) * amount * 0.5))
	var trail: int = maxi(4, roundi(float(h) * float(proportions.get("appendage", 0.24)) * float(shape["trail"]) * amount))
	var bend: int = int(shape["bend"])
	var subtype: int = int(shape["subtype"])
	match subtype:
		0: # Wisp: round buoyant mass with one curled streamer.
			_ellipse(map, cx, cy - 4, maxi(3, base_rx * 3 / 4), maxi(3, base_ry * 2 / 3), seed_value)
			_line(map, cx, cy + base_ry / 3 - 3, cx + bend, cy + base_ry + trail / 2, maxi(2, w / 20))
			_line(map, cx + bend, cy + base_ry + trail / 2, cx + bend + 3, cy + base_ry + trail / 2 + 2, 2)
		1: # Jelly: wide bell with four to six separate, anchored tentacles.
			_ellipse(map, cx, cy - base_ry / 3, maxi(5, base_rx + 3), maxi(3, base_ry / 2), seed_value)
			var tentacles: int = int(shape["lobes"])
			for i in tentacles:
				var root_x: int = cx + roundi(float(i * 2 - (tentacles - 1)) * float(base_rx) / float(maxi(2, tentacles)))
				var end_x: int = root_x + posmod(seed_value + i * 7, 5) - 2
				_line(map, root_x, cy - base_ry / 4, end_x, cy + base_ry / 2 + trail + (i % 3) * 2, 2)
		2: # Wraith: narrow towering hood, trailing torn robe.
			_ellipse(map, cx, cy - base_ry / 2, maxi(3, base_rx * 2 / 3), maxi(5, base_ry), seed_value)
			for i in 3:
				var root_x: int = cx + (i - 1) * maxi(2, base_rx / 2)
				_line(map, root_x, cy + base_ry / 4, root_x + (i - 1) * 3 + bend / 2, cy + base_ry + trail / 2 + i * 2, maxi(2, w / 22))
		3: # Mask: squared, angular head with stepped, small hanging veil.
			_rect(map, cx - base_rx * 3 / 4, cy - base_ry, cx + base_rx * 3 / 4, cy + base_ry / 4)
			for i in 3:
				var mask_x: int = cx + (i - 1) * maxi(2, base_rx / 2)
				_line(map, mask_x, cy, mask_x + (i - 1) * 3, cy + base_ry / 2 + trail / 3, 2)
			for side in [-1, 1]:
				_line(map, cx + side * base_rx * 2 / 3, cy - base_ry / 2, cx + side * (base_rx + 2), cy - base_ry, 2)
		4: # Flame: narrowing vertical body with rising spikes and side licks.
			_ellipse(map, cx, cy, maxi(3, base_rx * 2 / 3), maxi(4, base_ry), seed_value)
			_line(map, cx, cy - base_ry / 2, cx + bend, cy - base_ry - maxi(4, trail / 2), 3)
			for side in [-1, 1]:
				_line(map, cx + side * base_rx / 3, cy + base_ry / 2, cx + side * (base_rx + 2), cy - base_ry / 3, 3)
				_line(map, cx + side * (base_rx + 2), cy - base_ry / 3, cx + side * (base_rx + 1), cy - base_ry / 2, 2)
			_line(map, cx, cy + base_ry / 2, cx + bend / 2, cy + base_ry + trail / 2, 2)
		5: # Crowned: broad shoulders, central plume, paired crown horns.
			_ellipse(map, cx, cy - base_ry / 3, maxi(5, base_rx), maxi(4, base_ry * 3 / 4), seed_value)
			for side in [-1, 1]:
				_line(map, cx + side * base_rx / 2, cy - base_ry / 2, cx + side * (base_rx + 2), cy - base_ry - trail / 3, 3)
				_line(map, cx + side * base_rx / 2, cy + base_ry / 3, cx + side * (base_rx / 2 + 2 + bend / 3), cy + base_ry + trail / 2, 2)
			_line(map, cx, cy - base_ry / 2, cx, cy - base_ry - maxi(3, trail / 3), 3)
	# Keep silhouettes connected at their joints while preserving distinct tips.
	return map


static func _rect(map: Array[Variant], left: int, top: int, right: int, bottom: int) -> void:
	for x in range(maxi(0, left), mini(map.size(), right + 1)):
		for y in range(maxi(0, top), mini(map[0].size(), bottom + 1)):
			map[x][y] = true


static func _ellipse(map: Array[Variant], cx: int, cy: int, rx: int, ry: int, seed_value: int) -> void:
	rx = maxi(2, rx)
	ry = maxi(2, ry)
	for x in range(maxi(0, cx - rx), mini(map.size(), cx + rx + 1)):
		for y in range(maxi(0, cy - ry), mini(map[0].size(), cy + ry + 1)):
			var px: float = float(x - cx) / float(rx)
			var py: float = float(y - cy) / float(ry)
			var ripple: float = 0.045 * sin(float(y) * 0.71 + float(posmod(seed_value, 97)) * 0.27)
			if px * px + py * py < 0.96 + ripple:
				map[x][y] = true


static func _line(map: Array[Variant], x0: int, y0: int, x1: int, y1: int, thickness: int) -> void:
	var steps: int = maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in range(steps + 1):
		var x: int = roundi(lerpf(float(x0), float(x1), float(i) / float(steps)))
		var y: int = roundi(lerpf(float(y0), float(y1), float(i) / float(steps)))
		for dx in range(-thickness / 2, (thickness + 1) / 2):
			for dy in range(-thickness / 2, (thickness + 1) / 2):
				var xx: int = x + dx
				var yy: int = y + dy
				if xx >= 0 and yy >= 0 and xx < map.size() and yy < map[0].size():
					map[xx][yy] = true
