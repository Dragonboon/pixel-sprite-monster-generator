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
	var sheet: Dictionary = CreatureTopdownSheets.build(genome, CreatureTopdownGenerator.Action.WALK)
	assert(sheet["image"].get_size() == Vector2i(256, 512))
	assert(sheet["directions"].size() == 8)
	assert(CreatureTopdownSheets.export_pack(genome, "user://topdown_regression") == OK)
	var lab_scene: PackedScene = load("res://demo/topdown_lab.tscn")
	assert(lab_scene != null and lab_scene.can_instantiate())
	print("PASS: topdown species")
	quit()
