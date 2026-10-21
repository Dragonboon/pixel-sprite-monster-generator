@tool
extends EditorScript

## In Godot: open this file and choose File > Run (Ctrl+Shift+X).
## Reuses the very executable currently running the editor; no Python/path setup.
const TESTS := [
	"res://tests/load_scripts.gd",
	"res://tests/regression.gd",
	"res://tests/species_regression.gd",
	"res://tests/species_lab_smoke.gd"
]

func _run() -> void:
	var executable: String = OS.get_executable_path()
	var project_dir: String = ProjectSettings.globalize_path("res://")
	var failed: bool = false
	for path in TESTS:
		var output: Array = []
		var args := PackedStringArray(["--headless", "--path", project_dir,
			"--audio-driver", "Dummy", "--script", path])
		var exit_code: int = OS.execute(executable, args, output, true)
		var logs: String = "\n".join(output)
		if exit_code != 0 or not logs.contains("PASS:") or logs.contains("SCRIPT ERROR") or logs.contains("Assertion failed") or logs.contains("ERROR:"):
			push_error("FAIL %s (exit %d)\n%s" % [path, exit_code, logs])
			failed = true
		else:
			print("PASS ", path)
	if failed:
		push_error("Godot project tests FAILED - see Output")
	else:
		print("PASS: all Godot project tests")
