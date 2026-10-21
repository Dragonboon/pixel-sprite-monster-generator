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

	# V2 modules must replay, mutate deterministically and preserve explicit locks.
	var options: Dictionary = {"form": CreatureSpeciesGenerator.Form.BIPED,
		"head": 1, "tail": 2, "back": 1, "moods": {"epic": 1.0, "creepy": 0.5}}
	var dna: Dictionary = CreatureSpeciesDNA.sample(500, options)
	assert(int(dna["head"]) == 1 and int(dna["tail"]) == 2 and int(dna["back"]) == 1)
	var modular: Dictionary = CreatureSpeciesGenerator.render(dna)
	assert(modular["image"].get_data() == CreatureSpeciesGenerator.render(dna)["image"].get_data())
	var locked: Dictionary = {"form": true, "head": true, "tail": true}
	var mutation: Dictionary = CreatureSpeciesDNA.mutate(dna, 900, 1.0, locked)
	assert(mutation["form"] == dna["form"] and mutation["head"] == dna["head"] and mutation["tail"] == dna["tail"])
	assert(mutation == CreatureSpeciesDNA.mutate(dna, 900, 1.0, locked))
	var another: Dictionary = CreatureSpeciesDNA.sample(501, options)
	assert(another != dna, "Different seeds must sample different genomes")
	var changed: Dictionary = dna.duplicate(true)
	changed["head"] = 5
	assert(CreatureSpeciesGenerator.render(changed)["image"].get_data() != modular["image"].get_data(),
		"Changing head module must alter rendered pixels")
	assert(CreatureSpeciesDNA.sample(500, options) == dna)
	print("PASS: procedural species")
	quit()
