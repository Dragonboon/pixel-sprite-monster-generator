class_name CreaturePixelEffects
extends RefCounted

enum Style { CLASSIC, HANDHELD, JRPG, DUNGEON, COZY, ARCADE }
enum View { FRONT, THREE_QUARTER }

## CPU-only postprocessing; exactly one RGBA pixel per logical sprite cell.
static func process(source: Image, style: Style, view: View, shade: float, dither: float, glitch: float, seed_value: int) -> Image:
	if source == null:
		return null
	var width: int = source.get_width()
	var height: int = source.get_height()
	var shifted: Image = source.duplicate()
	if view == View.THREE_QUARTER:
		shifted = Image.create(width, height, false, Image.FORMAT_RGBA8)
		shifted.fill(Color.TRANSPARENT)
		for y in height:
			var offset: int = roundi(float(height / 2 - y) * 0.12)
			for x in width:
				var target: int = x + offset
				if target >= 0 and target < width:
					shifted.set_pixel(target, y, source.get_pixel(x, y))
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
					color = Color(color.r * 0.75, color.g * 0.64, color.b * 0.78, color.a)
				Style.COZY:
					color = color.lightened(0.13)
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
