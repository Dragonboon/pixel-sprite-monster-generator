class_name CreatureSpeciesFinish
extends RefCounted

## CPU-equivalent stages keep PNG export deterministic and available headlessly.
## A separate canvas shader can preview the final edge lighting in Godot.
enum Stage { RAW_MASK, FLAT, VOLUME, SHADER }
const BAYER_4 := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

static func paint(mask: Image, palette: PackedColorArray, stage: int, seed_value: int = 0) -> Image:
	var w: int = mask.get_width()
	var h: int = mask.get_height()
	var result := Image.create(w, h, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	if stage == Stage.RAW_MASK:
		for y in h:
			for x in w:
				if mask.get_pixel(x, y).a > 0.5:
					result.set_pixel(x, y, Color.WHITE)
		return result
	var top := PackedInt32Array()
	var bottom := PackedInt32Array()
	var left := PackedInt32Array()
	var right := PackedInt32Array()
	top.resize(w)
	bottom.resize(w)
	left.resize(h)
	right.resize(h)
	for x in w:
		top[x] = h
		bottom[x] = -1
		for y in h:
			if mask.get_pixel(x, y).a > 0.5:
				top[x] = mini(top[x], y)
				bottom[x] = y
	for y in h:
		left[y] = w
		right[y] = -1
		for x in w:
			if mask.get_pixel(x, y).a > 0.5:
				left[y] = mini(left[y], x)
				right[y] = x
	for y in h:
		for x in w:
			if mask.get_pixel(x, y).a <= 0.5:
				continue
			var outside_left: bool = x == 0 or mask.get_pixel(x - 1, y).a <= 0.5
			var outside_right: bool = x + 1 >= w or mask.get_pixel(x + 1, y).a <= 0.5
			var outside_up: bool = y == 0 or mask.get_pixel(x, y - 1).a <= 0.5
			var outside_down: bool = y + 1 >= h or mask.get_pixel(x, y + 1).a <= 0.5
			if outside_left or outside_right or outside_up or outside_down:
				result.set_pixel(x, y, palette[0])
				continue
			if stage == Stage.FLAT:
				result.set_pixel(x, y, palette[2])
				continue
			# All ratios refer to occupied spans, not a fixed image Y threshold.
			# Ordered dithering prevents a hard horizontal band where the tone changes.
			var vertical: float = float(y - top[x]) / float(maxi(1, bottom[x] - top[x]))
			var horizontal: float = float(x - left[y]) / float(maxi(1, right[y] - left[y]))
			var lightness: float = 0.54 + 0.16 * (0.5 - vertical) + 0.13 * (0.5 - horizontal)
			var local_edge: float = 0.0
			for step in range(1, 4):
				if y - step >= 0 and mask.get_pixel(x, y - step).a <= 0.5:
					local_edge += 0.065 / float(step)
				if x - step >= 0 and mask.get_pixel(x - step, y).a <= 0.5:
					local_edge += 0.047 / float(step)
				if y + step < h and mask.get_pixel(x, y + step).a <= 0.5:
					local_edge -= 0.047 / float(step)
			var dither: float = (float(BAYER_4[(y % 4) * 4 + x % 4]) - 7.5) / 16.0
			var value: float = lightness + local_edge + dither * 0.14
			var chosen: Color = palette[2]
			if value < 0.46:
				chosen = palette[1]
			elif value > 0.61:
				chosen = palette[3]
			result.set_pixel(x, y, chosen)
	return result


## Matched to species_finish.gdshader: alpha-based edge highlights,
## no image-space Y cuts, no blur and unchanged silhouette/alpha.
static func apply_shader(source: Image, strength: float = 0.7) -> Image:
	if source == null:
		return null
	var result := source.duplicate()
	var w: int = source.get_width()
	var h: int = source.get_height()
	var amount: float = clampf(strength, 0.0, 1.0)
	for y in h:
		for x in w:
			var original: Color = source.get_pixel(x, y)
			if original.a < 0.5:
				continue
			var upper: float = 0.0 if y == 0 else source.get_pixel(x, y - 1).a
			var lower: float = 0.0 if y + 1 >= h else source.get_pixel(x, y + 1).a
			var left: float = 0.0 if x == 0 else source.get_pixel(x - 1, y).a
			var right: float = 0.0 if x + 1 >= w else source.get_pixel(x + 1, y).a
			var rim: float = (2.0 - upper - left) * 0.09 * amount
			var occlusion: float = (2.0 - lower - right) * 0.07 * amount
			var changed: Color = original.lightened(rim).darkened(occlusion)
			changed.a = original.a
			result.set_pixel(x, y, changed)
	return result


static func horizontal_band_score(image: Image) -> float:
	## Largest cross-body jump in mean brightness. Used as a regression heuristic,
	## not as a strict quality score (some species intentionally have stripes).
	var previous: float = -1.0
	var maximum: float = 0.0
	var w: int = image.get_width()
	var h: int = image.get_height()
	for y in range(2, h - 2):
		var total: float = 0.0
		var occupied: int = 0
		for x in w:
			var color: Color = image.get_pixel(x, y)
			if color.a >= 0.5:
				total += color.get_luminance()
				occupied += 1
		if occupied < maxi(6, w / 5):
			continue
		var mean: float = total / float(occupied)
		if previous >= 0.0:
			maximum = maxf(maximum, absf(mean - previous))
		previous = mean
	return maximum
