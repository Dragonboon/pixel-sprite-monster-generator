extends SceneTree

func _initialize() -> void:
	check_directory("res://addons")
	if DirAccess.dir_exists_absolute("res://demo"):
		check_directory("res://demo")
	print("PASS: script loading")
	quit()

func check_directory(path: String) -> void:
	for filename in DirAccess.get_files_at(path):
		if filename.ends_with(".gd"):
			var script := load(path.path_join(filename)) as GDScript
			assert(script != null and script.can_instantiate(), filename)
	for directory in DirAccess.get_directories_at(path):
		check_directory(path.path_join(directory))
