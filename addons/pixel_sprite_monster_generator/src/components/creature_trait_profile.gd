class_name CreatureTraitProfile
extends RefCounted

## Draw a stable family-specific visual identity from a private RNG.
## No global RNG changes, and no extra calls to the generator's geometry RNG.
static func derive(archetype: int, seed_value: int, mood: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x5A71D3
	var mood_bias: int = 0
	if mood == CreatureMood.Mood.COZY:
		mood_bias = -1
	elif mood == CreatureMood.Mood.HORROR or mood == CreatureMood.Mood.EPIC:
		mood_bias = 1
	return {
		"family": archetype,
		"pattern": rng.randi_range(0, 3),
		"eye_layout": rng.randi_range(0, 2),
		"ornament": rng.randi_range(0, 2),
		"accent": rng.randi_range(0, 3),
		"mark_count": clampi(rng.randi_range(2, 5) + mood_bias, 1, 7),
		"offset": rng.randi_range(-4, 4),
		"phase": rng.randi_range(0, 1023)
	}
