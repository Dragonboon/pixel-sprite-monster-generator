class_name CreatureTopdownSheets
extends RefCounted

## Rows are eight unique directions; columns are deterministic frames.
## All sheets are original procedural output and share a stable cell/pivot.
const ROW_LABELS := ["Sur", "Suroeste", "Oeste", "Noroeste", "Norte", "Noreste", "Este", "Sureste"]
const ROW_ARROWS := ["↓", "↙", "←", "↖", "↑", "↗", "→", "↘"]


static func row_legend() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for i in CreatureTopdownGenerator.DIRECTIONS.size():
		rows.append({"row": i, "direction": CreatureTopdownGenerator.DIRECTIONS[i],
			"label": ROW_LABELS[i], "arrow": ROW_ARROWS[i]})
	return rows


static func build(genome: Dictionary, action: int, cell_size: int = 64, frame_count: int = 4) -> Dictionary:
	var dimension: int = clampi(cell_size, 32, 128)
	var count: int = clampi(frame_count, 1, 12)
	var sheet := Image.create(dimension * count, dimension * CreatureTopdownGenerator.Direction.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for direction in CreatureTopdownGenerator.Direction.size():
		for frame in count:
			var sprite: Image = CreatureTopdownGenerator.render(genome, direction, action, frame, dimension)
			sheet.blit_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), Vector2i(frame * dimension, direction * dimension))
	return {"image": sheet, "cell_size": dimension, "frames": count, "directions": CreatureTopdownGenerator.DIRECTIONS.duplicate(),
		"action": CreatureTopdownGenerator.ACTIONS[action], "row_legend": row_legend(),
		"pivot": [dimension / 2, roundi(float(dimension) * 0.75)]}


static func export_pack(genome: Dictionary, folder: String, size: int = 64) -> Error:
	if not folder.begins_with("user://") and not folder.begins_with("res://"):
		return ERR_INVALID_PARAMETER
	var err: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	if err != OK:
		return err
	var actions: Dictionary = {}
	for action in CreatureTopdownGenerator.Action.size():
		var data: Dictionary = build(genome, action, size)
		var filename: String = CreatureTopdownGenerator.ACTION_FILES[action] + ".png"
		err = data["image"].save_png(folder.path_join(filename))
		if err != OK:
			return err
		actions[data["action"]] = {"file": filename, "frames": data["frames"], "rows": 8,
			"cell_size": data["cell_size"], "pivot": data["pivot"]}
	var manifest: Dictionary = {"schema_version": 1, "species": genome, "direction_order": CreatureTopdownGenerator.DIRECTIONS.duplicate(),
		"direction_rows": row_legend(), "action_variants": CreatureTopdownGenerator.ACTION_VARIANTS.duplicate(true),
		"actions": actions, "fps": 8, "filter": "nearest", "origin": "procedural"}
	var file := FileAccess.open(folder.path_join("species.json"), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	return OK
