class_name CreatureBatchGenerator
extends RefCounted

## Small bounded CPU batch for authoring assets. Does not modify the caller's
## existing PixelSpriteMonsterGenerator or the global random stream.
const MAX_ITEMS: int = 16
const DEFAULT_SEED_STEP: int = 7919


static func generate(preset: CreatureGenerationPreset, parent: Node, count: int, first_seed: int, seed_step: int = DEFAULT_SEED_STEP) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if preset == null or parent == null or not parent.is_inside_tree() or count <= 0:
		return items
	var worker := PixelSpriteMonsterGenerator.new()
	preset.apply_to(worker)
	worker.randomize_seed = false
	worker.manual_seed = first_seed
	worker.visible = false
	parent.add_child(worker)
	for index in mini(count, MAX_ITEMS):
		var requested_seed: int = first_seed + index * seed_step
		if index > 0:
			worker.manual_seed = requested_seed
			worker.draw_sprite()
		var generated: Image = worker.get_image()
		if generated == null:
			continue
		items.append({
			"index": index,
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


## PNG files + machine-readable seed manifest. Only user:// or res:// destinations
## are supported. res:// usually is not writable from an exported game.
## An existing output filename will be overwritten by Image.save_png().
static func export_pngs(items: Array[Dictionary], directory: String, prefix: String = "creature") -> Error:
	if items.is_empty() or (not directory.begins_with("user://") and not directory.begins_with("res://")):
		return ERR_INVALID_PARAMETER
	if prefix.is_empty() or prefix.contains("/") or prefix.contains("\\") or prefix.contains(".."):
		return ERR_INVALID_PARAMETER
	if items.size() > MAX_ITEMS:
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
			"anatomy": item["anatomy"],
			"anatomy_metrics": item["anatomy_metrics"]
		})
	var manifest: Dictionary = {
		"schema_version": 1,
		"count": records.size(),
		"seed_step": DEFAULT_SEED_STEP,
		"items": records
	}
	var output := FileAccess.open(directory.path_join(prefix + "_manifest.json"), FileAccess.WRITE)
	if output == null:
		return FileAccess.get_open_error()
	output.store_string(JSON.stringify(manifest, "\t"))
	output.close()
	return OK
