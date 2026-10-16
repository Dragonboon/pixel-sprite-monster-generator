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
	generator.clear()
	assert(is_instance_valid(authored))
	assert(generator.get_image() == null)
	generator.free()
	print("PASS: generator regression")
	quit()
