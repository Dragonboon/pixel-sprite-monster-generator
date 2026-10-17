extends Control

# Exploration gallery lives outside addons; generator API remains reusable.
const PRESETS: Array[Dictionary] = [
	{"name": "Original", "shape": 0.0, "anatomy": CreatureMorphology.Archetype.ORIGINAL, "symmetry": 100.0, "steps": 4, "colors": 12, "size": Vector2(48, 48)},
	{"name": "Forest biped", "shape": 0.35, "anatomy": CreatureMorphology.Archetype.BIPED, "symmetry": 100.0, "steps": 4, "colors": 9, "size": Vector2(48, 48)},
	{"name": "Insectoid", "shape": 0.2, "anatomy": CreatureMorphology.Archetype.INSECTOID, "symmetry": 100.0, "steps": 3, "colors": 7, "size": Vector2(48, 48)},
	{"name": "Soft slime", "shape": 0.6, "anatomy": CreatureMorphology.Archetype.SLIME, "symmetry": 100.0, "steps": 3, "colors": 8, "size": Vector2(48, 48)},
	{"name": "Winged creature", "shape": 0.4, "anatomy": CreatureMorphology.Archetype.WINGED, "symmetry": 100.0, "steps": 4, "colors": 10, "size": Vector2(48, 48)},
	{"name": "Wild biped", "shape": 0.15, "anatomy": CreatureMorphology.Archetype.BIPED, "symmetry": 83.0, "steps": 5, "colors": 6, "size": Vector2(48, 48)},
	{"name": "Mantid", "shape": 0.2, "anatomy": CreatureMorphology.Archetype.INSECTOID, "symmetry": 93.0, "steps": 4, "colors": 7, "size": Vector2(48, 48)},
	{"name": "Forest beast", "shape": 0.2, "anatomy": CreatureMorphology.Archetype.QUADRUPED, "symmetry": 88.0, "steps": 4, "colors": 8, "size": Vector2(48, 48)},
	{"name": "Stone guardian", "shape": 0.1, "anatomy": CreatureMorphology.Archetype.GOLEM, "symmetry": 100.0, "steps": 5, "colors": 6, "size": Vector2(48, 48)},
	{"name": "Wandering spirit", "shape": 0.45, "anatomy": CreatureMorphology.Archetype.SPIRIT, "symmetry": 80.0, "steps": 3, "colors": 10, "size": Vector2(48, 48)}
]
var generator: PixelSpriteMonsterGenerator
var gallery: GridContainer
var seed_input: SpinBox
var status_label: Label
var rendered_images: Array[Image] = []
var random_source := RandomNumberGenerator.new()
var mood_selector: OptionButton
var style_selector: OptionButton
var quality_slider: HSlider
var shade_slider: HSlider
var detail_slider: HSlider
var details_checkbox: CheckBox
var harmony_enabled: CheckBox
var harmony_select: OptionButton
var color_count_select: OptionButton
var color_count_spinner: SpinBox
var structure_checkbox: CheckBox
var view_selector: OptionButton
var active_style: int = 0
var anatomy_profile: CreatureAnatomyProfile
var anatomy_enabled: CheckBox
var compare_views: CheckBox
var count_input: SpinBox
var family_selector: OptionButton
var preset_selector: OptionButton
var favorites_only: CheckBox
var saved_favorites: Dictionary = {}
var current_items: Array[Dictionary] = []
var current_preset: CreatureGenerationPreset
var export_button: Button
var run_id: int = 0
var progress: ProgressBar
var benchmark_button: Button
var page_selector: SpinBox
const PAGE_SIZE: int = 12
var finish_request: int = 0


func _ready() -> void:
	random_source.randomize()
	generator = PixelSpriteMonsterGenerator.new()
	generator.visible = false
	generator.cell_animation = false
	generator.randomize_seed = false
	anatomy_profile = CreatureAnatomyProfile.new()
	add_child(generator)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)
	var title := Label.new()
	title.text = "Procedural monster laboratory"
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)
	var controls := HBoxContainer.new()
	layout.add_child(controls)
	var seed_label := Label.new()
	seed_label.text = "Base seed"
	controls.add_child(seed_label)
	seed_input = SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 2000000000
	seed_input.rounded = true
	seed_input.value = 42
	controls.add_child(seed_input)
	_add_button(controls, "Generate gallery", _regenerate)
	_add_button(controls, "New seed", _new_seed)
	count_input = SpinBox.new()
	count_input.min_value = 1
	count_input.max_value = CreatureBatchGenerator.MAX_ENCOUNTER_ITEMS
	count_input.step = 1
	count_input.rounded = true
	count_input.value = 6
	count_input.tooltip_text = "Exactly 1–128 creatures"
	controls.add_child(count_input)
	export_button = Button.new()
	export_button.text = "Export selected PNGs + JSON"
	export_button.pressed.connect(_export_gallery)
	controls.add_child(export_button)
	family_selector = OptionButton.new()
	for family in ["Mixed families", "Original", "Biped", "Insectoid", "Slime", "Winged", "Quadruped", "Golem", "Spirit"]:
		family_selector.add_item(family)
	controls.add_child(family_selector)
	preset_selector = OptionButton.new()
	for option in ["Custom controls", "Cozy Slime", "Dungeon Insectoid"]:
		preset_selector.add_item(option)
	controls.add_child(preset_selector)
	favorites_only = CheckBox.new()
	favorites_only.text = "Favorites only"
	controls.add_child(favorites_only)
	var art_controls := HBoxContainer.new()
	layout.add_child(art_controls)
	mood_selector = OptionButton.new()
	for item in ["Normal", "Cozy", "Horror", "Epic"]:
		mood_selector.add_item(item)
	art_controls.add_child(mood_selector)
	style_selector = OptionButton.new()
	for item in ["Classic", "Handheld", "JRPG", "Dungeon", "Cozy", "Arcade"]:
		style_selector.add_item(item)
	art_controls.add_child(style_selector)
	view_selector = OptionButton.new()
	for item in ["Front", "3/4 left", "3/4 right", "Profile left", "Profile right", "Back (mirror)", "Isometric 2D"]:
		view_selector.add_item(item)
	art_controls.add_child(view_selector)
	anatomy_enabled = CheckBox.new()
	anatomy_enabled.text = "Anatomy profile"
	anatomy_enabled.button_pressed = true
	art_controls.add_child(anatomy_enabled)
	compare_views = CheckBox.new()
	compare_views.text = "Compare legacy anatomy"
	compare_views.button_pressed = false
	art_controls.add_child(compare_views)
	var quality_label := Label.new()
	quality_label.text = "Min quality"
	art_controls.add_child(quality_label)
	quality_slider = HSlider.new()
	quality_slider.min_value = 0
	quality_slider.max_value = 95
	quality_slider.value = 70
	quality_slider.custom_minimum_size.x = 105
	art_controls.add_child(quality_slider)
	var shade_label := Label.new()
	shade_label.text = "Shading"
	art_controls.add_child(shade_label)
	shade_slider = HSlider.new()
	shade_slider.min_value = 0
	shade_slider.max_value = 1
	shade_slider.step = 0.05
	shade_slider.value = 0.65
	shade_slider.custom_minimum_size.x = 105
	art_controls.add_child(shade_slider)
	var colors_controls := HBoxContainer.new()
	layout.add_child(colors_controls)
	harmony_enabled = CheckBox.new()
	harmony_enabled.text = "Color theory"
	harmony_enabled.button_pressed = true
	colors_controls.add_child(harmony_enabled)
	harmony_select = OptionButton.new()
	for harmony_name in ["Auto", "Monochromatic", "Analogous", "Complementary", "Split complementary", "Triadic", "Tetradic", "Neutral + accent"]:
		harmony_select.add_item(harmony_name)
	colors_controls.add_child(harmony_select)
	color_count_select = OptionButton.new()
	color_count_select.add_item("Maximum")
	color_count_select.add_item("Exact")
	colors_controls.add_child(color_count_select)
	color_count_spinner = SpinBox.new()
	color_count_spinner.min_value = 1
	color_count_spinner.max_value = 64
	color_count_spinner.value = 8
	color_count_spinner.rounded = true
	colors_controls.add_child(color_count_spinner)
	details_checkbox = CheckBox.new()
	details_checkbox.text = "Internal details"
	details_checkbox.button_pressed = true
	art_controls.add_child(details_checkbox)
	structure_checkbox = CheckBox.new()
	structure_checkbox.text = "Structural variants"
	structure_checkbox.button_pressed = true
	art_controls.add_child(structure_checkbox)
	detail_slider = HSlider.new()
	detail_slider.min_value = 0.0
	detail_slider.max_value = 1.0
	detail_slider.step = 0.1
	detail_slider.value = 0.8
	detail_slider.custom_minimum_size.x = 90
	detail_slider.tooltip_text = "Interior pattern contrast"
	art_controls.add_child(detail_slider)
	mood_selector.item_selected.connect(func(_v: int) -> void: _regenerate())
	style_selector.item_selected.connect(func(_v: int) -> void: _refresh_finish())
	view_selector.item_selected.connect(func(_v: int) -> void: _refresh_finish())
	anatomy_enabled.toggled.connect(func(_v: bool) -> void: _regenerate())
	compare_views.toggled.connect(func(_v: bool) -> void: _render_gallery())
	quality_slider.drag_ended.connect(func(_v: bool) -> void: _regenerate())
	shade_slider.drag_ended.connect(func(_v: bool) -> void: _refresh_finish())
	harmony_enabled.toggled.connect(func(_v: bool) -> void: _refresh_palette())
	harmony_select.item_selected.connect(func(_v: int) -> void: _refresh_palette())
	color_count_select.item_selected.connect(func(_v: int) -> void: _refresh_palette())
	color_count_spinner.value_changed.connect(func(_v: float) -> void: _refresh_palette())
	details_checkbox.toggled.connect(func(_v: bool) -> void: _refresh_finish())
	structure_checkbox.toggled.connect(func(_v: bool) -> void: _regenerate())
	detail_slider.drag_ended.connect(func(_v: bool) -> void: _refresh_finish())
	family_selector.item_selected.connect(func(_v: int) -> void: _regenerate())
	preset_selector.item_selected.connect(func(_v: int) -> void: _regenerate())
	count_input.value_changed.connect(func(_v: float) -> void: _regenerate())
	favorites_only.toggled.connect(func(_v: bool) -> void: _render_gallery())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	gallery = GridContainer.new()
	gallery.columns = 3
	gallery.add_theme_constant_override("h_separation", 12)
	gallery.add_theme_constant_override("v_separation", 12)
	scroll.add_child(gallery)
	progress = ProgressBar.new()
	progress.show_percentage = true
	layout.add_child(progress)
	benchmark_button = Button.new()
	benchmark_button.text = "Benchmark 1 / 8 / 32 / 128"
	benchmark_button.pressed.connect(_benchmark)
	controls.add_child(benchmark_button)
	page_selector = SpinBox.new()
	page_selector.min_value = 1
	page_selector.max_value = 1
	page_selector.step = 1
	page_selector.rounded = true
	page_selector.value = 1
	page_selector.tooltip_text = "Gallery page (12 sprites per page)"
	controls.add_child(page_selector)
	page_selector.value_changed.connect(func(_value: float) -> void: _render_gallery())
	status_label = Label.new()
	layout.add_child(status_label)
	_regenerate()


func _add_button(parent: HBoxContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(callback)
	parent.add_child(button)


func _new_seed() -> void:
	seed_input.value = random_source.randi_range(0, 1000000000)
	_regenerate()


func _regenerate() -> void:
	run_id += 1
	finish_request += 1
	var own_id: int = run_id
	current_items.clear()
	rendered_images.clear()
	progress.value = 0
	var requested: int = int(count_input.value)
	progress.max_value = requested
	var initial_seed: int = int(seed_input.value)
	var started: int = Time.get_ticks_usec()
	_show_status("Generating %d creatures..." % requested, false)
	for index in requested:
		if own_id != run_id:
			return
		var chosen_preset: CreatureGenerationPreset = _build_preset(index)
		var part: Array[Dictionary] = CreatureBatchGenerator.generate(chosen_preset, self, 1, initial_seed + index * CreatureBatchGenerator.DEFAULT_SEED_STEP)
		if part.size() != 1:
			_show_status("Generation failed at #%d" % [index + 1], true)
			return
		var item: Dictionary = part[0]
		item["index"] = index
		current_items.append(item)
		progress.value = index + 1
		if index + 1 == requested or (index + 1) % 1 == 0:
			_show_status("Generating %d/%d..." % [index + 1, requested], false)
			await get_tree().process_frame
	if own_id != run_id:
		return
	page_selector.max_value = maxi(1, ceili(float(current_items.size()) / float(PAGE_SIZE)))
	page_selector.value = 1
	var diversity: Dictionary = CreatureVariety.summarize(current_items)
	for item in current_items:
		rendered_images.append(item["image"])
	_render_gallery()
	var elapsed: float = float(Time.get_ticks_usec() - started) / 1000.0
	_show_status("Generated %d in %.0f ms (%.1f ms/creature) · unique silhouettes %d/%d · near duplicates %d" % [requested, elapsed, elapsed / float(requested), int(diversity["silhouette_unique"]), requested, int(diversity["near_duplicates"])], false)


## Restyle the cached images only: no quality search or temporary generators.
## Yield after each sprite so sliding cannot monopolize a full frame.
func _refresh_finish() -> void:
	finish_request += 1
	var request_id: int = finish_request
	if current_items.is_empty():
		return
	var updated: int = 0
	for item in current_items:
		if request_id != finish_request:
			return
		var source: Image = item.get("source_image")
		if source == null:
			continue
		item["image"] = CreaturePreviewComposer.compose(
			source, int(item.get("archetype", 0)), item.get("traits", {}),
			details_checkbox.button_pressed, detail_slider.value,
			style_selector.selected, view_selector.selected, shade_slider.value,
			0.18, 0.0, int(item["selected_seed"])
		)
		if harmony_enabled.button_pressed:
			var palette: PackedColorArray = item.get("palette", PackedColorArray())
			if palette.is_empty():
				palette = CreatureColorTheory.build(
				int(item["selected_seed"]), int(color_count_spinner.value),
				harmony_select.selected, mood_selector.selected,
				int(item.get("archetype", 0))
			)["colors"]
			item["palette"] = palette
			item["harmony"] = harmony_select.selected
			item["color_count_mode"] = color_count_select.selected
			item["image"] = CreatureColorTheory.quantize(item["image"], palette, color_count_select.selected)
		updated += 1
		if updated % 4 == 0:
			await get_tree().process_frame
	if request_id != finish_request:
		return
	rendered_images.clear()
	for item in current_items:
		rendered_images.append(item["image"])
	_render_gallery()
	_show_status("Updated finish on %d cached sprites (anatomy unchanged)." % updated, false)


## Palette-only changes keep all silhouettes and selected seeds intact.
func _refresh_palette() -> void:
	for item in current_items:
		item["palette"] = PackedColorArray()
	_refresh_finish()


func _benchmark() -> void:
	run_id += 1
	var own_id: int = run_id
	benchmark_button.disabled = true
	var summaries: Array[String] = []
	for amount in [1, 8, 32, 128]:
		if own_id != run_id:
			benchmark_button.disabled = false
			return
		_show_status("Benchmarking %d creatures..." % amount, false)
		var preset: CreatureGenerationPreset = _build_preset(0)
		var result: Dictionary = await CreatureBatchGenerator.generate_encounter_async(preset, self, amount, 4300, CreatureBatchGenerator.DEFAULT_SEED_STEP, 4)
		if result["error"] != OK:
			_show_status("Benchmark failed at %d: %s" % [amount, error_string(int(result["error"]))], true)
			benchmark_button.disabled = false
			return
		var diversity: Dictionary = CreatureVariety.summarize(result["items"])
		var estimated_bytes: int = 0
		for item in result["items"]:
			estimated_bytes += item["image"].get_data().size()
		summaries.append("%d: %.0fms, %.1f MiB, unique %d" % [amount, float(result["elapsed_ms"]), float(estimated_bytes) / 1048576.0, int(diversity["silhouette_unique"])])
	if own_id == run_id:
		_show_status("Benchmark (RGBA bytes only): " + " | ".join(summaries), false)
	benchmark_button.disabled = false


func _build_preset(index: int) -> CreatureGenerationPreset:
	var preset: CreatureGenerationPreset
	if preset_selector.selected == 1:
		preset = load("res://demo/presets/cozy_slime.tres").duplicate(true) as CreatureGenerationPreset
	elif preset_selector.selected == 2:
		preset = load("res://demo/presets/dungeon_insectoid.tres").duplicate(true) as CreatureGenerationPreset
	else:
		preset = CreatureGenerationPreset.new()
		var base: Dictionary = PRESETS[index % PRESETS.size()]
		preset.sprite_size = base["size"]
		preset.symmetry = float(base["symmetry"])
		preset.steps = int(base["steps"])
		preset.number_of_colors = int(base["colors"])
		preset.organic_shape_strength = float(base["shape"])
		preset.creature_archetype = base["anatomy"]
		preset.anatomy_profile = anatomy_profile if anatomy_enabled.button_pressed else null
		preset.silhouette_mood = mood_selector.selected
		preset.visual_style = style_selector.selected
		preset.view_mode = view_selector.selected
		preset.shading_strength = shade_slider.value
		preset.dithering_strength = 0.18
		preset.quality_min_score = quality_slider.value
		preset.quality_max_attempts = 8
		preset.refined_anatomy = true
	preset.structural_variants = structure_checkbox.button_pressed
	preset.color_theory_enabled = harmony_enabled.button_pressed
	preset.color_harmony = harmony_select.selected
	preset.color_count_mode = color_count_select.selected
	preset.target_color_count = int(color_count_spinner.value)
	preset.internal_details_enabled = details_checkbox.button_pressed
	preset.internal_detail_strength = detail_slider.value
	if family_selector.selected > 0:
		preset.creature_archetype = family_selector.selected - 1
	return preset


func _render_gallery() -> void:
	for child in gallery.get_children():
		gallery.remove_child(child)
		child.queue_free()
	var page_start: int = (int(page_selector.value) - 1) * PAGE_SIZE
	var page_end: int = page_start + PAGE_SIZE
	for item in current_items:
		var index: int = int(item["index"])
		if index < page_start or index >= page_end:
			continue
		var key: String = _favorite_key(item)
		if favorites_only.button_pressed and not saved_favorites.has(key):
			continue
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(265, 225)
		var contents := VBoxContainer.new()
		card.add_child(contents)
		var heading := HBoxContainer.new()
		contents.add_child(heading)
		var title := Label.new()
		title.text = "#%d · seed %d · Q %.0f" % [index + 1, int(item["selected_seed"]), float(item["quality_score"])]
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(title)
		var favorite := CheckButton.new()
		favorite.text = "★"
		favorite.button_pressed = saved_favorites.has(key)
		favorite.toggled.connect(func(enabled: bool) -> void:
			if enabled:
				saved_favorites[key] = true
			else:
				saved_favorites.erase(key)
			if favorites_only.button_pressed:
				_render_gallery()
		)
		heading.add_child(favorite)
		var preview := TextureRect.new()
		preview.texture = ImageTexture.create_from_image(item["image"])
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.custom_minimum_size = Vector2(250, 160)
		contents.add_child(preview)
		if compare_views.button_pressed and index < page_end:
			var old_preset: CreatureGenerationPreset = _build_preset(index)
			if CreatureAnatomyRefiner.supports(old_preset.creature_archetype):
				old_preset.refined_anatomy = false
				old_preset.structural_variants = false
				old_preset.internal_details_enabled = false
				old_preset.quality_enabled = false
				var old_items: Array[Dictionary] = CreatureBatchGenerator.generate(old_preset, self, 1, int(item["selected_seed"]))
				if not old_items.is_empty():
					var legacy: TextureRect = TextureRect.new()
					legacy.texture = ImageTexture.create_from_image(old_items[0]["image"])
					legacy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					legacy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					legacy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					legacy.custom_minimum_size = Vector2(160, 105)
					contents.add_child(legacy)
					var caption := Label.new()
					caption.text = "Above: refined  /  Below: legacy (same seed)"
					contents.add_child(caption)
		var metric := Label.new()
		var structure: Dictionary = item.get("structure", {})
		if not structure.is_empty():
			title.text += " · " + str(structure.get("name", ""))
		var traits: Dictionary = item.get("traits", {})
		metric.text = "Anatomy %.0f · %s · %.1f ms%s" % [float(item["anatomy_metrics"].get("score", 0.0)), ("Pattern %d / Accent %d" % [int(traits.get("pattern", 0)) + 1, int(traits.get("accent", 0)) + 1]) if not traits.is_empty() else "No details", float(item.get("elapsed_ms", 0.0)), "" if bool(item["quality_accepted"]) else " · best effort"]
		contents.add_child(metric)
		var chosen_palette: PackedColorArray = item.get("palette", PackedColorArray())
		if not chosen_palette.is_empty():
			var swatches := HBoxContainer.new()
			for selected_color in chosen_palette:
				var chip := ColorRect.new()
				chip.color = selected_color
				chip.custom_minimum_size = Vector2(10, 10)
				swatches.add_child(chip)
			contents.add_child(swatches)
		gallery.add_child(card)


func _favorite_key(item: Dictionary) -> String:
	return "%d_%d_%d" % [int(seed_input.value), int(item["index"]), int(item["selected_seed"])]


func _show_status(message: String, failure: bool) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.6, 0.6) if failure else Color(0.68, 0.95, 0.75)


func _export_gallery() -> void:
	var selected: Array[Dictionary] = []
	for item in current_items:
		if not favorites_only.button_pressed or saved_favorites.has(_favorite_key(item)):
			selected.append(item)
	if selected.is_empty():
		_show_status("Nothing to export. Uncheck Favorites only or mark a creature with ★.", true)
		return
	var folder: String = "user://creature_galleries/seed_%d" % int(seed_input.value)
	var error: Error = CreatureBatchGenerator.export_pngs(selected, folder, "monster")
	if error != OK:
		_show_status("Export failed (%s): %s" % [error_string(error), folder], true)
		return
	_show_status("Saved %d PNGs + manifest JSON to %s" % [selected.size(), ProjectSettings.globalize_path(folder)], false)
