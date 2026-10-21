extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var lab_scene: PackedScene = load("res://demo/species_lab.tscn")
	assert(lab_scene != null, "Species Lab scene must load")
	var lab := lab_scene.instantiate() as Control
	assert(lab != null, "Species Lab root must be Control")
	root.add_child(lab)
	await process_frame
	assert(lab.gallery_flow != null, "Gallery container missing")
	assert(lab.generated_items.size() > 0, "Lab should generate initial preview")
	assert(lab.selected_index == 0, "First result should be selected")
	assert(lab.preview.texture != null, "Inspector preview missing")
	var before: PackedByteArray = lab.generated_items[0]["image"].get_data()
	lab._start_batch(true)
	await process_frame
	assert(lab.generated_items.size() == CreatureSpeciesGenerator.Form.size(), "Comparison must include all 14 forms")
	for i in lab.generated_items.size():
		assert(int(lab.generated_items[i]["form"]) == i, "Form order mismatch")
		assert(int(lab.generated_items[i]["seed"]) == int(lab.seed_input.value), "Comparison seeds must match")
	lab._select(0)
	lab._pin_selection()
	assert(lab.pinned_preview.texture != null, "Pinned comparison missing")
	lab._start_batch(false)
	await process_frame
	assert(lab.pinned_preview.texture != null, "Pinned preview should survive reroll")
	assert(lab.generated_items[0]["image"].get_data() == before, "Same filter/seed must reproduce the same pixels")
	var scene: PackedScene = load("res://demo/test.tscn")
	assert(scene != null and scene.can_instantiate(), "Legacy scene remains available")
	print("PASS: species lab smoke")
	lab.queue_free()
	quit()
