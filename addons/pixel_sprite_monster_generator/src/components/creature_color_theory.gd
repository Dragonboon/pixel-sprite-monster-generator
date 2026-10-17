class_name CreatureColorTheory
extends RefCounted

## Consistent palettes: tonal hierarchy + hue harmony rather than unrelated RGB.
## The golden-ratio conjugate distributes base hues between seeds; a coherent
## hue relationship (analogous, complement, triad...) determines each palette.
enum Harmony { AUTO, MONOCHROMATIC, ANALOGOUS, COMPLEMENTARY, SPLIT_COMPLEMENTARY, TRIADIC, TETRADIC, NEUTRAL_ACCENT }
enum CountMode { MAXIMUM, EXACT }

const GOLDEN_RATIO_CONJUGATE: float = 0.618033988749895
const MAX_COLORS: int = 64


static func build(seed_value: int, requested: int, harmony: Harmony, mood: int, archetype: int, saturation: float = 0.65, value: float = 0.88) -> Dictionary:
	var n: int = clampi(requested, 1, MAX_COLORS)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x51BC07
	var chosen: Harmony = harmony
	if chosen == Harmony.AUTO:
		chosen = _auto_harmony(mood, archetype)
	# Stable golden-angle sequence distributes *base* hues, whereas intervals
	# in _hue_offset maintain harmonious relationships within a palette.
	var base_hue: float = fposmod(rng.randf() + float(posmod(seed_value, 997)) * GOLDEN_RATIO_CONJUGATE, 1.0)
	var sat: float = clampf(saturation, 0.2, 0.95)
	var value_cap: float = clampf(value, 0.38, 1.0)
	if mood == CreatureMood.Mood.COZY:
		sat *= 0.76
	elif mood == CreatureMood.Mood.HORROR:
		sat *= 0.85
		value_cap *= 0.80
	elif mood == CreatureMood.Mood.EPIC:
		sat = minf(0.95, sat * 1.12)
	var colors := PackedColorArray()
	for i in n:
		var position: float = float(i) / float(maxi(1, n - 1))
		var hue: float = fposmod(base_hue + _hue_offset(chosen, i, n), 1.0)
		var brightness: float = lerpf(0.24, value_cap, position)
		var local_sat: float = sat
		if chosen == Harmony.NEUTRAL_ACCENT and i < n - 2:
			local_sat = 0.10 + 0.06 * float(i % 3)
		elif chosen == Harmony.MONOCHROMATIC:
			local_sat = sat * (0.7 + 0.25 * position)
		if i == 0 and n > 1:
			brightness = 0.16
			local_sat *= 0.70
		elif i == n - 1 and n > 2:
			brightness = minf(1.0, value_cap + 0.12)
			local_sat *= 0.60
		elif i == n - 2 and n > 3:
			local_sat = minf(0.96, sat * 1.20)
		if n == 1:
			brightness = value_cap * 0.75
		colors.append(Color.from_hsv(hue, clampf(local_sat, 0.0, 1.0), clampf(brightness, 0.0, 1.0)))
	return {
		"colors": colors,
		"harmony": chosen,
		"roles": {
			"outline": 0,
			"shadow": 0 if n < 3 else 1,
			"body": maxi(0, n / 2),
			"secondary": maxi(0, n - 3),
			"accent": maxi(0, n - 2),
			"highlight": n - 1
		}
	}


static func _auto_harmony(mood: int, archetype: int) -> Harmony:
	if mood == CreatureMood.Mood.COZY:
		return Harmony.ANALOGOUS
	if mood == CreatureMood.Mood.HORROR:
		return Harmony.SPLIT_COMPLEMENTARY
	if mood == CreatureMood.Mood.EPIC:
		return Harmony.TRIADIC
	match archetype:
		CreatureMorphology.Archetype.GOLEM:
			return Harmony.NEUTRAL_ACCENT
		CreatureMorphology.Archetype.SPIRIT:
			return Harmony.ANALOGOUS
		CreatureMorphology.Archetype.INSECTOID:
			return Harmony.COMPLEMENTARY
		_:
			return Harmony.ANALOGOUS


static func _hue_offset(harmony: Harmony, index: int, n: int) -> float:
	if n < 3:
		return 0.0
	var band: int = index % 4
	match harmony:
		Harmony.MONOCHROMATIC:
			return 0.0
		Harmony.ANALOGOUS:
			return (float(band) - 1.5) * 0.035
		Harmony.COMPLEMENTARY:
			return 0.50 if band >= 2 else 0.0
		Harmony.SPLIT_COMPLEMENTARY:
			return 0.42 if band == 2 else (0.58 if band == 3 else 0.0)
		Harmony.TRIADIC:
			return float(index % 3) / 3.0
		Harmony.TETRADIC:
			return float(band) * 0.25
		Harmony.NEUTRAL_ACCENT:
			return 0.48 if index >= n - 2 else 0.0
		_:
			return 0.0


## Apply after shading and detail compositing to bound *visible* PNG colors.
## Transparent pixels are never recolored. EXACT can only be reached when
## >= N opaque pixels exist; check count_opaque_colors() in that edge case.
static func quantize(source: Image, palette: PackedColorArray, mode: CountMode) -> Image:
	if source == null:
		return null
	if palette.is_empty():
		return source.duplicate()
	var w: int = source.get_width()
	var h: int = source.get_height()
	var result := Image.create(w, h, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var assigned := PackedInt32Array()
	assigned.resize(w * h)
	assigned.fill(-1)
	var usage := PackedInt32Array()
	usage.resize(palette.size())
	usage.fill(0)
	var opaque_count: int = 0
	for y in h:
		for x in w:
			var color: Color = source.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			opaque_count += 1
			var chosen: int = _closest(color, palette)
			assigned[y * w + x] = chosen
			usage[chosen] += 1
			result.set_pixel(x, y, Color(palette[chosen].r, palette[chosen].g, palette[chosen].b, color.a))
	if mode == CountMode.EXACT and opaque_count >= palette.size():
		# Deterministically place unused role colors in closest interior pixels
		# whose current color has more than one instance.
		for role in palette.size():
			if usage[role] != 0:
				continue
			var best_index: int = -1
			var best_distance: float = INF
			for y in h:
				for x in w:
					var index: int = y * w + x
					var previous: int = assigned[index]
					if previous < 0 or usage[previous] <= 1:
						continue
					var interior: bool = x > 0 and y > 0 and x + 1 < w and y + 1 < h
					if interior:
						interior = assigned[index - 1] >= 0 and assigned[index + 1] >= 0 and assigned[index - w] >= 0 and assigned[index + w] >= 0
					var penalty: float = 0.0 if interior else 10.0
					var candidate: float = _distance(source.get_pixel(x, y), palette[role]) + penalty
					if candidate < best_distance:
						best_distance = candidate
						best_index = index
			if best_index < 0:
				break
			usage[assigned[best_index]] -= 1
			usage[role] += 1
			assigned[best_index] = role
			var at_x: int = best_index % w
			var at_y: int = best_index / w
			var alpha: float = source.get_pixel(at_x, at_y).a
			result.set_pixel(at_x, at_y, Color(palette[role].r, palette[role].g, palette[role].b, alpha))
	return result


static func count_opaque_colors(source: Image) -> int:
	if source == null:
		return 0
	var unique: Dictionary = {}
	for y in source.get_height():
		for x in source.get_width():
			var pixel: Color = source.get_pixel(x, y)
			if pixel.a > 0.0:
				unique[pixel.to_html(false)] = true
	return unique.size()


static func _closest(color: Color, palette: PackedColorArray) -> int:
	var best: int = 0
	var best_distance: float = INF
	for i in palette.size():
		var dist: float = _distance(color, palette[i])
		if dist < best_distance:
			best_distance = dist
			best = i
	return best


static func _distance(a: Color, b: Color) -> float:
	# Weighted RGB distance, with slightly higher green/luminance sensitivity.
	var dr: float = a.r - b.r
	var dg: float = a.g - b.g
	var db: float = a.b - b.b
	return 0.30 * dr * dr + 0.59 * dg * dg + 0.11 * db * db
