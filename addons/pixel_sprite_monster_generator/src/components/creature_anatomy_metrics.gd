class_name CreatureAnatomyMetrics
extends RefCounted

## Relative structure checks, designed to complement (not replace) pixel-art curation.
static func evaluate(map: Array[Variant], archetype: CreatureMorphology.Archetype, sampled: Dictionary) -> Dictionary:
	if map.is_empty() or map[0].is_empty():
		return {"score": 0.0, "body_coverage": 0.0, "appendage_balance": 0.0, "base_support": 0.0}
	var w: int = map.size()
	var h: int = map[0].size()
	var cx: int = w / 2
	var cy: int = h / 2
	var torso_width: int = maxi(2, roundi(float(w) * float(sampled.get("body_width", 0.45)) * 0.5))
	var torso_height: int = maxi(2, roundi(float(h) * float(sampled.get("body_height", 0.52)) * 0.5))
	var core: int = 0
	var core_capacity: int = 0
	for x in range(maxi(0, cx - torso_width), mini(w, cx + torso_width + 1)):
		for y in range(maxi(0, cy - torso_height), mini(h, cy + torso_height + 1)):
			core_capacity += 1
			if map[x][y]:
				core += 1
	var body_coverage: float = float(core) / float(maxi(1, core_capacity))
	var left_count: int = 0
	var right_count: int = 0
	var bottom_count: int = 0
	var top_count: int = 0
	for x in w:
		for y in h:
			if not map[x][y]:
				continue
			if x < cx - torso_width:
				left_count += 1
			if x > cx + torso_width:
				right_count += 1
			if y >= h * 3 / 4:
				bottom_count += 1
			if y <= h / 4:
				top_count += 1
	var appendage_balance: float = 1.0 - float(absi(left_count - right_count)) / float(maxi(1, left_count + right_count))
	var base_support: float = clampf(float(bottom_count) / maxf(1.0, float(w) * 0.20), 0.0, 1.0)
	var proportions: float = 0.0
	match archetype:
		CreatureMorphology.Archetype.BIPED:
			proportions = 0.5 * base_support + 0.5 * appendage_balance
		CreatureMorphology.Archetype.INSECTOID:
			proportions = 0.65 * appendage_balance + 0.35 * clampf(float(left_count + right_count) / maxf(1.0, float(w) * 0.15), 0.0, 1.0)
		CreatureMorphology.Archetype.SLIME:
			proportions = 0.75 * base_support + 0.25 * clampf(1.0 - float(top_count) / maxf(1.0, float(bottom_count + top_count)), 0.0, 1.0)
		CreatureMorphology.Archetype.WINGED:
			proportions = 0.7 * appendage_balance + 0.3 * clampf(float(left_count + right_count) / maxf(1.0, float(w) * 0.3), 0.0, 1.0)
		_:
			proportions = 0.5 * appendage_balance + 0.5 * base_support
	return {"score": 100.0 * (0.40 * body_coverage + 0.60 * proportions), "body_coverage": body_coverage, "appendage_balance": appendage_balance, "base_support": base_support}
