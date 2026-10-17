class_name CreatureBatchGenerator
extends RefCounted

## Small bounded CPU batch for authoring assets. Does not modify the caller's
## existing PixelSpriteMonsterGenerator or the global random stream.
const MAX_ITEMS: int = 16
const MAX_ENCOUNTER_ITEMS: int = 128
const DEFAULT_SEED_STEP: int = 7919


static func generate(preset: CreatureGenerationPreset, parent: Node, count: int, first_seed: int, seed_step: int = DEFAULT_SEED_STEP) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if _validate_encounter(preset, parent, count) != OK or count > MAX_ITEMS:
		return items
	var worker: PixelSpriteMonsterGenerator = _create_worker(preset, parent)
	_append_range(items, worker, 0, count, first_seed, seed_step)
	_release_worker(worker)
	return items


## Exactly 1..128 results or an explicit error; never truncate the count.
## One temporary generator is reused for the entire encounter.
static func generate_encounter(preset: CreatureGenerationPreset, parent: Node, count: int, first_seed: int, seed_step: int = DEFAULT_SEED_STEP) -> Dictionary:
	var started: int = Time.get_ticks_usec()
	var valid: Error = _validate_encounter(preset, parent, count)
	if valid != OK:
		return _encounter_result(valid, [], count, started)
	var items: Array[Dictionary] = []
	var worker: PixelSpriteMonsterGenerator = _create_worker(preset, parent)
	_append_range(items, worker, 0, count, first_seed, seed_step)
	_release_worker(worker)
	return _encounter_result(OK if items.size() == count else ERR_CANT_CREATE, items if items.size() == count else [], count, started)


## Yields between chunks, without allocating a new generator per chunk.
## The calculation within each chunk is still synchronous.
static func generate_encounter_async(preset: CreatureGenerationPreset, parent: Node, count: int, first_seed: int, seed_step: int = DEFAULT_SEED_STEP, chunk_size: int = 4) -> Dictionary:
	var started: int = Time.get_ticks_usec()
	var valid: Error = _validate_encounter(preset, parent, count)
	if valid != OK or chunk_size < 1 or chunk_size > MAX_ITEMS:
		return _encounter_result(valid if valid != OK else ERR_INVALID_PARAMETER, [], count, started)
	var items: Array[Dictionary] = []
	var worker: PixelSpriteMonsterGenerator = _create_worker(preset, parent)
	for offset in range(0, count, chunk_size):
		var amount: int = mini(chunk_size, count - offset)
		_append_range(items, worker, offset, amount, first_seed, seed_step)
		if offset + amount < count:
			await parent.get_tree().process_frame
			if not is_instance_valid(worker) or not is_instance_valid(parent) or not parent.is_inside_tree():
				if is_instance_valid(worker):
					_release_worker(worker)
				return _encounter_result(ERR_UNAVAILABLE, [], count, started)
	_release_worker(worker)
	return _encounter_result(OK if items.size() == count else ERR_CANT_CREATE, items if items.size() == count else [], count, started)


static func _create_worker(preset: CreatureGenerationPreset, parent: Node) -> PixelSpriteMonsterGenerator:
	var worker := PixelSpriteMonsterGenerator.new()
	worker.defer_initial_generation = true
	preset.apply_to(worker)
	worker.randomize_seed = false
	worker.visible = false
	parent.add_child(worker)
	return worker


static func _append_range(items: Array[Dictionary], worker: PixelSpriteMonsterGenerator, offset: int, count: int, first_seed: int, seed_step: int) -> void:
	for local_index in count:
		var index: int = offset + local_index
		var requested: int = first_seed + index * seed_step
		var started: int = Time.get_ticks_usec()
		worker.manual_seed = requested
		worker.draw_sprite()
		var source_image: Image = worker.get_unfinished_image()
		if source_image == null or source_image.is_empty():
			return
		var image: Image = worker.finish_image(source_image)
		if image == null or image.is_empty():
			return
		items.append({
			"index": index,
			"seed_step": seed_step,
			"elapsed_ms": float(Time.get_ticks_usec() - started) / 1000.0,
			"requested_seed": requested,
			"selected_seed": worker.last_seed,
			"quality_score": worker.last_quality_score,
			"quality_accepted": worker.quality_accepted,
			"quality_attempts": worker.last_quality_attempts,
			"anatomy": worker.last_anatomy.duplicate(true),
			"anatomy_metrics": worker.last_anatomy_metrics.duplicate(true),
			"traits": worker.last_traits.duplicate(true),
			"structure": worker.last_structure.duplicate(true),
			"image": image,
			"source_image": source_image,
			"archetype": worker.creature_archetype,
			"palette": worker.last_palette,
			"palette_roles": worker.last_palette_roles.duplicate(true),
			"harmony": worker.last_harmony,
			"color_count_mode": worker.color_count_mode
		})


static func _release_worker(worker: PixelSpriteMonsterGenerator) -> void:
	if is_instance_valid(worker):
		if worker.get_parent() != null:
			worker.get_parent().remove_child(worker)
		worker.free()


static func _validate_encounter(preset: CreatureGenerationPreset, parent: Node, count: int) -> Error:
	if preset == null or parent == null or not parent.is_inside_tree():
		return ERR_INVALID_PARAMETER
	if count < 1 or count > MAX_ENCOUNTER_ITEMS:
		return ERR_INVALID_PARAMETER
	return OK


static func _encounter_result(error: Error, items: Array[Dictionary], requested: int, started: int) -> Dictionary:
	return {
		"error": error,
		"items": items,
		"requested_count": requested,
		"generated_count": items.size(),
		"elapsed_ms": float(Time.get_ticks_usec() - started) / 1000.0
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
		var palette_hex: Array[String] = []
		var source_palette: PackedColorArray = item.get("palette", PackedColorArray())
		for palette_color in source_palette:
			palette_hex.append(palette_color.to_html(false))
		records.append({
			"file": image_name,
			"requested_seed": item["requested_seed"],
			"selected_seed": item["selected_seed"],
			"quality_score": item["quality_score"],
			"quality_accepted": item["quality_accepted"],
			"quality_attempts": item["quality_attempts"],
			"elapsed_ms": item.get("elapsed_ms", 0.0),
			"anatomy": item["anatomy"],
			"anatomy_metrics": item["anatomy_metrics"],
			"traits": item.get("traits", {}),
			"structure": item.get("structure", {}),
			"palette": palette_hex,
			"palette_roles": item.get("palette_roles", {}),
			"harmony": item.get("harmony", 0),
			"color_count_mode": item.get("color_count_mode", 0)
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
