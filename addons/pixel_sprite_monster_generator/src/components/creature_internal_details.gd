class_name CreatureInternalDetails
extends RefCounted

## Native-grid detail paint on already-colored RGBA pixels.
## All marks are clipped to opaque, enclosed interior cells. No new alpha.
static func render(source: Image, archetype: int, traits: Dictionary, strength: float) -> Image:
	if source == null:
		return null
	var output: Image = source.duplicate()
	if traits.is_empty() or strength <= 0.0 or not CreatureAnatomyRefiner.supports(archetype):
		return output
	var width: int = source.get_width()
	var height: int = source.get_height()
	var left: int = width
	var right: int = -1
	var top: int = height
	var bottom: int = -1
	for y in height:
		for x in width:
			if source.get_pixel(x, y).a >= 0.5:
				left = mini(left, x)
				right = maxi(right, x)
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if right <= left + 7 or bottom <= top + 9:
		return output
	var w: int = right - left + 1
	var h: int = bottom - top + 1
	var cx: int = (left + right) / 2
	var cy: int = (top + bottom) / 2
	var pattern: int = int(traits.get("pattern", 0))
	var ornament: int = int(traits.get("ornament", 0))
	var phase: int = int(traits.get("phase", 0))
	var offset: int = int(traits.get("offset", 0))
	var marks: int = int(traits.get("mark_count", 3))
	var accent: Color = _accent(archetype, int(traits.get("accent", 0)))
	var power: float = clampf(strength, 0.0, 1.0)
	match archetype:
		CreatureMorphology.Archetype.INSECTOID:
			# Carapace plates, contrasting abdomen segments and paired eyes.
			var segment_top: int = top + roundi(float(h) * 0.47)
			for i in range(marks):
				var y: int = segment_top + i * maxi(2, (bottom - segment_top) / maxi(1, marks))
				var span: int = maxi(3, roundi(float(w) * (0.20 + float(posmod(phase + i, 4)) * 0.035)))
				if pattern == 0 or pattern == 3:
					_stroke(output, source, cx - span, y, cx + span, y + (i % 2), 0, power, accent)
				elif pattern == 1:
					_stroke(output, source, cx - span, y - 1, cx, y + 2, 0, power, accent)
					_stroke(output, source, cx, y + 2, cx + span, y - 1, 0, power, accent)
				else:
					_spot(output, source, cx - span / 2, y, 1, 2, power, accent)
					_spot(output, source, cx + span / 2, y, 1, 2, power, accent)
			for side in [-1, 1]:
				_stroke(output, source, cx + side * maxi(2, w / 7), top + h / 3, cx + side * maxi(2, w / 5), cy, 1, power, accent)
		CreatureMorphology.Archetype.QUADRUPED:
			# Visible flank clusters and a differentiated back ridge.
			for i in range(marks + 1):
				var x: int = left + roundi(float(w) * (0.19 + 0.46 * float(i + 1) / float(marks + 2)))
				var y: int = top + roundi(float(h) * 0.49) + posmod(phase + i * 3, 7) - 3
				if pattern == 0:
					_spot(output, source, x, y, 1 + i % 2, 0, power, accent)
				elif pattern == 1:
					_stroke(output, source, x, y - 2, x + 2, y + 2, 0, power, accent)
				elif pattern == 2:
					_stroke(output, source, x - 1, y, x + 1, y, 2, power, accent)
				else:
					_spot(output, source, x, y, 1, 2, power, accent)
			for i in range(3 + ornament):
				var ridge_x: int = left + w / 4 + i * maxi(2, w / 10)
				_spot(output, source, ridge_x, top + h / 3 + (i % 2), 0, 1, power, accent)
		CreatureMorphology.Archetype.GOLEM:
			# Chunky plate seams, deterministic cracks, and a rune/core.
			var upper: int = top + roundi(float(h) * 0.38)
			for side in [-1, 1]:
				var seam_x: int = cx + side * maxi(3, w / 5)
				_stroke(output, source, seam_x, upper, seam_x + side * 2, cy + h / 7, 0, power, accent)
				if pattern == 0 or pattern == 2:
					_stroke(output, source, seam_x + side, cy + h / 7, seam_x - side * 2, cy + h / 4, 0, power, accent)
			for i in range(marks):
				var x: int = cx + (posmod(phase + i * 11, maxi(5, w / 2)) - maxi(2, w / 4))
				var y: int = cy + (i % 3) * 2 - 2
				_stroke(output, source, x, y, x + offset / 2, y + 3, 0, power, accent)
		CreatureMorphology.Archetype.SPIRIT:
			# A mask/core, streaks of light and offset spectral markings.
			for i in range(marks + 2):
				var x: int = cx + posmod(phase + i * 7, maxi(5, w / 2)) - maxi(2, w / 4)
				var y: int = cy + h / 9 + i * maxi(2, h / 16)
				_stroke(output, source, x, y, x + posmod(offset + i, 4) - 2, y + 2 + i % 2, 1, power, accent)
			if ornament == 2:
				_stroke(output, source, cx - 4, cy, cx + 4, cy, 2, power, accent)
		_:
			return output
	# Shared facial/identity anchor. Faces are clipped to genuine solid pixels.
	var eye_y: int = top + roundi(float(h) * (0.26 if archetype != CreatureMorphology.Archetype.QUADRUPED else 0.31))
	var eye_cx: int = cx + (w / 4 if archetype == CreatureMorphology.Archetype.QUADRUPED else 0)
	var eye_count: int = int(traits.get("eye_layout", 0))
	if archetype != CreatureMorphology.Archetype.QUADRUPED:
		for side in [-1, 1]:
			_spot(output, source, eye_cx + side * maxi(2, w / (7 if eye_count == 0 else 9)), eye_y, 0 if eye_count == 2 else 1, 3, power, accent)
	else:
		_spot(output, source, eye_cx, eye_y, 0 if eye_count == 2 else 1, 3, power, accent)
	# The core/rune always differs meaningfully by seed for golems and spirits.
	if archetype == CreatureMorphology.Archetype.GOLEM or archetype == CreatureMorphology.Archetype.SPIRIT:
		var radius: int = 2 + ornament
		if pattern == 0:
			_stroke(output, source, cx - radius, cy - 1, cx + radius, cy - 1, 2, power, accent)
			_stroke(output, source, cx, cy - radius, cx, cy + radius, 2, power, accent)
		elif pattern == 1:
			_stroke(output, source, cx - radius, cy, cx, cy - radius, 2, power, accent)
			_stroke(output, source, cx, cy - radius, cx + radius, cy, 2, power, accent)
			_stroke(output, source, cx + radius, cy, cx, cy + radius, 2, power, accent)
			_stroke(output, source, cx, cy + radius, cx - radius, cy, 2, power, accent)
		elif pattern == 2:
			_spot(output, source, cx, cy, radius, 2, power, accent)
		else:
			_stroke(output, source, cx - radius, cy - radius, cx + radius, cy + radius, 2, power, accent)
			_stroke(output, source, cx + radius, cy - radius, cx - radius, cy + radius, 2, power, accent)
	return output


static func _accent(archetype: int, variant: int) -> Color:
	var palette: Array[Color]
	match archetype:
		CreatureMorphology.Archetype.INSECTOID:
			palette = [Color(0.95, 0.76, 0.38), Color(0.43, 0.91, 0.51), Color(0.85, 0.42, 0.56), Color(0.65, 0.81, 0.95)]
		CreatureMorphology.Archetype.GOLEM:
			palette = [Color(0.36, 0.95, 0.90), Color(0.99, 0.70, 0.28), Color(0.75, 0.52, 0.95), Color(0.60, 0.96, 0.49)]
		CreatureMorphology.Archetype.SPIRIT:
			palette = [Color(0.50, 0.88, 1.00), Color(0.91, 0.64, 0.99), Color(0.78, 1.00, 0.67), Color(1.00, 0.83, 0.55)]
		_:
			palette = [Color(0.95, 0.77, 0.48), Color(0.81, 0.62, 0.38), Color(0.91, 0.51, 0.46), Color(0.60, 0.89, 0.55)]
	return palette[posmod(variant, palette.size())]


static func _spot(dst: Image, src: Image, cx: int, cy: int, radius: int, role: int, strength: float, tint: Color) -> void:
	for x in range(cx - radius, cx + radius + 1):
		for y in range(cy - radius, cy + radius + 1):
			if absi(x - cx) + absi(y - cy) <= maxi(1, radius):
				_mark(dst, src, x, y, role, strength, tint)


static func _stroke(dst: Image, src: Image, x0: int, y0: int, x1: int, y1: int, role: int, strength: float, tint: Color) -> void:
	var steps: int = maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		_mark(dst, src, roundi(lerpf(float(x0), float(x1), t)), roundi(lerpf(float(y0), float(y1), t)), role, strength, tint)


static func _mark(dst: Image, src: Image, x: int, y: int, role: int, strength: float, tint: Color) -> void:
	if x < 1 or y < 1 or x >= src.get_width() - 1 or y >= src.get_height() - 1:
		return
	if src.get_pixel(x, y).a < 0.99:
		return
	# Protect outlines, one-pixel appendages and transparent negative space.
	for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if src.get_pixel(x + delta.x, y + delta.y).a < 0.99:
			return
	var original: Color = dst.get_pixel(x, y)
	var changed: Color = original
	match role:
		0: changed = original.darkened(0.58 * strength)
		1: changed = original.lightened(0.42 * strength)
		2: changed = original.lerp(tint, 0.82 * strength)
		_: changed = original.darkened(0.79 * strength)
	changed.a = original.a
	dst.set_pixel(x, y, changed)
