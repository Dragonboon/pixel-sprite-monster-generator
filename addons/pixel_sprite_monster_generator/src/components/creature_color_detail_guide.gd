class_name CreatureColorDetailGuide
extends RefCounted

## Image-space mask for protected eye/core/mark accents.
static func build(source: Image, archetype: int, traits: Dictionary, strength: float, view: CreaturePixelEffects.View) -> Image:
	if source == null:
		return null
	var painted: Image = CreatureInternalDetails.render(source, archetype, traits, strength)
	var guide := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	guide.fill(Color.TRANSPARENT)
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x, y).a > 0.0 and painted.get_pixel(x, y) != source.get_pixel(x, y):
				guide.set_pixel(x, y, Color.WHITE)
	return CreaturePixelEffects.project(guide, view) if view != CreaturePixelEffects.View.FRONT else guide
