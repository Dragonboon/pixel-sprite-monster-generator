class_name CreatureSpeciesGenerator
extends RefCounted

## Standalone deterministic creature grammar. Does not alter the legacy generator.
## Images are native-resolution, padded RGBA8. No files, global RNG or GPU needed.
enum Form {
	HEAD, HEAD_LEGS, FISH, INSECT, QUADRUPED, WINGED_PAIR,
	COLONY, TENTACLED, BASED, BIPED_TAIL, BIPED,
	WINGED_DOUBLE, SERPENT, HEAD_ARMS
}
enum Element { NEUTRAL, FIRE, WATER, PLANT, ELECTRIC, EARTH, ICE, SHADOW }

const FORM_NAMES := [
	"floating_head", "head_with_legs", "fish", "insect", "quadruped",
	"two_wings", "colony", "tentacled", "anchored_body", "tailed_biped",
	"biped", "four_wings", "serpentine", "head_with_arms"
]
const ELEMENT_HUES := [0.10, 0.06, 0.55, 0.32, 0.14, 0.10, 0.52, 0.76]

static func sample(seed_value: int, form: int = -1, element: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x713EA5
	var chosen_form: int = form if form >= 0 and form < Form.size() else rng.randi_range(0, Form.size() - 1)
	var chosen_element: int = element if element >= 0 and element < Element.size() else rng.randi_range(0, Element.size() - 1)
	return {
		"schema_version": 1, "seed": seed_value, "form": chosen_form,
		"form_name": FORM_NAMES[chosen_form], "element": chosen_element,
		"body_width": rng.randf_range(0.82, 1.22),
		"body_height": rng.randf_range(0.82, 1.22),
		"head_scale": rng.randf_range(0.78, 1.32),
		"limb_length": rng.randf_range(0.72, 1.30),
		"eye_count": 1 if rng.randf() < 0.16 else 2,
		"eye_style": rng.randi_range(0, 3),
		"mouth": rng.randi_range(0, 2),
		"horns": rng.randi_range(0, 2),
		"pattern": rng.randi_range(0, 3),
		"accent_marks": rng.randi_range(2, 7),
		"tail": rng.randi_range(0, 2),
		"phase": rng.randi_range(0, 100000),
		"hue_shift": rng.randf_range(-0.055, 0.055)
	}

static func generate(seed_value: int, size: Vector2i = Vector2i(48, 48), form: int = -1, element: int = -1) -> Dictionary:
	return render(sample(seed_value, form, element), size)

static func render(genome: Dictionary, size: Vector2i = Vector2i(48, 48)) -> Dictionary:
	var w: int = clampi(size.x, 24, 128)
	var h: int = clampi(size.y, 24, 128)
	var image := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var mask := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	var form: int = clampi(int(genome.get("form", Form.BIPED)), 0, Form.size() - 1)
	var element: int = clampi(int(genome.get("element", Element.NEUTRAL)), 0, Element.size() - 1)
	var hue: float = fposmod(ELEMENT_HUES[element] + float(genome.get("hue_shift", 0.0)), 1.0)
	var outline := Color.from_hsv(hue, 0.35, 0.13)
	var shadow := Color.from_hsv(hue, 0.61, 0.39)
	var body := Color.from_hsv(hue, 0.62, 0.78)
	var light := Color.from_hsv(hue, 0.45, 0.96)
	var accent := Color.from_hsv(fposmod(hue + 0.39, 1.0), 0.73, 0.93)
	var eye := Color(0.97, 0.97, 0.88)
	var iris := Color(0.07, 0.10, 0.19)
	var bw: float = float(genome.get("body_width", 1.0))
	var bh: float = float(genome.get("body_height", 1.0))
	var hs: float = float(genome.get("head_scale", 1.0))
	var ll: float = float(genome.get("limb_length", 1.0))
	# Spatial coordinates are normalized to a 48x48 design grid.
	# All anatomy is drawn on an opaque semantic mask, then colored.
	match form:
		Form.HEAD:
			_ellipse(mask, 24, 24, 13 * bw, 12 * bh, Color.WHITE, w, h)
		Form.HEAD_LEGS:
			_legs(mask, [17.0, 31.0], 30, 42, ll, w, h)
			_ellipse(mask, 24, 22, 13 * bw, 12 * bh, Color.WHITE, w, h)
		Form.FISH:
			_line(mask, 9, 25, 3, 16, 5, w, h)
			_line(mask, 9, 25, 3, 34, 5, w, h)
			_ellipse(mask, 25, 25, 16 * bw, 9 * bh, Color.WHITE, w, h)
			_line(mask, 19, 19, 15, 10, 4, w, h)
			_line(mask, 22, 31, 17, 38, 4, w, h)
		Form.INSECT:
			_legs(mask, [12.0, 18.0, 30.0, 36.0], 26, 39, ll, w, h)
			_ellipse(mask, 24, 30, 11 * bw, 11 * bh, Color.WHITE, w, h)
			_ellipse(mask, 24, 17, 8 * hs, 8 * hs, Color.WHITE, w, h)
			_line(mask, 20, 12, 16, 5, 2, w, h)
			_line(mask, 28, 12, 32, 5, 2, w, h)
		Form.QUADRUPED:
			_legs(mask, [12.0, 18.0, 31.0, 36.0], 28, 42, ll, w, h)
			_ellipse(mask, 22, 27, 17 * bw, 9 * bh, Color.WHITE, w, h)
			_ellipse(mask, 35, 17, 8 * hs, 9 * hs, Color.WHITE, w, h)
			_line(mask, 9, 27, 3, 19, 3, w, h)
		Form.WINGED_PAIR, Form.WINGED_DOUBLE:
			_ellipse(mask, 12, 21, 11, 12, Color.WHITE, w, h)
			_ellipse(mask, 36, 21, 11, 12, Color.WHITE, w, h)
			if form == Form.WINGED_DOUBLE:
				_ellipse(mask, 10, 32, 8, 8, Color.WHITE, w, h)
				_ellipse(mask, 38, 32, 8, 8, Color.WHITE, w, h)
			_ellipse(mask, 24, 27, 8 * bw, 12 * bh, Color.WHITE, w, h)
			_ellipse(mask, 24, 14, 7 * hs, 7 * hs, Color.WHITE, w, h)
		Form.COLONY:
			for pos in [Vector2(17, 21), Vector2(29, 20), Vector2(23, 32), Vector2(32, 31)]:
				_ellipse(mask, pos.x, pos.y, 8 * bw, 8 * bh, Color.WHITE, w, h)
		Form.TENTACLED:
			for i in 5:
				_line(mask, 13 + i * 5, 26, 9 + i * 7, 42, 3, w, h)
			_ellipse(mask, 24, 21, 14 * bw, 12 * bh, Color.WHITE, w, h)
		Form.BASED:
			_line(mask, 24, 32, 24, 42, 8, w, h)
			_ellipse(mask, 24, 42, 13, 4, Color.WHITE, w, h)
			_ellipse(mask, 24, 21, 12 * bw, 13 * bh, Color.WHITE, w, h)
		Form.BIPED_TAIL, Form.BIPED:
			_legs(mask, [18.0, 30.0], 32, 43, ll, w, h)
			_line(mask, 17, 24, 8, 34, 5, w, h)
			_line(mask, 31, 24, 40, 34, 5, w, h)
			if form == Form.BIPED_TAIL:
				_line(mask, 30, 33, 43, 36, 5, w, h)
				_line(mask, 43, 36, 45, 29, 3, w, h)
			_ellipse(mask, 24, 29, 11 * bw, 12 * bh, Color.WHITE, w, h)
			_ellipse(mask, 24, 14, 10 * hs, 9 * hs, Color.WHITE, w, h)
		Form.SERPENT:
			_line(mask, 35, 13, 35, 29, 10, w, h)
			_line(mask, 35, 29, 17, 34, 10, w, h)
			_line(mask, 17, 34, 13, 41, 7, w, h)
			_ellipse(mask, 34, 13, 9 * hs, 9 * hs, Color.WHITE, w, h)
		Form.HEAD_ARMS:
			_line(mask, 16, 21, 5, 30, 7, w, h)
			_line(mask, 32, 21, 43, 30, 7, w, h)
			_ellipse(mask, 24, 24, 13 * bw, 13 * bh, Color.WHITE, w, h)
	# Paint interior in four semantic tones, preserving a dark 1px contour.
	for y in range(1, h + 1):
		for x in range(1, w + 1):
			if mask.get_pixel(x, y).a < 0.5:
				continue
			var border: bool = false
			for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if mask.get_pixel(x + delta.x, y + delta.y).a < 0.5:
					border = true
					break
			var tone := body
			if border:
				tone = outline
			elif y > h * 0.57:
				tone = shadow
			elif (x + y) % 9 == 0:
				tone = light
			image.set_pixel(x, y, tone)
	# Organic markings are reproducible and only touch deep interior cells.
	var rng := RandomNumberGenerator.new()
	rng.seed = int(genome.get("seed", 0)) ^ 0x4F8BC7
	var pattern: int = int(genome.get("pattern", 0))
	var marks: int = int(genome.get("accent_marks", 4)) * 3
	for i in marks:
		var x: int = rng.randi_range(5, w - 4)
		var y: int = rng.randi_range(7, h - 4)
		if pattern == 0 and i % 2 == 0:
			continue
		if pattern == 1:
			x = (x / 5) * 5
		elif pattern == 2:
			y = (y / 5) * 5
		_mark(image, mask, x, y, accent)
	# Attach horns/ears to a named head anchor, not to the global bounding box.
	var head_x: float = 34.0 if form == Form.QUADRUPED or form == Form.SERPENT else 24.0
	var head_y: float = 14.0 if form in [Form.BIPED, Form.BIPED_TAIL, Form.WINGED_PAIR, Form.WINGED_DOUBLE, Form.SERPENT] else 21.0
	if form == Form.FISH:
		head_x = 32.0
		head_y = 23.0
	for side in [-1, 1]:
		if int(genome.get("horns", 0)) > 0 and form not in [Form.FISH, Form.TENTACLED, Form.COLONY]:
			_line(image, head_x + side * 5, head_y - 5, head_x + side * (6 + int(genome["horns"]) * 2), head_y - 11, 2, w, h, accent)
	# Eyes: semantic attachment, preserved contrast. Fish and quadrupeds face right.
	var eyes: int = int(genome.get("eye_count", 2))
	var eye_y: float = head_y - 1
	var spacing: float = 4.0 * hs
	for eye_index in eyes:
		var ex: float = head_x + (0.0 if eyes == 1 else (-spacing if eye_index == 0 else spacing))
		if form in [Form.FISH, Form.QUADRUPED, Form.SERPENT]:
			ex = head_x + (1.0 if eyes == 1 else float(eye_index) * 3.0)
		_ellipse(image, ex, eye_y, 2.0, 2.7, eye, w, h, mask)
		_ellipse(image, ex + 0.65, eye_y + 0.5, 1.1, 1.7, iris, w, h, mask)
	# Mouth and expression; skip fish-like profiles where a muzzle would be displaced.
	if form not in [Form.FISH, Form.QUADRUPED, Form.SERPENT]:
		_line(image, head_x - 2, head_y + 6, head_x + 2, head_y + 6 + int(genome.get("mouth", 0)) - 1, 1, w, h, iris, mask)
	return {
		"genome": genome.duplicate(true), "image": image, "form": form,
		"element": element, "seed": int(genome.get("seed", 0)),
		"palette": PackedColorArray([outline, shadow, body, light, accent, eye, iris])
	}

static func _legs(image: Image, xs: Array[float], top: float, bottom: float, factor: float, w: int, h: int) -> void:
	for x in xs:
		_line(image, x, top, x + (2 if x > 24 else -2), top + (bottom - top) * factor, 4, w, h)

static func _ellipse(image: Image, cx: float, cy: float, rx: float, ry: float, color: Color, w: int, h: int, clip: Image = null) -> void:
	var sx: float = float(w) / 48.0
	var sy: float = float(h) / 48.0
	for y in range(maxi(1, floori((cy - ry) * sy) + 1), mini(h + 1, ceili((cy + ry) * sy) + 2)):
		for x in range(maxi(1, floori((cx - rx) * sx) + 1), mini(w + 1, ceili((cx + rx) * sx) + 2)):
			var dx: float = (float(x - 1) / sx - cx) / maxf(0.5, rx)
			var dy: float = (float(y - 1) / sy - cy) / maxf(0.5, ry)
			if dx * dx + dy * dy <= 1.0 and (clip == null or clip.get_pixel(x, y).a > 0.5):
				image.set_pixel(x, y, color)

static func _line(image: Image, x0: float, y0: float, x1: float, y1: float, thickness: int, w: int, h: int, color: Color = Color.WHITE, clip: Image = null) -> void:
	var steps: int = maxi(1, ceili(maxf(absf(x1 - x0), absf(y1 - y0)) * maxf(float(w), float(h)) / 48.0 * 2.0))
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		_ellipse(image, lerpf(x0, x1, t), lerpf(y0, y1, t), float(thickness) / 2.0, float(thickness) / 2.0, color, w, h, clip)

static func _mark(image: Image, mask: Image, x: int, y: int, color: Color) -> void:
	if x <= 1 or y <= 1 or x >= image.get_width() - 2 or y >= image.get_height() - 2:
		return
	for delta in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if mask.get_pixelv(Vector2i(x, y) + delta).a < 0.5:
			return
	image.set_pixel(x, y, color)
