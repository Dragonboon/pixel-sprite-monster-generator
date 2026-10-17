class_name CreatureGenerationPreset
extends Resource

## Portable authoring configuration for batch generation or runtime use.
## Seeds are intentionally supplied separately to support reproducible variations.

@export_group("Geometry")
@export var sprite_size: Vector2 = Vector2(48, 48)
@export_range(0.0, 100.0, 1.0) var symmetry: float = 100.0
@export_range(0.0, 1.0, 0.05) var organic_shape_strength: float = 0.25
@export var keep_largest_body: bool = true
@export var outlined: bool = true
@export_range(0, 20, 1) var steps: int = 4
@export_range(0, 8, 1) var birth_limit: int = 5
@export_range(0, 8, 1) var death_limit: int = 4

@export_group("Anatomy")
@export var creature_archetype: CreatureMorphology.Archetype = CreatureMorphology.Archetype.BIPED
@export var anatomy_profile: CreatureAnatomyProfile
@export var refined_anatomy: bool = true
@export var structural_variants: bool = true
@export var internal_details_enabled: bool = true
@export_range(0.0, 1.0, 0.05) var internal_detail_strength: float = 0.8
@export_range(0.0, 1.0, 0.05) var anatomy_strength: float = 0.9
@export var facial_eyes: bool = true
@export var silhouette_mood: CreatureMood.Mood = CreatureMood.Mood.NORMAL
@export var horror_profile: CreatureHorrorProfile.Profile = CreatureHorrorProfile.Profile.CLASSIC
@export_range(0.0, 1.0, 0.05) var uncanny_strength: float = 0.75

@export_group("Palette")
@export_range(1, 64, 1) var number_of_colors: int = 10
@export var custom_color_palette: PixelSpriteMonsterGeneratorColorPalette
@export var color_theory_enabled: bool = false
@export var color_harmony: CreatureColorTheory.Harmony = CreatureColorTheory.Harmony.AUTO
@export var color_count_mode: CreatureColorTheory.CountMode = CreatureColorTheory.CountMode.MAXIMUM
@export_range(1, 64, 1) var target_color_count: int = 8
@export var color_saturation: float = 0.5
@export var color_value: float = 0.95
@export var main_noise: FastNoiseLite
@export var secondary_noise: FastNoiseLite

@export_group("Pixel Finish")
@export var visual_style: CreaturePixelEffects.Style = CreaturePixelEffects.Style.CLASSIC
@export var view_mode: CreaturePixelEffects.View = CreaturePixelEffects.View.FRONT
@export_range(0.0, 1.0, 0.05) var shading_strength: float = 0.6
@export_range(0.0, 1.0, 0.05) var dithering_strength: float = 0.15
@export_range(0.0, 1.0, 0.05) var glitch_strength: float = 0.0

@export_group("Selection")
@export var quality_enabled: bool = true
@export_range(0.0, 100.0, 1.0) var quality_min_score: float = 70.0
@export_range(1, 32, 1) var quality_max_attempts: int = 8


## Apply without generating; call draw_sprite() after setting a seed if needed.
func apply_to(generator: PixelSpriteMonsterGenerator) -> void:
	if generator == null:
		return
	generator.sprite_size = sprite_size
	generator.symmetry = symmetry
	generator.organic_shape_strength = organic_shape_strength
	generator.keep_largest_body = keep_largest_body
	generator.outlined = outlined
	generator.steps = steps
	generator.birth_limit = birth_limit
	generator.death_limit = death_limit
	generator.creature_archetype = creature_archetype
	generator.anatomy_profile = anatomy_profile
	generator.refined_anatomy = refined_anatomy
	generator.structural_variants = structural_variants
	generator.internal_details_enabled = internal_details_enabled
	generator.internal_detail_strength = internal_detail_strength
	generator.anatomy_strength = anatomy_strength
	generator.facial_eyes = facial_eyes
	generator.silhouette_mood = silhouette_mood
	generator.horror_profile = horror_profile
	generator.uncanny_strength = uncanny_strength
	generator.number_of_colors = number_of_colors
	generator.custom_color_palette = custom_color_palette
	generator.color_theory_enabled = color_theory_enabled
	generator.color_harmony = color_harmony
	generator.color_count_mode = color_count_mode
	generator.target_color_count = target_color_count
	generator.color_saturation = color_saturation
	generator.color_value = color_value
	if main_noise != null:
		generator.main_noise = main_noise
	if secondary_noise != null:
		generator.secondary_noise = secondary_noise
	generator.visual_style = visual_style
	generator.view_mode = view_mode
	generator.shading_strength = shading_strength
	generator.dithering_strength = dithering_strength
	generator.glitch_strength = glitch_strength
	generator.quality_enabled = quality_enabled
	generator.quality_min_score = quality_min_score
	generator.quality_max_attempts = quality_max_attempts
	generator.cell_animation = false
