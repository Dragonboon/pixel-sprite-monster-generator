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
