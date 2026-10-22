class_name CreatureSpeciesDNA
extends RefCounted

## Versioned, deterministic modular genome. Form is an influence, not a rigid template.
## Every random draw is isolated from the game's RNG and from legacy sprite seeds.
const HEADS := ["Round", "Reptile", "Mammal", "Avian", "Mask", "Angular"]
const LIMBS := ["Stubby", "Claws", "Hooves", "Fins", "Tentacles"]
const BACKS := ["None", "Shell", "Wings", "Spines", "Crest"]
const TAILS := ["None", "Whip", "Heavy", "Flame", "Leaf"]
const SUBTYPES := ["Compact", "Hunter", "Guardian", "Ethereal"]
const TORSOS := ["Compact", "Pear", "Barrel", "Triangle", "Slim"]
const ABDOMENS := ["Round", "Segmented", "Tucked", "Heavy"]
const STANCES := ["Standing", "Crouched", "Wide", "Leaning"]
const WING_STYLES := ["Bat", "Feather", "Insect", "Manta"]
const MOODS := ["organic", "epic", "funny", "creepy", "cute", "wild"]
const TRAITS := ["form", "element", "subtype", "head", "limbs", "back", "tail", "torso", "abdomen", "stance", "wing_style",
	"body_width", "body_height", "head_scale", "limb_length", "eye_count",
	"eye_style", "mouth", "horns", "pattern", "accent_marks", "hue_shift"]

static func sample(seed_value: int, options: Dictionary = {}) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x3CDE71
	var base: Dictionary = CreatureSpeciesGenerator.sample(seed_value)
	base["schema_version"] = 2
	base["form"] = _choice(rng, options, "form", CreatureSpeciesGenerator.Form.size())
	base["form_name"] = CreatureSpeciesGenerator.FORM_NAMES[int(base["form"])]
	base["element"] = _choice(rng, options, "element", CreatureSpeciesGenerator.Element.size())
	base["subtype"] = _choice(rng, options, "subtype", SUBTYPES.size())
	base["head"] = _choice(rng, options, "head", HEADS.size())
	base["limbs"] = _choice(rng, options, "limbs", LIMBS.size())
	base["back"] = _choice(rng, options, "back", BACKS.size())
	base["tail"] = _choice(rng, options, "tail", TAILS.size())
	base["torso"] = _choice(rng, options, "torso", TORSOS.size())
	base["abdomen"] = _choice(rng, options, "abdomen", ABDOMENS.size())
	base["stance"] = _choice(rng, options, "stance", STANCES.size())
	base["wing_style"] = _choice(rng, options, "wing_style", WING_STYLES.size())
	var mood_input: Dictionary = options.get("moods", {})
	var moods: Dictionary = {}
	for mood in MOODS:
		moods[mood] = clampf(float(mood_input.get(mood, 0.35)), 0.0, 1.0)
	base["moods"] = moods
	var epic: float = float(moods["epic"])
	var funny: float = float(moods["funny"])
	var creepy: float = float(moods["creepy"])
	var cute: float = float(moods["cute"])
	var wild: float = float(moods["wild"])
	# Biases change geometry, not just colors and descriptive labels.
	base["body_width"] = clampf(rng.randf_range(0.70, 1.28) + funny * 0.25 - creepy * 0.12, 0.65, 1.50)
	base["body_height"] = clampf(rng.randf_range(0.72, 1.29) + epic * 0.24 + creepy * 0.13 - funny * 0.10, 0.65, 1.65)
	base["head_scale"] = clampf(rng.randf_range(0.65, 1.26) + cute * 0.34 + funny * 0.20 - epic * 0.15, 0.58, 1.65)
	base["limb_length"] = clampf(rng.randf_range(0.65, 1.28) + creepy * 0.24 + epic * 0.16, 0.55, 1.68)
	base["eye_count"] = 1 if rng.randf() < creepy * 0.24 else 2
	base["eye_style"] = rng.randi_range(0, 3)
	base["mouth"] = rng.randi_range(0, 2)
	base["horns"] = rng.randi_range(1, 2) if rng.randf() < epic * 0.68 + wild * 0.15 else 0
	base["pattern"] = rng.randi_range(0, 3)
	base["accent_marks"] = rng.randi_range(2, 7)
	base["hue_shift"] = rng.randf_range(-0.065, 0.065)
	# Optional precise constraints are useful for replaying authored genetics.
	for key in TRAITS:
		if options.has(key) and key not in ["form", "element", "subtype", "head", "limbs", "back", "tail", "torso", "abdomen", "stance", "wing_style"]:
			base[key] = options[key]
	return base


static func mutate(original: Dictionary, seed_value: int, intensity: float = 0.5, locks: Dictionary = {}) -> Dictionary:
	var source: Dictionary = original.duplicate(true)
	var options: Dictionary = {"moods": source.get("moods", {})}
	var candidate: Dictionary = sample(seed_value, options)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x124D67
	var chance: float = clampf(intensity, 0.0, 1.0)
	for key in TRAITS:
		if bool(locks.get(key, false)) or rng.randf() >= chance:
			if source.has(key):
				candidate[key] = source[key]
	candidate["form_name"] = CreatureSpeciesGenerator.FORM_NAMES[int(candidate["form"])]
	candidate["seed"] = seed_value
	return candidate


static func _choice(rng: RandomNumberGenerator, options: Dictionary, key: String, count: int) -> int:
	var requested: int = int(options.get(key, -1))
	if requested >= 0 and requested < count:
		return requested
	return rng.randi_range(0, count - 1)
