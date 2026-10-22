class_name CreatureTopdownGenerator
extends RefCounted

## Eight-direction orthographic pixel creatures derived from one semantic DNA.
## Original procedural geometry only; no reference sprites or external runtime assets.
enum Direction { S, SW, W, NW, N, NE, E, SE }
enum Action { IDLE, WALK, HURT, CHARGE, SHOOT, ATTACK, FAINT, IDLE_B, WALK_B, DASH }
enum Family { REPTILE, BEAST, BEETLE, GHOST, BAT, PLANT, SHELL, SERPENT }

const DIRECTIONS := ["S", "SW", "W", "NW", "N", "NE", "E", "SE"]
const ACTIONS := ["Idle", "Walk", "Hurt", "Charge", "Shoot", "Attack", "Faint", "IdleB", "WalkB", "Dash"]
const ACTION_FILES := ["idle", "walk", "hurt", "charge", "shoot", "attack", "faint", "idle_b", "walk_b", "dash"]
const ACTION_VARIANTS := {"idle": ["Idle", "IdleB"], "walk": ["Walk", "WalkB"], "dash": ["Dash"], "faint": ["Faint"]}
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
		"body_shape": rng.randi_range(0, 5),
		"stance_style": rng.randi_range(0, 3),
		"head_position": rng.randi_range(0, 3),
		"appendage_style": rng.randi_range(0, 4),
		"plant_motif": rng.randi_range(0, 4),
		"shell_motif": rng.randi_range(0, 3),
		"motion_style": rng.randi_range(0, 5),
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
	var pose: Dictionary = CreatureTopdownMotion.sample(genome, state, tick)
	var a: float = float(dir) * PI / 4.0
	var facing := Vector2(sin(a), cos(a))
	var lateral := Vector2(facing.y, -facing.x)
	var phase: float = float(tick) * TAU / float(FRAMES)
	# Las variantes comparten anatomía, pero no el mismo ciclo de movimiento.
	var moving: bool = state in [Action.WALK, Action.WALK_B, Action.DASH]
	var walk_variant: bool = state == Action.WALK_B
	var idle_variant: bool = state == Action.IDLE_B
	var dash_progress: float = float(tick) / float(FRAMES - 1) if state == Action.DASH else 0.0
	var faint_progress: float = float(tick) / float(FRAMES - 1) if state == Action.FAINT else 0.0
	var motion_style: int = int(genome.get("motion_style", 0))
	var rhythm: float = 1.0 + float(motion_style % 3) * 0.18
	var gait_phase: float = phase + (PI * 0.5 if walk_variant else 0.0)
	var swing: float = sin(gait_phase) * (4.1 * rhythm if walk_variant else (3.2 * rhythm if moving else 0.4))
	var bob: float = (1.25 if walk_variant else (2.0 if state == Action.DASH else (1.6 if moving else 0.55))) * sin(gait_phase + PI * 0.5)
	if idle_variant:
		bob = 0.25 * sin(phase) + 1.2 * sin(phase * 0.5)
	var attack_offset: float = (2.5 if state in [Action.ATTACK, Action.SHOOT] else 0.0) * sin(phase * 0.5)
	var recoil: float = 2.0 if state == Action.HURT and tick % 2 == 1 else 0.0
	var charge: float = 1.3 if state == Action.CHARGE else 0.0
	var base: Vector2 = Vector2(32.0 + (1.0 if idle_variant else 0.0) * sin(phase), 45.0 + faint_progress * 3.0 + recoil)
	var collapse: float = 1.0 - faint_progress * 0.83
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
	var body_shape: int = int(genome.get("body_shape", 0))
	var stance_style: int = int(genome.get("stance_style", 0))
	var head_position: int = int(genome.get("head_position", 0))
	var appendage_style: int = int(genome.get("appendage_style", 0))
	var plant_motif: int = int(genome.get("plant_motif", 0))
	var shell_motif: int = int(genome.get("shell_motif", 0))
	# Projection of a small 3D-like puppet. Side, forward and height are
	# independent axes; view changes do not generate new anatomy.
	# For a south-facing creature, the head is raised and slightly forward.
	var origin := func(side: float, forward: float, height: float) -> Vector2:
		return (base + lateral * side + facing * forward * (0.85 if state == Action.DASH else 0.68) + Vector2(0.0, -height * collapse - bob)) * scale

	# Estela corta, detrás del cuerpo. No introduce sprites auxiliares.
	if state == Action.DASH and tick > 0:
		var trail: Vector2 = origin.call(0.0, -12.0 - dash_progress * 5.0, 10.0)
		_stroke(image, trail, origin.call(0.0, -6.0, 11.0), (2.5 + dash_progress * 2.0) * scale, colors, 1)

	# Draw occluded structures first. Outlines are local to each volume.
	var tail_tip: Vector2 = origin.call(float(pose["tail_sway"]) * 0.65, -19.0 * tail_len, 10.0 + sin(phase) * 1.5)
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
			var wing_tip: Vector2 = origin.call(side * (19.0 + float(pose["wing_flap"])), -8.0, 21.0 + float(pose["wing_flap"]))
			_stroke(image, wing_root, wing_tip, 7.0 * scale, colors, 4)
			_oval(image, wing_tip, (6.0 if family == Family.BAT else 8.0) * scale, 4.5 * scale, colors, 4)

	var is_floating: bool = family in [Family.GHOST, Family.BAT]
	if not is_floating and family != Family.SERPENT:
		var number_of_pairs: int = 2 if family in [Family.BEAST, Family.SHELL, Family.BEETLE] else 1
		if family == Family.BEETLE:
			number_of_pairs = 3
		for pair_index in number_of_pairs:
			for side in [-1.0, 1.0]:
				var foot_pose: Dictionary = CreatureTopdownMotion.foot(pose, family, side, pair_index)
				var forward_socket: float = -4.5 + float(pair_index) * 6.0
				var foot_height: float = 2.0 + float(foot_pose["lift"])
				var leg_base: Vector2 = origin.call(side * 6.0 * bw, forward_socket, 8.0)
				var foot: Vector2 = origin.call(side * (7.5 + float(pair_index) * 1.4), forward_socket + 4.0 + float(foot_pose["forward"]), foot_height)
				_stroke(image, leg_base, foot, 4.0 * ll * scale, colors, 1)
				_oval(image, foot, 4.5 * scale, (3.2 if bool(foot_pose["contact"]) else 2.5) * scale, colors, 2)

	var torso: Vector2 = origin.call(0.0, -1.0 + attack_offset, 15.0 + charge + float(pose["body_bob"]) * 0.5)
	var torso_w: float = (12.0 if family != Family.SERPENT else 9.0) * bw
	torso_w *= [0.78, 1.18, 0.90, 1.05, 1.30, 0.85][body_shape]
	var torso_h: float = (10.0 if family != Family.BEETLE else 13.0) * bh
	torso_h *= [1.23, 0.82, 1.25, 0.87, 1.08, 1.08][body_shape]
	if family == Family.GHOST:
		torso_h *= 1.28
	if family == Family.SHELL:
		torso_w *= 1.30
		torso_h *= 1.20
	if state == Action.DASH:
		torso_h *= 1.0 + 0.16 * sin(PI * dash_progress)
		torso_w *= 1.0 - 0.14 * sin(PI * dash_progress)
	if state == Action.FAINT:
		torso_h *= 1.0 - 0.62 * faint_progress
	_oval(image, torso, torso_w * scale, torso_h * scale, colors, 2)
	if family == Family.SHELL or family == Family.BEETLE:
		# Caparazón elevado: volumen dorsal, reborde lateral y placas que lo
		# conectan visualmente con el torso. No es una lámina plana transversal.
		var shell: Vector2 = origin.call(0.0, -5.0, 19.0 + charge)
		var shell_width: float = torso_w * (0.86 + float(shell_motif % 3) * 0.08)
		_oval(image, shell + Vector2(0.0, 2.8 * scale), shell_width * scale,
			(torso_h * 0.86) * scale, colors, 1)
		_oval(image, shell + Vector2(0.0, -2.0 * scale),
			(shell_width - 0.8) * scale, (torso_h * 0.75) * scale, colors, 4)
		_stroke(image, origin.call(-shell_width * 0.6, -5.0, 16.5),
			origin.call(shell_width * 0.6, -5.0, 16.5), 2.8 * scale, colors, 1)
		for side in [-1.0, 1.0]:
			_stroke(image, origin.call(side * shell_width * 0.45, -5.0, 19.0),
				origin.call(side * shell_width * 0.22, -5.0, 25.0), 1.2 * scale, colors, 1)
		if shell_motif == 2:
			_stroke(image, shell, origin.call(0.0, -10.0, 23.0), 1.4 * scale, colors, 1)
	elif family == Family.PLANT:
		# Tallos y hojas alargadas con nervio central: las estructuras vegetales
		# necesitan silueta flexible, no bloques ni facetas minerales.
		for side in [-1.0, 1.0]:
			var leaf_root: Vector2 = origin.call(side * 3.0, -4.0, 21.0)
			var leaf_tip: Vector2 = origin.call(side * (9.0 + plant_motif * 1.3),
				-9.0 + float(plant_motif % 2) * 4.0, 30.0 + float(plant_motif % 3) * 2.5)
			_stroke(image, leaf_root, leaf_tip, 2.1 * scale, colors, 1)
			_leaf(image, leaf_root, leaf_tip, (3.8 + float(plant_motif % 3)) * scale, colors)

	# Head is positioned from the same forward socket for every direction.
	var face_forward: float = 8.0 + attack_offset
	var head: Vector2 = origin.call(float(head_position - 1) * 1.4,
		face_forward + float(head_position % 3) * 2.2, 25.0 * bh + charge)
	var rx: float = (8.5 if family != Family.BEAST else 10.0) * hs
	var ry: float = (8.0 if family != Family.BEETLE else 6.2) * hs
	if family == Family.GHOST:
		rx *= 1.18
		ry *= 1.18
	if state == Action.FAINT:
		ry *= 1.0 - faint_progress * 0.62
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
		var sprout: Vector2 = origin.call(0.0, face_forward - 3.5, 32.0)
		var sprout_tip: Vector2 = origin.call(float(plant_motif % 3 - 1) * 4.0,
			face_forward - 7.5, 38.0 + float(plant_motif % 2) * 3.0)
		_leaf(image, sprout, sprout_tip, 3.8 * scale, colors)
	var horns: int = int(genome.get("horns", 0))
	if horns > 0 and family not in [Family.GHOST, Family.PLANT]:
		for side in [-1.0, 1.0]:
			_stroke(image, origin.call(side * 5.5, face_forward - 2.5, 31.0),
				origin.call(side * (7.0 + horns * 1.5), face_forward - 3.0, 35.0 + horns * 2.0),
				(1.5 + horns * 0.5) * scale, colors, 4)

	# Semantic visibility: front face on S/SE/SW, a single eye on E/W,
	# and no front facial symbols on N/NW/NE.
	var frontness: float = facing.y
	if frontness > -0.16 and (state != Action.FAINT or faint_progress < 0.8):
		var blinking: bool = state == Action.IDLE_B and tick == 2
		var eye_size: float = (2.4 if int(genome.get("eye_type", 0)) == 0 else 1.6) * scale
		if blinking:
			eye_size = 1.0 * scale
		var eye_spacing: float = 3.5 * hs
		for side in [-1.0, 1.0]:
			if absf(facing.x) > 0.7 and side * facing.x < 0.0:
				continue
			var eye_pos: Vector2 = origin.call(float(head_position - 1) * 1.4 + side * eye_spacing,
			face_forward + float(head_position % 3) * 2.2 + 7.8, 28.0 * bh)
			_oval(image, eye_pos, eye_size, eye_size, [colors[0], colors[0], colors[5], colors[5], colors[5], colors[5], colors[6]], 2)
			_oval(image, eye_pos + facing * scale, 0.9 * scale, 1.5 * scale, [colors[0], colors[0], colors[6], colors[6], colors[6], colors[6], colors[6]], 2)
		if int(genome.get("mouth", 0)) != 0 and family != Family.BEETLE:
			_stroke(image, origin.call(-2.0, face_forward + 9.5, 22.8), origin.call(2.0, face_forward + 9.5, 22.8), 1.0 * scale, colors, 0)

	# Directional depth: forward arms are drawn over the torso; rear-facing
	# arms remain tucked behind the head and chest.
	var draw_near_arms: bool = facing.y > -0.4
	# Near appendages are deliberately rendered last to overlap the torso.
	if draw_near_arms and family not in [Family.SERPENT, Family.GHOST]:
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
	# La última fase de debilitamiento pierde presencia después de desplomarse.
	if state == Action.FAINT and tick == FRAMES - 1:
		for py in dimension:
			for px in dimension:
				var pixel: Color = image.get_pixel(px, py)
				if pixel.a > 0.0:
					pixel.a *= 0.42
					image.set_pixel(px, py, pixel)
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


# Hoja fusiforme entre dos anclajes, con nervadura y punta reconocibles.
static func _leaf(image: Image, root: Vector2, tip: Vector2, width: float, palette: Array[Color]) -> void:
	var axis: Vector2 = (tip - root).normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	for step in 9:
		var t: float = float(step) / 8.0
		var tip_scale: float = 1.0 - absf(t * 2.0 - 1.0)
		var point: Vector2 = root.lerp(tip, t)
		_stroke(image, point - normal * width * tip_scale,
			point + normal * width * tip_scale, 1.8, palette, 4)
	_stroke(image, root, tip, 1.1, palette, 1)


static func _stroke(image: Image, start: Vector2, end: Vector2, thickness: float, palette: Array[Color], role: int) -> void:
	var count: int = maxi(1, ceili(start.distance_to(end) * 1.8))
	for i in range(count + 1):
		var at: Vector2 = start.lerp(end, float(i) / float(count))
		_oval(image, at, maxf(1.0, thickness * 0.5), maxf(1.0, thickness * 0.5), palette, role)
