class_name CreatureBatchGenerator
extends RefCounted

## Small bounded CPU batch for authoring assets. Does not modify the caller's
## existing PixelSpriteMonsterGenerator or the global random stream.
const MAX_ITEMS: int = 16
const MAX_ENCOUNTER_ITEMS: int = 128
const DEFAULT_SEED_STEP: int = 7919


static func generate(preset: CreatureGenerationPreset, parent: Node, count: int, first_seed: int, seed_step: int = DEFAULT_SEED_STEP) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if preset == null or parent == null or not parent.is_inside_tree() or count <= 0 or count > MAX_ITEMS:
		return items
	var worker := PixelSpriteMonsterGenerator.new()
	preset.apply_to(worker)
	worker.randomize_seed = false
	worker.manual_seed = first_seed
	worker.visible = false
	parent.add_child(worker)
	for index in count:
		var started_us: int = Time.get_ticks_usec()
		var requested_seed: int = first_seed + index * seed_step
		if index > 0:
			worker.manual_seed = requested_seed
			worker.draw_sprite()
		var generated: Image = worker.get_image()
		if generated == null:
			continue
		items.append({
			"index": index,
			"seed_step": seed_step,
			"elapsed_ms": float(Time.get_ticks_usec() - started_us) / 1000.0,
			"requested_seed": requested_seed,
			"selected_seed": worker.last_seed,
			"quality_score": worker.last_quality_score,
			"quality_accepted": worker.quality_accepted,
			"quality_attempts": worker.last_quality_attempts,
			"anatomy": worker.last_anatomy.duplicate(true),
			"anatomy_metrics": worker.last_anatomy_metrics.duplicate(true),
			"image": generated
		})
	parent.remove_child(worker)
	worker.free()
	return items



## RPG encounter generation. Exactly 1..128 results or a non-OK error.
## Large requests are processed in chunks, with explicit validation instead
## of the legacy 16-item function's old silent truncation.
static func generate_encounter(preset: CreatureGenerationPreset, parent: Node, count: int, first_seed: int, seed_step: int = DEFAULT_SEED_STEP) -> Dictionary:
	var start_us: int = Time.get_ticks_usec()
	var valid: Error = _validate_encounter(preset, parent, count)
	if valid != OK:
		return _encounter_result(valid, [], count, start_us)
	var items: Array[Dictionary] = []
	for offset in range(0, count, MAX_ITEMS):
		var amount: int = mini(MAX_ITEMS, count - offset)
		var part: Array[Dictionary] = generate(preset, parent, amount, first_seed + offset * seed_step, seed_step)
		if part.size() != amount:
			return _encounter_result(ERR_CANT_CREATE, [], count, start_us)
		for local in part:
			local["index"] = offset + int(local["index"])
			items.append(local)
	return _encounter_result(OK, items, count, start_us)


## Preferred at runtime: yields a frame between chunks, keeping a multi-wave
## encounter from blocking the game for all creatures at once.
static func generate_encounter_async(preset: CreatureGenerationPreset, parent: Node, count: int, first_seed: int, seed_step: int = DEFAULT_SEED_STEP, chunk_size: int = 4) -> Dictionary:
	var start_us: int = Time.get_ticks_usec()
	var valid: Error = _validate_encounter(preset, parent, count)
	if valid != OK or chunk_size < 1 or chunk_size > MAX_ITEMS:
		return _encounter_result(valid if valid != OK else ERR_INVALID_PARAMETER, [], count, start_us)
	var items: Array[Dictionary] = []
	for offset in range(0, count, chunk_size):
		var amount: int = mini(chunk_size, count - offset)
		var part: Array[Dictionary] = generate(preset, parent, amount, first_seed + offset * seed_step, seed_step)
		if part.size() != amount:
			return _encounter_result(ERR_CANT_CREATE, [], count, start_us)
		for local in part:
			local["index"] = offset + int(local["index"])
			items.append(local)
		if offset + amount < count:
			await parent.get_tree().process_frame
	return _encounter_result(OK, items, count, start_us)


static func _validate_encounter(preset: CreatureGenerationPreset, parent: Node, count: int) -> Error:
	if preset == null or parent == null or not parent.is_inside_tree():
		return ERR_INVALID_PARAMETER
	if count < 1 or count > MAX_ENCOUNTER_ITEMS:
		return ERR_INVALID_PARAMETER
	return OK


static func _encounter_result(error: Error, items: Array[Dictionary], requested: int, start_us: int) -> Dictionary:
	return {
		"error": error,
		"items": items,
		"requested_count": requested,
		"generated_count": items.size(),
		"elapsed_ms": float(Time.get_ticks_usec() - start_us) / 1000.0
	}


## PNG files + machine-readable seed manifest. Only user:// or res:// destinations
## are supported. res:// usually is not writable from an exported game.
## An existing output filename will be overwritten by Image.save_png().
static func export_pngs(items: Array[Dictionary], directory: String, prefix: String = "creature") -> Error:
	if items.is_empty() or (not directory.begins_with("user://") and not directory.begins_with("res://")):
		return ERR_INVALID_PARAMETER
	if prefix.is_empty() or prefix.contains("/") or prefix.contains("\\") or prefix.contains(".."):
		return ERR_INVALID_PARAMETER
	if items.size() > MAX_ENCOUNTER_ITEMS:
		return ERR_INVALID_PARAMETER
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if dir_error != OK:
		return dir_error
	var records: Array[Dictionary] = []
	for index in items.size():
		var item: Dictionary = items[index]
		var image: Image = item.get("image")
		if image == null or image.is_empty():
			return ERR_INVALID_DATA
		var image_name: String = "%s_%02d_%d.png" % [prefix, index + 1, int(item["requested_seed"])]
		var image_error: Error = image.save_png(directory.path_join(image_name))
		if image_error != OK:
			return image_error
		records.append({
			"file": image_name,
			"requested_seed": item["requested_seed"],
			"selected_seed": item["selected_seed"],
			"quality_score": item["quality_score"],
			"quality_accepted": item["quality_accepted"],
			"quality_attempts": item["quality_attempts"],
			"elapsed_ms": item.get("elapsed_ms", 0.0),
			"anatomy": item["anatomy"],
			"anatomy_metrics": item["anatomy_metrics"]
		})
	var manifest: Dictionary = {
		"schema_version": 1,
		"count": records.size(),
		"seed_step": int(items[0].get("seed_step", DEFAULT_SEED_STEP)),
		"items": records
	}
	var output := FileAccess.open(directory.path_join(prefix + "_manifest.json"), FileAccess.WRITE)
	if output == null:
		return FileAccess.get_open_error()
	output.store_string(JSON.stringify(manifest, "\t"))
	output.close()
	return OK
