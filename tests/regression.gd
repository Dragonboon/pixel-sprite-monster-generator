extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var generator := PixelSpriteMonsterGenerator.new()
	generator.randomize_seed = false
	generator.manual_seed = 42
	generator.cell_animation = false
	var noise_seed: int = generator.main_noise.seed
	var authored := Node.new()
	generator.add_child(authored)
	root.add_child(generator)
	assert(is_instance_valid(authored), "Regeneration deleted a game-owned child")
	var first: Dictionary = generator.all_color_groups.duplicate(true)
	var first_pixels: PackedByteArray = generator.get_image().get_data()
	seed(12345)
	var expected_random := randi()
	seed(12345)
	for i in 4:
		generator.draw_sprite()
		assert(generator.all_color_groups == first, "Fixed seed must reproduce geometry and colors")
		assert(generator.get_image().get_data() == first_pixels)
		assert(generator.get_child_count() == 2)
	assert(randi() == expected_random, "Generation changed the game's random stream")
	assert(generator.main_noise.seed == noise_seed, "Preset noise was mutated")
	for cell in generator.cell_group_drawer.cells():
		assert(is_equal_approx(cell.draw_size, 128.0 / 48.0))
	generator.manual_seed = 43
	generator.draw_sprite()
	assert(generator.get_image().get_data() != first_pixels)
	generator.randomize_seed = true
	generator.draw_sprite()
	var random_pixels: PackedByteArray = generator.get_image().get_data()
	generator.randomize_seed = false
	generator.manual_seed = generator.last_seed
	generator.draw_sprite()
	assert(generator.get_image().get_data() == random_pixels)
	generator.eye_color_saturation = 0.0
	generator.eye_color_value = 0.25
	generator.draw_sprite()
	for color in generator.eye_scheme:
		assert(is_equal_approx(color.r, 0.25) and is_equal_approx(color.g, 0.25))
	generator.number_of_colors = 1
	generator.color_generation_method = ColorSchemeGenerator.ColorGenerationMethod.RandomRGB
	generator.draw_sprite()
	assert(generator.scheme.size() == 1)
	assert(is_finite(generator.scheme[0].r))
	generator.sprite_size = Vector2(33, 25)
	generator.pixel_perfect = true
	generator.steps = 0
	generator.custom_color_palette = PixelSpriteMonsterGeneratorColorPalette.new()
	generator.custom_color_palette.colors = PackedColorArray([Color.RED, Color.BLUE])
	generator.draw_sprite()
	assert(generator.cellular_automata.default_steps == 0)
	assert(generator.scheme == generator.custom_color_palette.colors)
	assert(generator.get_image().get_size() == Vector2i(35, 27))
	for cell in generator.cell_group_drawer.cells():
		assert(cell.draw_size == 1.0)
	# A non-square odd-width map must still be symmetric at 100 percent.
	var map: Array = generator.map_generator.generate_new(Vector2(33, 25), 100.0)
	for x in 33:
		for y in 25:
			assert(map[x][y] == map[32 - x][y])
	generator.sprite_size = Vector2(-1, 0)
	generator.number_of_colors = 0
	generator.main_noise = null
	generator.secondary_noise = null
	generator.draw_sprite()
	assert(generator.sprite_size == Vector2(4, 4) and generator.number_of_colors == 1)
	# Export a representative neutral sprite for visual review.
	generator.sprite_size = Vector2(48, 48)
	generator.custom_color_palette = null
	generator.number_of_colors = 12
	generator.steps = 4
	generator.manual_seed = 42
	generator.draw_sprite()
	assert(generator.export_png("user://monster-test.png") == OK)
	var png := Image.load_from_file("user://monster-test.png")
	assert(png.get_size() == Vector2i(50, 50) and not png.is_invisible())
	assert(png.get_data() == generator.get_image().get_data())
	print("Exported: ", ProjectSettings.globalize_path("user://monster-test.png"))
	# Opt-in shape cleanup and deterministic regeneration.
	var fragments: Array[Variant] = [[true, true, false], [false, false, false], [false, false, true]]
	var cleaned := SilhouetteRefiner.refine(fragments, 0.0, true)
	assert(cleaned[0][0] and cleaned[0][1] and not cleaned[2][2])
	generator.organic_shape_strength = 0.65
	generator.keep_largest_body = true
	generator.draw_sprite()
	var organic_pixels: PackedByteArray = generator.get_image().get_data()
	generator.draw_sprite()
	assert(generator.get_image().get_data() == organic_pixels)
	# Archetypes are opt-in and never affect the original random stream.
	generator.organic_shape_strength = 0.45
	generator.keep_largest_body = true
	var distinct: Dictionary = {}
	for archetype in [CreatureMorphology.Archetype.BIPED, CreatureMorphology.Archetype.INSECTOID, CreatureMorphology.Archetype.SLIME, CreatureMorphology.Archetype.WINGED]:
		generator.creature_archetype = archetype
		generator.facial_eyes = true
		generator.manual_seed = 42
		generator.draw_sprite()
		var pixels: PackedByteArray = generator.get_image().get_data()
		generator.draw_sprite()
		assert(generator.get_image().get_data() == pixels, "Archetypes must reproduce with a fixed seed")
		distinct[hash(pixels)] = true
	assert(distinct.size() >= 2, "Archetypes should produce distinct silhouettes")
	var sample: Array[Variant] = []
	for x in 32:
		var column: Array = []
		for y in 32:
			column.append(x >= 7 and x <= 24 and y >= 7 and y <= 24)
		sample.append(column)
	var insect := CreatureMorphology.apply(sample, CreatureMorphology.Archetype.INSECTOID, 1.0, 42)
	for x in 32:
		for y in 32:
			assert(insect[x][y] == insect[31 - x][y], "Anatomy must preserve symmetry on symmetric maps")
	# Anatomical ranges remain deterministic with editable resource presets.
	var profile := CreatureAnatomyProfile.new()
	profile.body_width_min = 0.42
	profile.body_width_max = 0.42
	generator.anatomy_profile = profile
	generator.creature_archetype = CreatureMorphology.Archetype.BIPED
	generator.manual_seed = 7788
	generator.draw_sprite()
	assert(is_equal_approx(float(generator.last_anatomy["body_width"]), 0.42))
	var anatomical_pixels: PackedByteArray = generator.get_image().get_data()
	generator.draw_sprite()
	assert(generator.get_image().get_data() == anatomical_pixels)
	generator.anatomy_profile = null
	# Quality filtering is deterministic and returns useful metadata even if the
	# threshold is unreachable within the bounded number of attempts.
	generator.creature_archetype = CreatureMorphology.Archetype.ORIGINAL
	generator.silhouette_mood = CreatureMood.Mood.COZY
	generator.quality_enabled = true
	generator.quality_min_score = 100.0
	generator.quality_max_attempts = 4
	generator.manual_seed = 2026
	generator.draw_sprite()
	var selected_seed: int = generator.last_seed
	var quality_pixels: PackedByteArray = generator.get_image().get_data()
	assert(generator.last_quality_attempts == 4)
	generator.draw_sprite()
	assert(generator.last_seed == selected_seed)
	assert(generator.get_image().get_data() == quality_pixels)
	assert(generator.last_quality_score > 0.0)
	assert(not generator.quality_accepted or generator.last_quality_score >= 100.0)
	generator.quality_min_score = 0.0
	generator.draw_sprite()
	assert(generator.quality_accepted and generator.last_quality_attempts == 1)
	generator.quality_enabled = false
	generator.silhouette_mood = CreatureMood.Mood.NORMAL
	# Artistic styles should differ in tonal range, not merely hue.
	var reference := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	reference.fill(Color(0.47, 0.38, 0.59))
	var cozy := CreaturePixelEffects.process(reference, CreaturePixelEffects.Style.COZY, CreaturePixelEffects.View.FRONT, 0.6, 0.0, 0.0, 12)
	var dungeon := CreaturePixelEffects.process(reference, CreaturePixelEffects.Style.DUNGEON, CreaturePixelEffects.View.FRONT, 0.6, 0.0, 0.0, 12)
	assert(cozy.get_data() != dungeon.get_data(), "Distinct art styles must differ visibly")
	assert(cozy.get_pixel(5, 5).get_luminance() > dungeon.get_pixel(5, 5).get_luminance() + 0.25)
	# Multiple new views are deterministic and stay within a native RGBA grid.
	var view_source := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	view_source.fill(Color.TRANSPARENT)
	for y in range(8, 30):
		for x in range(11, 29):
			view_source.set_pixel(x, y, Color(0.6, 0.4, 0.25))
	for view in [CreaturePixelEffects.View.THREE_QUARTER_RIGHT, CreaturePixelEffects.View.PROFILE_LEFT, CreaturePixelEffects.View.PROFILE_RIGHT, CreaturePixelEffects.View.BACK, CreaturePixelEffects.View.ISOMETRIC]:
		var projection: Image = CreaturePixelEffects.project(view_source, view)
		assert(projection.get_size() == view_source.get_size())
		assert(not projection.is_invisible())
		assert(projection.get_data() == CreaturePixelEffects.project(view_source, view).get_data())
	assert(CreaturePixelEffects.project(view_source, CreaturePixelEffects.View.PROFILE_LEFT).get_data() != view_source.get_data())
	assert(CreaturePixelEffects.project(view_source, CreaturePixelEffects.View.ISOMETRIC).get_data() != view_source.get_data())
	# Profiles opt into combined geometric and anatomy-specific quality scores.
	generator.visual_style = CreaturePixelEffects.Style.CLASSIC
	generator.view_mode = CreaturePixelEffects.View.FRONT
	generator.anatomy_profile = CreatureAnatomyProfile.new()
	generator.creature_archetype = CreatureMorphology.Archetype.WINGED
	generator.quality_enabled = true
	generator.quality_min_score = 68.0
	generator.quality_max_attempts = 3
	generator.manual_seed = 5151
	generator.draw_sprite()
	assert(generator.last_anatomy_metrics.has("score"))
	var metrics_before: Dictionary = generator.last_anatomy_metrics.duplicate(true)
	var quality_before: float = generator.last_quality_score
	generator.draw_sprite()
	assert(generator.last_anatomy_metrics == metrics_before)
	assert(is_equal_approx(generator.last_quality_score, quality_before))
	generator.quality_enabled = false
	generator.anatomy_profile = null
	# Pixel effects preserve logical resolution and deterministic CPU-only PNG exports.
	generator.visual_style = CreaturePixelEffects.Style.HANDHELD
	generator.view_mode = CreaturePixelEffects.View.THREE_QUARTER
	generator.shading_strength = 0.75
	generator.dithering_strength = 0.3
	generator.glitch_strength = 0.2
	generator.draw_sprite()
	var effect_pixels: PackedByteArray = generator.get_image().get_data()
	generator.draw_sprite()
	assert(generator.get_image().get_data() == effect_pixels)
	assert(generator.export_png("user://styled-monster-test.png") == OK)
	# Silhouette diagnostic separates visual duplicates from palette changes.
	var v0 := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	v0.fill(Color.TRANSPARENT)
	for y in range(4, 12):
		for x in range(4, 12):
			v0.set_pixel(x, y, Color.RED)
	var v1: Image = v0.duplicate()
	for y in range(4, 12):
		for x in range(4, 12):
			v1.set_pixel(x, y, Color.BLUE)
	var v2 := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	v2.fill(Color.TRANSPARENT)
	for y in range(4, 12):
		for x in range(7, 9):
			v2.set_pixel(x, y, Color.GREEN)
	var silhouettes: Array[Dictionary] = [{"image": v0}, {"image": v1}, {"image": v2}]
	var diversity: Dictionary = CreatureVariety.summarize(silhouettes)
	assert(diversity["silhouette_unique"] == 2)
	assert(diversity["near_duplicates"] == 1)
	assert(diversity["exact_unique"] == 3)
	assert(is_equal_approx(CreatureVariety.distance(CreatureVariety.signature(v0), CreatureVariety.signature(v1)), 0.0))
	# Sparse or detached components must score worse than an equivalent solid body.
	var filled: Array[Variant] = []
	var fragmented: Array[Variant] = []
	for x in 24:
		var solid_col: Array = []
		var sparse_col: Array = []
		for y in 24:
			var inside: bool = x >= 4 and x < 20 and y >= 4 and y < 20
			solid_col.append(inside)
			sparse_col.append(inside and (x % 3 == 0 or y % 3 == 0))
		filled.append(solid_col)
		fragmented.append(sparse_col)
	var solid_quality: Dictionary = CreatureQuality.measure(filled)
	var broken_quality: Dictionary = CreatureQuality.measure(fragmented)
	assert(solid_quality["score"] > broken_quality["score"])
	assert(broken_quality.has("components") and broken_quality.has("occupancy"))
	# Same-seed morphology review, without renderer or Godot Actions.
	var anatomy_source_rng := RandomNumberGenerator.new()
	var review_signatures: Dictionary = {}
	var anatomy_ratios: Dictionary = {"body_width": 0.44, "body_height": 0.54, "head": 0.25, "appendage": 0.26}
	for family in [CreatureMorphology.Archetype.INSECTOID, CreatureMorphology.Archetype.QUADRUPED, CreatureMorphology.Archetype.GOLEM, CreatureMorphology.Archetype.SPIRIT]:
		for reviewed_seed in [42, 1042, 4200]:
			anatomy_source_rng.seed = reviewed_seed
			var input_mask: Array[Variant] = MapGenerator.new(anatomy_source_rng).generate_new(Vector2(48, 48), 100.0)
			var refined: Array[Variant] = CreatureAnatomyRefiner.refine(input_mask, family, 0.95, anatomy_ratios, reviewed_seed)
			assert(refined == CreatureAnatomyRefiner.refine(input_mask, family, 0.95, anatomy_ratios, reviewed_seed))
			var shaped: Dictionary = CreatureQuality.measure(refined)
			assert(shaped["width"] >= 12 and shaped["height"] >= 16)
			assert(float(shaped["connected_ratio"]) >= 0.85)
			review_signatures[hash(refined)] = true
	assert(review_signatures.size() >= 8, "Archetypes should remain meaningfully distinct")
	assert(not CreatureAnatomyRefiner.supports(CreatureMorphology.Archetype.ORIGINAL))
	# Refined and legacy modes must replay individually with the same seed.
	generator.creature_archetype = CreatureMorphology.Archetype.GOLEM
	generator.anatomy_profile = CreatureAnatomyProfile.new()
	generator.manual_seed = 1042
	generator.quality_enabled = false
	generator.refined_anatomy = true
	generator.draw_sprite()
	var refined_pixels: PackedByteArray = generator.get_image().get_data()
	generator.draw_sprite()
	assert(refined_pixels == generator.get_image().get_data())
	generator.refined_anatomy = false
	generator.draw_sprite()
	var legacy_pixels: PackedByteArray = generator.get_image().get_data()
	assert(refined_pixels != legacy_pixels)
	generator.refined_anatomy = true
	generator.anatomy_profile = null
	# Internal trait profiles remain deterministic, vary by seed and do not
	# affect silhouette geometry, alpha or the global random stream.
	var traits_per_seed: Dictionary = {}
	var detail_base := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	detail_base.fill(Color.TRANSPARENT)
	for dy in range(5, 43):
		for dx in range(5, 43):
			detail_base.set_pixel(dx, dy, Color(0.47, 0.55, 0.65, 1.0))
	for family in [CreatureMorphology.Archetype.INSECTOID, CreatureMorphology.Archetype.GOLEM, CreatureMorphology.Archetype.SPIRIT, CreatureMorphology.Archetype.QUADRUPED]:
		var family_outputs: Dictionary = {}
		for trait_seed in [42, 1042, 4200, 9913]:
			var traits: Dictionary = CreatureTraitProfile.derive(family, trait_seed, CreatureMood.Mood.NORMAL)
			assert(traits == CreatureTraitProfile.derive(family, trait_seed, CreatureMood.Mood.NORMAL))
			var decorated: Image = CreatureInternalDetails.render(detail_base, family, traits, 0.9)
			assert(decorated.get_size() == detail_base.get_size())
			var changed: int = 0
			for yy in decorated.get_height():
				for xx in decorated.get_width():
					assert(is_equal_approx(decorated.get_pixel(xx, yy).a, detail_base.get_pixel(xx, yy).a))
					if decorated.get_pixel(xx, yy) != detail_base.get_pixel(xx, yy):
						changed += 1
			assert(changed >= 3)
			assert(decorated.get_data() == CreatureInternalDetails.render(detail_base, family, traits, 0.9).get_data())
			family_outputs[hash(decorated.get_data())] = true
		assert(family_outputs.size() >= 2, "Each archetype requires visible seeded detail variety")
		traits_per_seed[family] = family_outputs.size()
	assert(CreatureInternalDetails.render(detail_base, CreatureMorphology.Archetype.ORIGINAL, {}, 1.0).get_data() == detail_base.get_data())
	# An existing sprite remains reproducible and can opt out of details.
	generator.anatomy_profile = CreatureAnatomyProfile.new()
	generator.creature_archetype = CreatureMorphology.Archetype.GOLEM
	generator.refined_anatomy = true
	generator.internal_details_enabled = true
	generator.internal_detail_strength = 0.9
	generator.manual_seed = 1042
	generator.quality_enabled = false
	generator.draw_sprite()
	var detailed_pixels: PackedByteArray = generator.get_image().get_data()
	var stored_traits: Dictionary = generator.last_traits.duplicate(true)
	generator.draw_sprite()
	assert(generator.get_image().get_data() == detailed_pixels)
	assert(generator.last_traits == stored_traits)
	generator.internal_details_enabled = false
	generator.draw_sprite()
	assert(generator.last_traits.is_empty())
	assert(generator.get_image().get_data() != detailed_pixels)
	generator.internal_details_enabled = true
	generator.anatomy_profile = null
	# Morphotypes vary geometrically across seeds, without losing deterministic replay.
	var base_map: Array[Variant] = []
	for mx in 48:
		var column: Array = []
		for my in 48:
			column.append(mx >= 12 and mx <= 35 and my >= 12 and my <= 35)
		base_map.append(column)
	var dimensions: Dictionary = {"body_width": 0.44, "body_height": 0.52, "head": 0.25, "appendage": 0.24}
	var subtype_shapes: Dictionary = {}
	for variant_seed in range(60, 66):
		var shape: Dictionary = CreatureStructuralVariants.sample(CreatureMorphology.Archetype.SPIRIT, variant_seed, CreatureMood.Mood.NORMAL)
		var mask: Array[Variant] = CreatureStructuralVariants.apply(base_map, CreatureMorphology.Archetype.SPIRIT, 0.95, dimensions, shape, variant_seed)
		assert(mask == CreatureStructuralVariants.apply(base_map, CreatureMorphology.Archetype.SPIRIT, 0.95, dimensions, shape, variant_seed))
		assert(float(CreatureQuality.measure(mask)["connected_ratio"]) > 0.70)
		subtype_shapes[hash(mask)] = true
	assert(subtype_shapes.size() >= 5)
	for family in [CreatureMorphology.Archetype.BIPED, CreatureMorphology.Archetype.SLIME, CreatureMorphology.Archetype.WINGED, CreatureMorphology.Archetype.INSECTOID, CreatureMorphology.Archetype.QUADRUPED, CreatureMorphology.Archetype.GOLEM]:
		var family_variants: Dictionary = {}
		for variant_seed in range(60, 64):
			var shape: Dictionary = CreatureStructuralVariants.sample(family, variant_seed, CreatureMood.Mood.NORMAL)
			family_variants[hash(CreatureStructuralVariants.apply(base_map, family, 0.9, dimensions, shape, variant_seed))] = true
		assert(family_variants.size() > 1)
	# Classic silhouette is available by disabling the structural variant pass.
	generator.creature_archetype = CreatureMorphology.Archetype.SPIRIT
	generator.anatomy_profile = CreatureAnatomyProfile.new()
	generator.structural_variants = true
	generator.manual_seed = 1042
	generator.quality_enabled = false
	generator.draw_sprite()
	var seeded_structure: Dictionary = generator.last_structure.duplicate(true)
	var seeded_image: PackedByteArray = generator.get_image().get_data()
	generator.draw_sprite()
	assert(generator.last_structure == seeded_structure)
	assert(generator.get_image().get_data() == seeded_image)
	generator.structural_variants = false
	generator.draw_sprite()
	assert(generator.last_structure.is_empty())
	generator.anatomy_profile = null
	generator.structural_variants = true
	# Palette roles and exact-color quantization are deterministic and alpha-safe.
	var swatch := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	swatch.fill(Color.TRANSPARENT)
	for sy in range(2, 30):
		for sx in range(2, 30):
			swatch.set_pixel(sx, sy, Color.from_hsv(float(sx) / 32.0, 0.62, float(sy) / 32.0))
	for harmony in [CreatureColorTheory.Harmony.MONOCHROMATIC, CreatureColorTheory.Harmony.ANALOGOUS, CreatureColorTheory.Harmony.COMPLEMENTARY, CreatureColorTheory.Harmony.SPLIT_COMPLEMENTARY, CreatureColorTheory.Harmony.TRIADIC, CreatureColorTheory.Harmony.TETRADIC, CreatureColorTheory.Harmony.NEUTRAL_ACCENT, CreatureColorTheory.Harmony.AUTO]:
		var spec: Dictionary = CreatureColorTheory.build(4200, 7, harmony, CreatureMood.Mood.NORMAL, CreatureMorphology.Archetype.SPIRIT)
		var colors: PackedColorArray = spec["colors"]
		assert(colors.size() == 7)
		assert(colors == CreatureColorTheory.build(4200, 7, harmony, CreatureMood.Mood.NORMAL, CreatureMorphology.Archetype.SPIRIT)["colors"])
		var exact: Image = CreatureColorTheory.quantize(swatch, colors, CreatureColorTheory.CountMode.EXACT)
		var limited: Image = CreatureColorTheory.quantize(swatch, colors, CreatureColorTheory.CountMode.MAXIMUM)
		assert(CreatureColorTheory.count_opaque_colors(exact) == 7)
		assert(CreatureColorTheory.count_opaque_colors(limited) <= 7)
		assert(exact.get_pixel(0, 0).a == 0.0)
		assert(exact.get_data() == CreatureColorTheory.quantize(swatch, colors, CreatureColorTheory.CountMode.EXACT).get_data())
	var monochrome: Dictionary = CreatureColorTheory.build(17, 1, CreatureColorTheory.Harmony.MONOCHROMATIC, CreatureMood.Mood.COZY, CreatureMorphology.Archetype.SLIME)
	assert(CreatureColorTheory.count_opaque_colors(CreatureColorTheory.quantize(swatch, monochrome["colors"], CreatureColorTheory.CountMode.EXACT)) == 1)
	# Uncanny Horror has six distinct, deterministic connected figures, while
	# the classic Horror path and unsupported families remain unaffected.
	var uncanny_types: Dictionary = {}
	var horror_map: Array[Variant] = []
	for xx in 48:
		var column: Array[bool] = []
		column.resize(48)
		column.fill(false)
		horror_map.append(column)
	for uncanny_seed in range(36, 42):
		var traits: Dictionary = CreatureHorrorProfile.sample(uncanny_seed, 0.85)
		var figure: Array[Variant] = CreatureHorrorProfile.apply(horror_map, CreatureMorphology.Archetype.BIPED, traits)
		assert(figure == CreatureHorrorProfile.apply(horror_map, CreatureMorphology.Archetype.BIPED, traits))
		assert(float(CreatureQuality.measure(figure)["connected_ratio"]) >= 0.70)
		uncanny_types[traits["subtype"]] = true
	assert(uncanny_types.size() == 6)
	assert(CreatureHorrorProfile.apply(horror_map, CreatureMorphology.Archetype.SLIME, CreatureHorrorProfile.sample(42, 0.8)) == horror_map)
	var horror_palette: Dictionary = CreatureHorrorProfile.palette(42, 7)
	assert((horror_palette["colors"] as PackedColorArray).size() == 7)
	# Refined quantization preserves alpha and palette counts deterministically.
	var spec_refined: Dictionary = CreatureColorTheory.build(42, 6, CreatureColorTheory.Harmony.ANALOGOUS, CreatureMood.Mood.NORMAL, CreatureMorphology.Archetype.GOLEM)
	var detail_guide := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	detail_guide.fill(Color.TRANSPARENT)
	detail_guide.set_pixel(14, 14, Color.WHITE)
	var mapped: Image = CreatureColorTheory.quantize_refined(swatch, spec_refined["colors"], spec_refined["roles"], CreatureColorTheory.CountMode.EXACT, detail_guide)
	assert(CreatureColorTheory.count_opaque_colors(mapped) == 6)
	assert(mapped.get_pixel(0, 0).a == 0.0)
	assert(mapped.get_data() == CreatureColorTheory.quantize_refined(swatch, spec_refined["colors"], spec_refined["roles"], CreatureColorTheory.CountMode.EXACT, detail_guide).get_data())
	assert(CreatureColorTheory.count_opaque_colors(CreatureColorTheory.quantize_refined(swatch, spec_refined["colors"], spec_refined["roles"], CreatureColorTheory.CountMode.MAXIMUM, detail_guide)) <= 6)
	# The cached finishing stage must preserve the original output and seeds.
	generator.creature_archetype = CreatureMorphology.Archetype.SPIRIT
	generator.anatomy_profile = CreatureAnatomyProfile.new()
	generator.refined_anatomy = true
	generator.structural_variants = true
	generator.internal_details_enabled = true
	generator.internal_detail_strength = 0.8
	generator.visual_style = CreaturePixelEffects.Style.ARCADE
	generator.view_mode = CreaturePixelEffects.View.FRONT
	generator.shading_strength = 0.65
	generator.dithering_strength = 0.25
	generator.glitch_strength = 0.0
	generator.randomize_seed = false
	generator.manual_seed = 4200
	generator.quality_enabled = false
	generator.draw_sprite()
	var native_image: Image = generator.get_unfinished_image()
	var composed: Image = generator.finish_image(native_image)
	assert(native_image != null and native_image.get_size() == generator.get_image().get_size())
	assert(composed.get_data() == generator.get_image().get_data())
	var native_bytes: PackedByteArray = native_image.get_data()
	var stored_seed: int = generator.last_seed
	var style_only: Image = CreaturePreviewComposer.compose(
		native_image, generator.creature_archetype, generator.last_traits,
		true, 0.8, CreaturePixelEffects.Style.ARCADE,
		CreaturePixelEffects.View.FRONT, 0.2, 0.25, 0.0, stored_seed
	)
	assert(style_only.get_data() == CreaturePreviewComposer.compose(
		native_image, generator.creature_archetype, generator.last_traits,
		true, 0.8, CreaturePixelEffects.Style.ARCADE,
		CreaturePixelEffects.View.FRONT, 0.2, 0.25, 0.0, stored_seed
	).get_data())
	assert(native_image.get_data() == native_bytes)
	assert(generator.last_seed == stored_seed)
	generator.anatomy_profile = null
	# Isolated batch generation does not mutate or delete the live preview.
	var authoring := CreatureGenerationPreset.new()
	authoring.quality_max_attempts = 2
	authoring.quality_min_score = 0.0
	authoring.creature_archetype = CreatureMorphology.Archetype.SLIME
	authoring.anatomy_profile = CreatureAnatomyProfile.new()
	var preserved: PackedByteArray = generator.get_image().get_data()
	var batch: Array[Dictionary] = CreatureBatchGenerator.generate(authoring, root, 3, 2500)
	assert(batch.size() == 3)
	# Exact counts: reject invalid requests, never truncate silently.
	assert(CreatureBatchGenerator.generate(authoring, root, 17, 2500).is_empty())
	for amount in [1, 2, 6, 17]:
		var encounter: Dictionary = CreatureBatchGenerator.generate_encounter(authoring, root, amount, 2500)
		assert(encounter["error"] == OK)
		assert(encounter["generated_count"] == amount)
		assert(encounter["items"].size() == amount)
		assert(float(encounter["elapsed_ms"]) >= 0.0)
	assert(CreatureBatchGenerator.generate_encounter(authoring, root, 0, 2500)["error"] == ERR_INVALID_PARAMETER)
	assert(CreatureBatchGenerator.generate_encounter(authoring, root, 129, 2500)["error"] == ERR_INVALID_PARAMETER)
	var async_result: Dictionary = await CreatureBatchGenerator.generate_encounter_async(authoring, root, 6, 2500, CreatureBatchGenerator.DEFAULT_SEED_STEP, 2)
	assert(async_result["error"] == OK and async_result["generated_count"] == 6)
	var sync_result: Dictionary = CreatureBatchGenerator.generate_encounter(authoring, root, 6, 2500)
	for i in 6:
		assert(sync_result["items"][i]["image"].get_data() == async_result["items"][i]["image"].get_data())

	assert(batch[0]["requested_seed"] == 2500)
	assert(batch[1]["requested_seed"] == 10419)
	assert(batch[0]["image"] is Image)
	assert(generator.get_image().get_data() == preserved)
	var batch_repeat: Array[Dictionary] = CreatureBatchGenerator.generate(authoring, root, 3, 2500)
	for i in batch.size():
		assert(batch[i]["image"].get_data() == batch_repeat[i]["image"].get_data())
		assert(batch[i]["selected_seed"] == batch_repeat[i]["selected_seed"])
	assert(CreatureBatchGenerator.generate(authoring, root, 0, 2500).is_empty())
	assert(CreatureBatchGenerator.generate(null, root, 3, 2500).is_empty())
	assert(CreatureBatchGenerator.export_pngs(batch, "user://creature-batch-test", "batch") == OK)
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://creature-batch-test/batch_manifest.json"))
	assert(manifest is Dictionary and manifest["count"] == 3)
	assert(Image.load_from_file("user://creature-batch-test/batch_01_2500.png").get_size() == batch[0]["image"].get_size())
	generator.clear()
	assert(is_instance_valid(authored))
	assert(generator.get_image() == null)
	generator.free()
	print("PASS: generator regression")
	quit()
