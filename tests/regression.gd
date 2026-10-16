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
	generator.clear()
	assert(is_instance_valid(authored))
	assert(generator.get_image() == null)
	generator.free()
	print("PASS: generator regression")
	quit()
