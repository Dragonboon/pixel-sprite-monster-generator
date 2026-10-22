class_name CreatureTopdownMotion
extends RefCounted

## Deterministic family-aware 4-frame motion curves.
## Coordinates use puppet-local forward (towards the face) and Z (ground height).
## This class owns no textures, mutable state or global RNG.
static func sample(genome: Dictionary, action: int, frame: int) -> Dictionary:
	var family: int = clampi(int(genome.get("family", 0)), 0, CreatureTopdownGenerator.Family.size() - 1)
	var tick: int = posmod(frame, CreatureTopdownGenerator.FRAMES)
	var phase: float = float(tick) * TAU / float(CreatureTopdownGenerator.FRAMES)
	var walk: bool = action in [CreatureTopdownGenerator.Action.WALK, CreatureTopdownGenerator.Action.WALK_B, CreatureTopdownGenerator.Action.DASH]
	var variant: bool = action == CreatureTopdownGenerator.Action.WALK_B
	var dash: bool = action == CreatureTopdownGenerator.Action.DASH
	var faint: bool = action == CreatureTopdownGenerator.Action.FAINT
	var factor: float = 1.3 if variant else (1.65 if dash else 1.0)
	var progress: float = float(tick) / float(CreatureTopdownGenerator.FRAMES - 1)
	var floating: bool = family in [CreatureTopdownGenerator.Family.GHOST, CreatureTopdownGenerator.Family.BAT]
	var ground_bob: float = 0.0
	if walk:
		ground_bob = 1.05 * (1.0 - cos(phase * 2.0)) if not floating else 0.95 * sin(phase)
	elif action == CreatureTopdownGenerator.Action.IDLE_B:
		ground_bob = 0.9 * sin(phase)
	else:
		ground_bob = 0.35 * sin(phase)
	return {
		"phase": phase,
		"walk": walk,
		"stride": (3.6 * factor if walk and not floating else 0.0),
		"lift": (2.8 * factor if walk and not floating else 0.0),
		"body_bob": ground_bob,
		"tail_sway": (2.6 if walk else 1.2) * sin(phase),
		"wing_flap": (2.8 if family == CreatureTopdownGenerator.Family.BAT else 1.5) * sin(phase),
		"recoil": 2.0 if action == CreatureTopdownGenerator.Action.HURT and tick % 2 == 1 else 0.0,
		"lunge": (2.8 if action in [CreatureTopdownGenerator.Action.ATTACK, CreatureTopdownGenerator.Action.SHOOT] else 0.0) * sin(PI * progress),
		"head_lift": (2.0 if action == CreatureTopdownGenerator.Action.CHARGE else 0.0) * sin(PI * progress),
		"collapse": 1.0 - (0.83 * progress if faint else 0.0),
		"faint_progress": progress if faint else 0.0,
		"dash_progress": progress if dash else 0.0,
		"alpha": 0.42 if faint and tick == CreatureTopdownGenerator.FRAMES - 1 else 1.0,
		"ground_contact": not floating and family != CreatureTopdownGenerator.Family.SERPENT
	}


## side -1/+1; limb_index 0 = rear leg, 1 = foreleg.
## Diagonal phase offset creates a four-beat beast gait.
static func foot(pose: Dictionary, family: int, side: float, limb_index: int = 0) -> Dictionary:
	var phase: float = float(pose["phase"]) + (PI if side > 0.0 else 0.0)
	if family in [CreatureTopdownGenerator.Family.BEAST, CreatureTopdownGenerator.Family.SHELL] and limb_index == 1:
		phase += PI
	elif family == CreatureTopdownGenerator.Family.BEETLE:
		phase += float(limb_index) * (2.0 * PI / 3.0)
	return {
		"forward": cos(phase) * float(pose["stride"]),
		"lift": maxf(0.0, sin(phase)) * float(pose["lift"]),
		"contact": sin(phase) <= 0.0 or not bool(pose["walk"])
	}


static func gait_name(family: int) -> String:
	match family:
		CreatureTopdownGenerator.Family.BEAST, CreatureTopdownGenerator.Family.SHELL:
			return "quadruped"
		CreatureTopdownGenerator.Family.BEETLE:
			return "six_leg_crawl"
		CreatureTopdownGenerator.Family.BAT:
			return "wing_flutter"
		CreatureTopdownGenerator.Family.GHOST:
			return "hover"
		CreatureTopdownGenerator.Family.SERPENT:
			return "undulation"
		_:
			return "biped"
