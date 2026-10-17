class_name CreaturePreviewComposer
extends RefCounted

## Pure finishing stage for a cached unstyled pixel image.
## Does not regenerate geometry, consume any RNG, or modify the source.
static func compose(source: Image, archetype: int, traits: Dictionary, detail_enabled: bool, detail_strength: float, style: CreaturePixelEffects.Style, view: CreaturePixelEffects.View, shade: float, dither: float, glitch: float, seed_value: int) -> Image:
	if source == null:
		return null
	var finished: Image = source
	if detail_enabled and detail_strength > 0.0 and not traits.is_empty():
		finished = CreatureInternalDetails.render(finished, archetype, traits, detail_strength)
	if style != CreaturePixelEffects.Style.CLASSIC or view != CreaturePixelEffects.View.FRONT or shade > 0.0 or dither > 0.0 or glitch > 0.0:
		finished = CreaturePixelEffects.process(finished, style, view, shade, dither, glitch, seed_value)
	return finished
