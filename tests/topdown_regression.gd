extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var genome: Dictionary = CreatureTopdownGenerator.species(253, CreatureTopdownGenerator.Family.REPTILE, 3)
	var image: Image = CreatureTopdownGenerator.render(genome, CreatureTopdownGenerator.Direction.NE, CreatureTopdownGenerator.Action.WALK, 2)
	assert(image.get_size() == Vector2i(64, 64))
	assert(image.get_data() == CreatureTopdownGenerator.render(genome, CreatureTopdownGenerator.Direction.NE, CreatureTopdownGenerator.Action.WALK, 2).get_data())
	assert(image.get_pixel(0, 0).a == 0.0)
	var distinct: Dictionary = {}
	for direction in CreatureTopdownGenerator.Direction.size():
		var frame: Image = CreatureTopdownGenerator.render(genome, direction)
		assert(not frame.is_invisible())
		distinct[hash(frame.get_data())] = true
	assert(distinct.size() >= 5, "Direction rendering must produce distinct views")
	# Compatibilidad: las siete acciones originales mantienen su índice y exportación.
	assert(CreatureTopdownGenerator.Action.IDLE == 0)
	assert(CreatureTopdownGenerator.Action.FAINT == 6)
	assert(CreatureTopdownGenerator.Action.IDLE_B == 7)
	assert(CreatureTopdownGenerator.Action.WALK_B == 8)
	assert(CreatureTopdownGenerator.Action.DASH == 9)
	assert(CreatureTopdownGenerator.ACTION_FILES.size() == CreatureTopdownGenerator.Action.size())
	assert(CreatureTopdownSheets.ROW_LABELS.size() == 8)
	var rows: Array[Dictionary] = CreatureTopdownSheets.row_legend()
	for direction in 8:
		assert(rows[direction]["row"] == direction)
		assert(rows[direction]["direction"] == CreatureTopdownGenerator.DIRECTIONS[direction])
		assert(rows[direction]["label"] == CreatureTopdownSheets.ROW_LABELS[direction])

	# Las semillas son repetibles y afectan a la estructura, no solo a la paleta.
	for family in CreatureTopdownGenerator.Family.size():
		for seed_value in [19, 37, 101, 2027]:
			var dna: Dictionary = CreatureTopdownGenerator.species(seed_value, family, 3)
			assert(dna == CreatureTopdownGenerator.species(seed_value, family, 3))
			for action in CreatureTopdownGenerator.Action.size():
				var first: Image = CreatureTopdownGenerator.render(dna, CreatureTopdownGenerator.Direction.S, action, 2)
				assert(first.get_size() == Vector2i(64, 64))
				assert(not first.is_invisible())
				assert(first.get_data() == CreatureTopdownGenerator.render(dna,
					CreatureTopdownGenerator.Direction.S, action, 2).get_data())
	var shapes: Dictionary = {}
	for seed_value in 18:
		var candidate: Dictionary = CreatureTopdownGenerator.species(100 + seed_value, CreatureTopdownGenerator.Family.PLANT, 3)
		shapes[str(candidate["body_shape"]) + ":" + str(candidate["stance_style"]) + ":" +
			str(candidate["plant_motif"]) + ":" + str(candidate["head_position"])] = true
	assert(shapes.size() >= 9, "Las semillas deben producir distintas anatomías")
	var idle_a: Image = CreatureTopdownGenerator.render(genome, 0, CreatureTopdownGenerator.Action.IDLE, 2)
	var idle_b: Image = CreatureTopdownGenerator.render(genome, 0, CreatureTopdownGenerator.Action.IDLE_B, 2)
	var walk_a: Image = CreatureTopdownGenerator.render(genome, 0, CreatureTopdownGenerator.Action.WALK, 2)
	var walk_b: Image = CreatureTopdownGenerator.render(genome, 0, CreatureTopdownGenerator.Action.WALK_B, 2)
	assert(idle_a.get_data() != idle_b.get_data())
	assert(walk_a.get_data() != walk_b.get_data())
	var faint_start: Image = CreatureTopdownGenerator.render(genome, 0, CreatureTopdownGenerator.Action.FAINT, 0)
	var faint_end: Image = CreatureTopdownGenerator.render(genome, 0, CreatureTopdownGenerator.Action.FAINT, 3)
	assert(faint_start.get_data() != faint_end.get_data())
	var dash: Image = CreatureTopdownGenerator.render(genome, 0, CreatureTopdownGenerator.Action.DASH, 2)
	assert(not dash.is_invisible())
	var sheet: Dictionary = CreatureTopdownSheets.build(genome, CreatureTopdownGenerator.Action.WALK)
	assert(sheet["image"].get_size() == Vector2i(256, 512))
	assert(sheet["directions"].size() == 8)
	assert(sheet["row_legend"].size() == 8)
	assert(CreatureTopdownSheets.export_pack(genome, "user://topdown_regression") == OK)
	var manifest_file := FileAccess.open("user://topdown_regression/species.json", FileAccess.READ)
	assert(manifest_file != null)
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()
	assert(manifest["direction_order"] == CreatureTopdownGenerator.DIRECTIONS)
	assert(manifest["direction_rows"].size() == 8)
	assert(manifest["actions"].size() == CreatureTopdownGenerator.Action.size())
	assert(manifest["actions"].has("Dash"))
	assert(manifest["actions"].has("IdleB"))
	assert(manifest["actions"].has("WalkB"))
	assert(FileAccess.file_exists("user://topdown_regression/dash.png"))
	assert(FileAccess.file_exists("user://topdown_regression/idle_b.png"))
	assert(FileAccess.file_exists("user://topdown_regression/walk_b.png"))
	var lab_scene: PackedScene = load("res://demo/topdown_lab.tscn")
	assert(lab_scene != null and lab_scene.can_instantiate())
	print("PASS: topdown species")
	quit()
