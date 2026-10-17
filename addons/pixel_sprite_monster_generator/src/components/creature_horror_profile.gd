class_name CreatureHorrorProfile
extends RefCounted

## Quiet, nearly-human silhouettes for mystery / psychological-horror games.
## Deliberately opt-in; standard HORROR remains exactly as before.
enum Profile { CLASSIC, UNCANNY }

const PHI: float = 1.618033988749895
const NAMES: Array[String] = [
	"Mask", "Puppet", "Hollow", "Watcher", "Lurker", "Broken Saint"
]


static func supports(archetype: int) -> bool:
	return archetype in [
		CreatureMorphology.Archetype.BIPED,
		CreatureMorphology.Archetype.SPIRIT,
		CreatureMorphology.Archetype.GOLEM
	]


static func sample(seed_value: int, strength: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x1A721CD
	var variant: int = posmod(seed_value, NAMES.size())
	var power: float = clampf(strength, 0.0, 1.0)
	# PHI controls head-to-torso and torso-to-limb relations, with small
	# seeded deviations that are unsettling but not purely random.
	return {
		"subtype": variant,
		"name": NAMES[variant],
		"strength": power,
		"head_ratio": (1.0 / PHI) * lerpf(1.0, rng.randf_range(0.82, 1.22), power),
		"limb_ratio": PHI * lerpf(1.0, rng.randf_range(0.88, 1.13), power),
		"neck_ratio": (1.0 / PHI) * lerpf(1.0, rng.randf_range(0.78, 1.25), power),
		"offset": roundi(rng.randf_range(-3.0, 3.0) * power),
		"eye_offset": rng.randi_range(-1, 1),
		"palette_variant": posmod(seed_value / 6, 4)
	}


## Always returns an x-major boolean map. Core, head and every limb share
## joined anchor points; eyes are enclosed holes, not detached islands.
static func apply(source: Array[Variant], archetype: int, traits: Dictionary) -> Array[Variant]:
	if traits.is_empty() or not supports(archetype) or source.is_empty() or source[0].is_empty():
		return source.duplicate(true)
	var w: int = source.size()
	var h: int = source[0].size()
	if w < 24 or h < 24:
		return source.duplicate(true)
	var result: Array[Variant] = []
	for x in w:
		var column: Array[bool] = []
		column.resize(h)
		column.fill(false)
		result.append(column)

	var subtype: int = int(traits["subtype"])
	var power: float = float(traits["strength"])
	var cx: int = w / 2
	var shift: int = int(traits["offset"])
	var head_y: int = roundi(float(h) * 0.27)
	var shoulder_y: int = roundi(float(h) * 0.46)
	var hip_y: int = roundi(float(h) * 0.68)
	var foot_y: int = mini(h - 3, roundi(float(h) * 0.92))
	var torso_span: int = maxi(5, hip_y - shoulder_y)
	var head_rx: int = maxi(3, roundi(float(w) * 0.13 * float(traits["head_ratio"]) * PHI))
	var head_ry: int = maxi(4, roundi(float(h) * 0.12 * float(traits["neck_ratio"]) * PHI))
	var shoulder_rx: int = maxi(4, roundi(float(head_rx) * PHI * 0.85))
	var arm_length: int = maxi(5, roundi(float(torso_span) * float(traits["limb_ratio"]) * 0.92))
	var narrow: int = maxi(2, shoulder_rx / 2)
	var neck_start: int = head_y + head_ry - 2
	var face_x: int = cx + shift

	match subtype:
		0: # Mask: face slightly too wide, straight doll-like posture.
			head_rx += maxi(2, roundi(float(head_rx) * 0.25 * power))
			shoulder_rx = maxi(3, shoulder_rx - 2)
		1: # Puppet: reduced head, long elbowed arms and angular knees.
			head_rx = maxi(3, head_rx - 2)
			arm_length += maxi(2, roundi(float(arm_length) / PHI * power))
		2: # Hollow: tall empty-looking skull and narrow shoulders.
			head_ry += maxi(2, roundi(float(head_ry) * 0.35 * power))
			shoulder_rx = maxi(4, shoulder_rx - 2)
		3: # Watcher: improbably long face, very vertical extremities.
			head_ry += maxi(3, roundi(float(head_ry) * 0.45 * power))
			head_rx = maxi(3, head_rx - 1)
		4: # Lurker: a slightly displaced head over hunched shoulders.
			face_x += maxi(1, roundi(2.0 * power))
			shoulder_rx += 2
			arm_length += 2
		5: # Broken Saint: ceremonial mantle and raised crown fragments.
			head_ry += 1
			shoulder_rx += 3

	# Head-to-neck joins before the body. No intentionally disconnected halo.
	_oval(result, face_x, head_y, head_rx, head_ry)
	_line(result, face_x, neck_start, cx, shoulder_y + 2, maxi(2, w / 22))
	_oval(result, cx, shoulder_y + 3, maxi(3, shoulder_rx - 1), maxi(4, torso_span / 2))
	_line(result, cx, shoulder_y, cx, hip_y, maxi(3, shoulder_rx * 2 - 1))
	_oval(result, cx, hip_y, maxi(3, shoulder_rx - 2), maxi(2, torso_span / 4))

	# Side-to-side deviations are small: near symmetry is what makes it eerie.
	for side in [-1, 1]:
		var base_x: int = cx + side * maxi(2, shoulder_rx - 2)
		var hand_x: int = cx + side * (shoulder_rx + narrow)
		var hand_y: int = mini(h - 4, shoulder_y + arm_length)
		if subtype == 1: # Marionette: dislocated-looking but connected elbows.
			var elbow_x: int = cx + side * (shoulder_rx + 4)
			var elbow_y: int = shoulder_y + maxi(3, torso_span / 3)
			_line(result, base_x, shoulder_y, elbow_x, elbow_y, 2)
			_line(result, elbow_x, elbow_y, hand_x + side * 2, hand_y, 2)
		elif subtype == 4: # Lurker: arms reach forward and asymmetrically.
			_line(result, base_x, shoulder_y, hand_x + side * 4, hand_y - side * 2, 2)
		elif subtype == 3: # Watcher: both arms fall unusually straight.
			_line(result, base_x, shoulder_y, base_x + side, hand_y, 2)
		else:
			_line(result, base_x, shoulder_y, hand_x, hand_y, 2)
		# Two planted legs with subtly wrong stride length.
		var leg_x: int = cx + side * narrow
		var leg_end_x: int = leg_x + side * (2 if subtype == 1 else 0)
		var leg_end_y: int = foot_y - (1 if side == 1 and subtype in [2, 4] else 0)
		_line(result, leg_x, hip_y - 1, leg_end_x, leg_end_y, maxi(2, w / 22))
		_line(result, leg_end_x, leg_end_y, leg_end_x + side * 2, leg_end_y, 2)

	if subtype == 5:
		for side in [-1, 1]:
			_line(result, face_x + side * maxi(2, head_rx / 2), head_y - head_ry + 2,
				face_x + side * maxi(3, head_rx), head_y - head_ry - maxi(3, head_ry / 2), 2)
			_line(result, cx + side * (shoulder_rx - 1), shoulder_y,
				cx + side * (shoulder_rx + 4), hip_y - 2, 3)
	elif subtype == 2:
		# A small negative space in the chest, entirely surrounded by a torso.
		for dy in range(-1, 2):
			_set(result, cx, shoulder_y + 5 + dy, false)

	# Low-resolution facial emptiness: enclosed holes stay distinct from
	# external transparency, without random scatter or photorealism.
	var eye_y: int = head_y - 1
	var eye_sep: int = maxi(2, head_rx / 2)
	for side in [-1, 1]:
		var ex: int = face_x + side * eye_sep
		var ey: int = eye_y + (int(traits["eye_offset"]) if side == 1 else 0)
		if ex > 1 and ex < w - 2 and ey > 1 and ey < h - 2:
			if result[ex - 1][ey] and result[ex + 1][ey] and result[ex][ey - 1] and result[ex][ey + 1]:
				result[ex][ey] = false
	return result


## Cold, muted color ramps with a restrained unnatural accent. Used only
## when the selected harmony is AUTO; manually chosen harmony still wins.
static func palette(seed_value: int, requested: int) -> Dictionary:
	var n: int = clampi(requested, 1, CreatureColorTheory.MAX_COLORS)
	var kind: int = posmod(seed_value / 6, 4)
	var base_hue: float = [0.31, 0.57, 0.71, 0.105][kind]
	var accent_hue: float = [0.49, 0.01, 0.37, 0.98][kind]
	var colors := PackedColorArray()
	for i in n:
		var t: float = float(i) / float(maxi(1, n - 1))
		var brightness: float = lerpf(0.11, 0.82, t)
		var chroma: float = lerpf(0.12, 0.31, t)
		var hue: float = fposmod(base_hue + (t - 0.5) * 0.035, 1.0)
		if i == n - 2 and n >= 4:
			hue = accent_hue
			chroma = 0.51
			brightness = 0.68
		elif i == n - 1 and n >= 3:
			chroma = 0.085
			brightness = 0.90
		if n == 1:
			brightness = 0.52
		colors.append(Color.from_hsv(hue, chroma, brightness))
	return {
		"colors": colors,
		"harmony": CreatureColorTheory.Harmony.NEUTRAL_ACCENT,
		"roles": {
			"outline": 0,
			"shadow": mini(1, n - 1),
			"body": n / 2,
			"secondary": maxi(0, n - 3),
			"accent": maxi(0, n - 2),
			"highlight": n - 1
		}
	}


static func _set(map: Array[Variant], x: int, y: int, value: bool) -> void:
	if x >= 0 and x < map.size() and y >= 0 and y < map[0].size():
		map[x][y] = value


static func _oval(map: Array[Variant], cx: int, cy: int, rx: int, ry: int) -> void:
	for x in range(maxi(0, cx - rx), mini(map.size(), cx + rx + 1)):
		for y in range(maxi(0, cy - ry), mini(map[0].size(), cy + ry + 1)):
			var dx: float = float(x - cx) / float(maxi(1, rx))
			var dy: float = float(y - cy) / float(maxi(1, ry))
			if dx * dx + dy * dy <= 1.0:
				map[x][y] = true


static func _line(map: Array[Variant], x0: int, y0: int, x1: int, y1: int, thickness: int) -> void:
	var steps: int = maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	var radius: int = maxi(0, thickness / 2)
	for step in range(steps + 1):
		var fraction: float = float(step) / float(steps)
		var x: int = roundi(lerpf(float(x0), float(x1), fraction))
		var y: int = roundi(lerpf(float(y0), float(y1), fraction))
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				_set(map, x + dx, y + dy, true)
