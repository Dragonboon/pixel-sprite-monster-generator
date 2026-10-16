class_name CreaturePixelEffects
extends RefCounted

enum Style { CLASSIC, HANDHELD, JRPG, DUNGEON, COZY, ARCADE }
enum View { FRONT, THREE_QUARTER, THREE_QUARTER_RIGHT, PROFILE_LEFT, PROFILE_RIGHT, BACK, ISOMETRIC }

## CPU-only postprocessing; exactly one RGBA pixel per logical sprite cell.
static func process(source: Image, style: Style, view: View, shade: float, dither: float, glitch: float, seed_value: int) -> Image:
	if source == null:
		return null
	var width: int = source.get_width()
	var height: int = source.get_height()
	var shifted: Image = project(source, view)
	var result: Image = shifted.duplicate()
	var light: float = clampf(shade, 0.0, 1.0)
	var dots: float = clampf(dither, 0.0, 1.0)
	for y in height:
		for x in width:
			var color: Color = shifted.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var upper: bool = y > 0 and shifted.get_pixel(x, y - 1).a >= 0.5
			var lower: bool = y + 1 < height and shifted.get_pixel(x, y + 1).a >= 0.5
			var left: bool = x > 0 and shifted.get_pixel(x - 1, y).a >= 0.5
			var right: bool = x + 1 < width and shifted.get_pixel(x + 1, y).a >= 0.5
			var offset: float = 0.0
			if not upper or not left:
				offset += light * 0.24
			if not lower or not right:
				offset -= light * 0.25
			if dots > 0.0 and posmod(x + y, 2) == 0:
				offset -= dots * 0.12
			if offset > 0.0:
				color = color.lightened(minf(offset, 1.0))
			else:
				color = color.darkened(minf(-offset, 1.0))
			match style:
				Style.HANDHELD:
					var luma: float = (color.r * 0.25 + color.g * 0.62 + color.b * 0.13)
					var level: float = floorf(luma * 3.99) / 3.0
					color = Color(0.12 + 0.55 * level, 0.19 + 0.62 * level, 0.12 + 0.36 * level, color.a)
				Style.DUNGEON:
					# Cool near-black shadows and tightly contained highlights.
					var low: float = clampf(color.r * 0.22 + color.g * 0.62 + color.b * 0.16, 0.0, 1.0)
					var shadow: float = 0.42 if not lower or not right else 1.0
					color = Color(
						(0.035 + color.r * 0.34 + low * 0.09) * shadow,
						(0.055 + color.g * 0.26 + low * 0.08) * shadow,
						(0.095 + color.b * 0.47 + low * 0.12) * shadow,
						color.a
					)
					if not upper and upper != lower:
						color = color.lightened(0.1)
				Style.COZY:
					# Warm pastels and generous light midtones. Dark outlines soften.
					var brightness: float = color.r * 0.3 + color.g * 0.59 + color.b * 0.11
					var pastel: Color = Color(
						0.53 + color.r * 0.40,
						0.45 + color.g * 0.45,
						0.44 + color.b * 0.44,
						color.a
					)
					color = pastel.lerp(Color(1.0, 0.88, 0.74, color.a), clampf(brightness * 0.20, 0.0, 0.2))
				Style.ARCADE:
					color = Color(clampf(color.r * 1.16, 0.0, 1.0), clampf(color.g * 1.12, 0.0, 1.0), clampf(color.b * 1.18, 0.0, 1.0), color.a)
				Style.JRPG:
					color = color.darkened(0.06)
				_:
					pass
			result.set_pixel(x, y, color)
	if glitch > 0.0:
		var copy: Image = result.duplicate()
		for y in height:
			if posmod(y * 92821 + seed_value, 101) < roundi(clampf(glitch, 0.0, 1.0) * 15.0):
				var shift: int = 1 + posmod(y + seed_value, 2)
				for x in width:
					var sample: int = posmod(x + shift, width)
					if copy.get_pixel(x, y).a > 0.0:
						result.set_pixel(x, y, copy.get_pixel(sample, y))
	return result


## Pixel-snapped 2D approximations: not genuine 3D model rotation.
## Old FRONT/THREE_QUARTER enum values remain stable for saved Godot scenes.
static func project(source: Image, view: View) -> Image:
	if source == null:
		return null
	if view == View.FRONT:
		return source.duplicate()
	var width: int = source.get_width()
	var height: int = source.get_height()
	var output := Image.create(width, height, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	var cx: float = float(width - 1) * 0.5
	var cy: float = float(height - 1) * 0.5
	for y in height:
		for x in width:
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var sx: float = float(x)
			var sy: float = float(y)
			match view:
				View.THREE_QUARTER:
					sx = cx + (dx + dy * 0.12) / 0.90
				View.THREE_QUARTER_RIGHT:
					sx = cx + (dx - dy * 0.12) / 0.90
				View.PROFILE_LEFT:
					sx = cx + (dx + dy * 0.09) / 0.66
				View.PROFILE_RIGHT:
					sx = cx - (dx - dy * 0.09) / 0.66
				View.BACK:
					sx = float(width - 1 - x)
				View.ISOMETRIC:
					# Inverse of a bounded 2D shear/compression, with no resampling.
					var det: float = 0.80 * 0.77 + 0.16 * 0.13
					sx = cx + (0.77 * dx + 0.16 * dy) / det
					sy = cy + (-0.13 * dx + 0.80 * dy) / det
				_:
					pass
			var source_x: int = roundi(sx)
			var source_y: int = roundi(sy)
			if source_x < 0 or source_y < 0 or source_x >= width or source_y >= height:
				continue
			var sample: Color = source.get_pixel(source_x, source_y)
			if view == View.BACK and sample.a > 0.0:
				# Merely indicates a rear-facing lighting pass; facial geometry
				# cannot be recovered from a frontal mask.
				sample = sample.darkened(0.18)
			output.set_pixel(x, y, sample)
	return output
