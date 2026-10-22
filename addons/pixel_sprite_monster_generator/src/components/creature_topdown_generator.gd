class_name CreatureTopdownGenerator
extends RefCounted

## Eight-direction orthographic pixel creatures derived from one semantic DNA.
## Original procedural geometry only; no reference sprites or external runtime assets.
enum Direction { S, SW, W, NW, N, NE, E, SE }
enum Action { IDLE, WALK, HURT, CHARGE, SHOOT, ATTACK, FAINT }
enum Family { REPTILE, BEAST, BEETLE, GHOST, BAT, PLANT, SHELL, SERPENT }

const DIRECTIONS := ["S", "SW", "W", "NW", "N", "NE", "E", "SE"]
const ACTIONS := ["Idle", "Walk", "Hurt", "Charge", "Shoot", "Attack", "Faint"]
const FAMILIES := ["Reptile", "Beast", "Beetle", "Ghost", "Bat", "Plant", "Shell", "Serpent"]
const FRAMES: int = 4
const DEFAULT_SIZE: int = 64
const HUES := [0.11, 0.045, 0.55, 0.31, 0.14, 0.08, 0.53, 0.76]

static func species(seed_value: int, family: int = -1, element: int = -1) -> Dictionary:
	var dna: Dictionary = CreatureSpeciesDNA.sample(seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x5DE713
	var chosen_family: int = family if family >= 0 and family < Family.size() else rng.randi_range(0, Family.size() - 1)
	var chosen_element: int = element if element >= 0 and element < HUES.size() else rng.randi_range(0, HUES.size() - 1)
	return {
		"schema_version": 1,
		"seed": seed_value,
		"family": chosen_family,
		"element": chosen_element,
		"body_width": rng.randf_range(0.76, 1.34),
		"body_height": rng.randf_range(0.78, 1.28),
		"head_size": rng.randf_range(0.72, 1.40),
		"leg_length": rng.randf_range(0.67, 1.40),
		"tail_length": rng.randf_range(0.70, 1.42),
		"ear_size": rng.randf_range(0.8, 1.5),
		"eye_type": rng.randi_range(0, 3),
		"horns": rng.randi_range(0, 2),
		"spikes": rng.randi_range(0, 3),
		"markings": rng.randi_range(0, 3),
		"mouth": rng.randi_range(0, 2),
		"wing_style": rng.randi_range(0, 2),
		"primary_hue_offset": rng.randf_range(-0.07, 0.07),
		"accent_hue_offset": rng.randf_range(0.27, 0.53),
		"genetics": dna
	}


static func render(genome: Dictionary, direction: int, action: int = Action.IDLE, frame: int = 0, size: int = DEFAULT_SIZE) -> Image:
	var dimension: int = clampi(size, 32, 128)
	var image := Image.create(dimension, dimension, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var family: int = clampi(int(genome.get("family", 0)), 0, Family.size() - 1)
	var dir: int = posmod(direction, Direction.size())
	var state: int = clampi(action, 0, Action.size() - 1)
	var tick: int = posmod(frame, FRAMES)
	var a: float = float(dir) * PI / 4.0
	var facing := Vector2(sin(a), cos(a))
	var lateral := Vector2(facing.y, -facing.x)
	var phase: float = float(tick) * TAU / float(FRAMES)
	var moving: bool = state == Action.WALK
	var swing: float = sin(phase) * (3.2 if moving else 0.4)
	var bob: float = (1.6 if moving else 0.55) * sin(phase + PI * 0.5)
	var attack_offset: float = (2.5 if state in [Action.ATTACK, Action.SHOOT] else 0.0) * sin(phase * 0.5)
	var faint: float = float(tick) * 2.0 if state == Action.FAINT else 0.0
	var recoil: float = 2.0 if state == Action.HURT and tick % 2 == 1 else 0.0
	var charge: float = 1.3 if state == Action.CHARGE else 0.0
	var base: Vector2 = Vector2(32.0, 45.0 + faint * 0.5 + recoil)
	var scale: float = float(dimension) / 64.0
	var hue: float = fposmod(HUES[clampi(int(genome.get("element", 0)), 0, HUES.size() - 1)] + float(genome.get("primary_hue_offset", 0.0)), 1.0)
	var accent_hue: float = fposmod(hue + float(genome.get("accent_hue_offset", 0.4)), 1.0)
	var colors: Array[Color] = [
		Color.from_hsv(hue, 0.34, 0.12),
		Color.from_hsv(hue, 0.58, 0.36),
		Color.from_hsv(hue, 0.56, 0.75),
		Color.from_hsv(hue, 0.38, 0.95),
		Color.from_hsv(accent_hue, 0.64, 0.79),
		Color(0.95, 0.96, 0.90),
		Color(0.06, 0.08, 0.12)
	]
	var bw: float = float(genome.get("body_width", 1.0))
	var bh: float = float(genome.get("body_height", 1.0))
	var hs: float = float(genome.get("head_size", 1.0))
	var ll: float = float(genome.get("leg_length", 1.0))
	var tail_len: float = float(genome.get("tail_length", 1.0))
	# Projection of a small 3D-like puppet. Side, forward and height are
	# independent axes; view changes do not generate new anatomy.
	# For a south-facing creature, the head is raised and slightly forward.
	var origin := func(side: float, forward: float, height: float) -> Vector2:
		return (base + lateral * side + facing * forward * 0.68 + Vector2(0.0, -height - bob)) * scale

	# Draw occluded structures first. Outlines are local to each volume.
	var tail_tip: Vector2 = origin.call(0.0, -19.0 * tail_len, 10.0 + sin(phase) * 1.5)
	var tail_root: Vector2 = origin.call(0.0, -5.0, 10.0)
	if family in [Family.REPTILE, Family.BEAST, Family.SHELL, Family.SERPENT, Family.PLANT]:
		_stroke(image, tail_root, tail_tip, (4.5 if family != Family.SERPENT else 8.0) * scale, colors, 4)
		if family == Family.PLANT:
			_oval(image, tail_tip, 5.0 * scale, 3.0 * scale, colors, 4)
		if family == Family.SERPENT:
			_oval(image, origin.call(0.0, -12.0, 7.0), 9.0 * scale, 5.0 * scale, colors, 2)
	if family == Family.BAT or family == Family.BEETLE:
		for side in [-1.0, 1.0]:
			var wing_root: Vector2 = origin.call(side * 5.0, -2.0, 17.0)
			var wing_tip: Vector2 = origin.call(side * (19.0 + sin(phase) * 2.0), -8.0, 21.0 + sin(phase) * 2.0)
			_stroke(image, wing_root, wing_tip, 7.0 * scale, colors, 4)
			_oval(image, wing_tip, (6.0 if family == Family.BAT else 8.0) * scale, 4.5 * scale, colors, 4)

	var is_floating: bool = family in [Family.GHOST, Family.BAT]
	if not is_floating and family != Family.SERPENT:
		for side in [-1.0, 1.0]:
			var leg_base: Vector2 = origin.call(side * 6.0 * bw, -1.0, 8.0)
			var foot: Vector2 = origin.call(side * (7.5 + swing * 0.12), 3.0 + swing * side, 2.0)
			_stroke(image, leg_base, foot, 4.0 * ll * scale, colors, 1)
			_oval(image, foot, 4.5 * scale, 3.2 * scale, colors, 2)

	var torso: Vector2 = origin.call(0.0, -1.0 + attack_offset, 15.0 + charge)
	var torso_w: float = (12.0 if family != Family.SERPENT else 9.0) * bw
	var torso_h: float = (10.0 if family != Family.BEETLE else 13.0) * bh
	if family == Family.GHOST:
		torso_h *= 1.28
	if family == Family.SHELL:
		torso_w *= 1.30
		torso_h *= 1.20
	_oval(image, torso, torso_w * scale, torso_h * scale, colors, 2)
	if family == Family.SHELL or family == Family.BEETLE:
		var shell: Vector2 = origin.call(0.0, -4.0, 18.0 + charge)
		_oval(image, shell, (torso_w + 1.0) * scale, (torso_h - 0.5) * scale, colors, 4)
		_stroke(image, origin.call(-5.0, -4.0, 22.0), origin.call(5.0, -4.0, 22.0), 1.4 * scale, colors, 1)
	elif family == Family.PLANT:
		_oval(image, origin.call(-5.0, -4.0, 22.0), 5.0 * scale, 8.0 * scale, colors, 4)
		_oval(image, origin.call(5.0, -4.0, 22.0), 5.0 * scale, 8.0 * scale, colors, 4)

	# Head is positioned from the same forward socket for every direction.
	var face_forward: float = 8.0 + attack_offset
	var head: Vector2 = origin.call(0.0, face_forward, 25.0 * bh + charge)
	var rx: float = (8.5 if family != Family.BEAST else 10.0) * hs
	var ry: float = (8.0 if family != Family.BEETLE else 6.2) * hs
	if family == Family.GHOST:
		rx *= 1.18
		ry *= 1.18
	_oval(image, head, rx * scale, ry * scale, colors, 2)
	if family == Family.REPTILE or family == Family.SERPENT:
		_oval(image, origin.call(0.0, face_forward + 6.5, 21.5 * bh), 6.0 * scale, 3.6 * scale, colors, 3)
	elif family == Family.BEAST:
		for side in [-1.0, 1.0]:
			_oval(image, origin.call(side * 8.0, face_forward - 1.0, 30.5), 3.7 * scale, 6.0 * scale, colors, 4)
	elif family == Family.BEETLE:
		for side in [-1.0, 1.0]:
			_stroke(image, origin.call(side * 4.0, face_forward + 3.0, 30.0),
				origin.call(side * 7.0, face_forward + 8.0, 38.0), 1.8 * scale, colors, 4)
	elif family == Family.PLANT:
		_oval(image, origin.call(0.0, face_forward - 4.0, 34.0), 5.0 * scale, 8.0 * scale, colors, 4)
	var horns: int = int(genome.get("horns", 0))
	if horns > 0 and family not in [Family.GHOST, Family.PLANT]:
		for side in [-1.0, 1.0]:
			_stroke(image, origin.call(side * 5.5, face_forward - 2.5, 31.0),
				origin.call(side * (7.0 + horns * 1.5), face_forward - 3.0, 35.0 + horns * 2.0),
				(1.5 + horns * 0.5) * scale, colors, 4)

	# Semantic visibility: front face on S/SE/SW, a single eye on E/W,
	# and no front facial symbols on N/NW/NE.
	var frontness: float = facing.y
	if frontness > -0.16 and state != Action.FAINT:
		var eye_size: float = (2.4 if int(genome.get("eye_type", 0)) == 0 else 1.6) * scale
		var eye_spacing: float = 3.5 * hs
		for side in [-1.0, 1.0]:
			if absf(facing.x) > 0.7 and side * facing.x < 0.0:
				continue
			var eye_pos: Vector2 = origin.call(side * eye_spacing, face_forward + 7.8, 28.0 * bh)
			_oval(image, eye_pos, eye_size, eye_size, [colors[0], colors[0], colors[5], colors[5], colors[5], colors[5], colors[6]], 2)
			_oval(image, eye_pos + facing * scale, 0.9 * scale, 1.5 * scale, [colors[0], colors[0], colors[6], colors[6], colors[6], colors[6], colors[6]], 2)
		if int(genome.get("mouth", 0)) != 0 and family != Family.BEETLE:
			_stroke(image, origin.call(-2.0, face_forward + 9.5, 22.8), origin.call(2.0, face_forward + 9.5, 22.8), 1.0 * scale, colors, 0)

	# Near appendages are deliberately rendered last to overlap the torso.
	if family not in [Family.SERPENT, Family.GHOST]:
		for side in [-1.0, 1.0]:
			var arm: Vector2 = origin.call(side * (10.0 * bw), 5.0 + swing * side, 14.0)
			_stroke(image, origin.call(side * (8.5 * bw), 4.0, 20.0), arm, 3.8 * scale, colors, 2)
			if family == Family.REPTILE or family == Family.BEAST:
				_stroke(image, arm, arm + facing * 2.5 * scale, 1.6 * scale, colors, 4)

	# Markings are attached in local anatomical coordinates, never screen Y.
	if int(genome.get("markings", 0)) > 0 and family not in [Family.GHOST, Family.SHELL]:
		for i in range(3 + int(genome.get("markings", 0))):
			var part: Vector2 = origin.call(float(i % 3 - 1) * 3.6, float(i / 3) * -3.5, 21.0)
			_oval(image, part, 1.3 * scale, 1.3 * scale, colors, 4)
	return image


## Pixel ellipse with 1 logical-pixel outline, local lighting and no band cutoff.
static func _oval(image: Image, center: Vector2, rx: float, ry: float, palette: Array[Color], role: int) -> void:
	var w: int = image.get_width()
	var h: int = image.get_height()
	var r_x: float = maxf(1.0, rx)
	var r_y: float = maxf(1.0, ry)
	for y in range(maxi(0, floori(center.y - r_y - 1)), mini(h, ceili(center.y + r_y + 2))):
		for x in range(maxi(0, floori(center.x - r_x - 1)), mini(w, ceili(center.x + r_x + 2))):
			var nx: float = (float(x) + 0.5 - center.x) / r_x
			var ny: float = (float(y) + 0.5 - center.y) / r_y
			var dist: float = nx * nx + ny * ny
			if dist > 1.0:
				continue
			var color: Color = palette[role]
			if dist > pow(1.0 - minf(0.35, 1.0 / minf(r_x, r_y)), 2.0):
				color = palette[0]
			elif role != 0 and role != 1 and role != 6:
				if nx + ny > 0.35:
					color = palette[1]
				elif nx + ny < -0.43:
					color = palette[3]
			image.set_pixel(x, y, color)


static func _stroke(image: Image, start: Vector2, end: Vector2, thickness: float, palette: Array[Color], role: int) -> void:
	var count: int = maxi(1, ceili(start.distance_to(end) * 1.8))
	for i in range(count + 1):
		var at: Vector2 = start.lerp(end, float(i) / float(count))
		_oval(image, at, maxf(1.0, thickness * 0.5), maxf(1.0, thickness * 0.5), palette, role)
