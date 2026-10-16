class_name CreatureAnatomyProfile
extends Resource

@export_range(0.15, 0.8, 0.01) var body_width_min: float = 0.35
@export_range(0.15, 0.8, 0.01) var body_width_max: float = 0.55
@export_range(0.15, 0.8, 0.01) var body_height_min: float = 0.42
@export_range(0.15, 0.8, 0.01) var body_height_max: float = 0.64
@export_range(0.1, 0.4, 0.01) var head_min: float = 0.18
@export_range(0.1, 0.4, 0.01) var head_max: float = 0.32
@export_range(0.1, 0.5, 0.01) var appendage_min: float = 0.16
@export_range(0.1, 0.5, 0.01) var appendage_max: float = 0.34

func sample(rng: RandomNumberGenerator, mood: int) -> Dictionary:
	var body_width: float = rng.randf_range(minf(body_width_min, body_width_max), maxf(body_width_min, body_width_max))
	var body_height: float = rng.randf_range(minf(body_height_min, body_height_max), maxf(body_height_min, body_height_max))
	var head: float = rng.randf_range(minf(head_min, head_max), maxf(head_min, head_max))
	var appendage: float = rng.randf_range(minf(appendage_min, appendage_max), maxf(appendage_min, appendage_max))
	match mood:
		CreatureMood.Mood.COZY:
			body_width *= 1.18
			head *= 1.20
			appendage *= 0.75
		CreatureMood.Mood.HORROR:
			body_width *= 0.82
			appendage *= 1.30
		CreatureMood.Mood.EPIC:
			body_width *= 1.25
			body_height *= 1.10
			appendage *= 1.25
	return {"body_width": clampf(body_width, 0.1, 0.9), "body_height": clampf(body_height, 0.1, 0.9), "head": clampf(head, 0.1, 0.5), "appendage": clampf(appendage, 0.1, 0.5)}
