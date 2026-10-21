extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var baseline := CreatureSpeciesGenerator.generate(101, Vector2i(48, 48))
	assert(baseline["image"] is Image)
	assert(baseline["image"].get_size() == Vector2i(50, 50))
	assert(baseline["image"].get_data() == CreatureSpeciesGenerator.generate(101)["image"].get_data())
	var encountered: Dictionary = {}
	for form in CreatureSpeciesGenerator.Form.size():
		var first := CreatureSpeciesGenerator.generate(1001 + form, Vector2i(48, 48), form, CreatureSpeciesGenerator.Element.PLANT)
		var second := CreatureSpeciesGenerator.generate(1001 + form, Vector2i(48, 48), form, CreatureSpeciesGenerator.Element.PLANT)
		var image: Image = first["image"]
		assert(first["form"] == form, "Requested form was not preserved")
		assert(image.get_data() == second["image"].get_data(), "Same genome produced different pixels")
		assert(not image.is_invisible(), "Generated creature must contain body pixels")
		assert(image.get_pixel(0, 0).a == 0.0, "Background must remain transparent")
		encountered[hash(image.get_data())] = true
	assert(encountered.size() >= 10, "Forms should yield visibly different silhouettes")
	var genome := CreatureSpeciesGenerator.sample(2034, CreatureSpeciesGenerator.Form.INSECT, CreatureSpeciesGenerator.Element.WATER)
	assert(CreatureSpeciesGenerator.render(genome)["image"].get_data() == CreatureSpeciesGenerator.render(genome)["image"].get_data())
	seed(9876)
	var expected := randi()
	seed(9876)
	CreatureSpeciesGenerator.generate(99)
	assert(randi() == expected, "Species generation must not touch global RNG")
	var tiny := CreatureSpeciesGenerator.generate(13, Vector2i(3, 2))
	assert(tiny["image"].get_size() == Vector2i(26, 26), "Sizes must be clamped")
	print("PASS: procedural species")
	quit()
