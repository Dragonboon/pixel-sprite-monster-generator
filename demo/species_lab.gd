extends Control

## Experimental species browser. Separate from the legacy laboratory by design:
## no changes to the original generator's seed stream, presets or UI state.
const SAVE_DIR: String = "user://species_lab"
const SEED_STEP: int = 7919
const MAX_GALLERY: int = 48
const ELEMENT_NAMES := ["Neutral", "Fire", "Water", "Plant", "Electric", "Earth", "Ice", "Shadow"]
const SPRITE_SIZES := [24, 32, 48, 64, 96, 128]
const BG := Color("#10151d")
const PANEL := Color("#1c2633")
const CARD := Color("#233142")
const ACTIVE := Color("#284f62")
const PALE := Color("#d9e8f2")
const MUTED := Color("#95acbd")

var random_source := RandomNumberGenerator.new()
var run_id: int = 0
var generated_items: Array[Dictionary] = []
var selected_index: int = -1
var pinned_genome: Dictionary = {}
var pinned_size: Vector2i = Vector2i(48, 48)

var seed_input: SpinBox
var count_input: SpinBox
var form_filter: OptionButton
var element_filter: OptionButton
var size_filter: OptionButton
var progress: ProgressBar
var status_label: Label
var gallery_flow: HFlowContainer
var results_label: Label
var preview: TextureRect
var pinned_preview: TextureRect
var pinned_info: Label
var metadata_label: Label
var genome_view: TextEdit
var save_button: Button
var copy_button: Button
var pin_button: Button
var card_panels: Array[PanelContainer] = []


func _ready() -> void:
	random_source.randomize()
	_build_ui()
	_start_batch(false)


func _exit_tree() -> void:
	run_id += 1


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	page.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	heading.add_child(_label("SPECIES LAB  /  PROCEDURAL CREATURES", 24))
	heading.add_child(_label("14 body plans  •  8 elements  •  deterministic genomes  •  experimental", 12, MUTED))
	_button(header, "Legacy generator lab  ↗", _open_legacy)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	page.add_child(body)

	var left := _panel(PANEL, 262)
	body.add_child(left)
	var settings := VBoxContainer.new()
	settings.add_theme_constant_override("separation", 10)
	left.add_child(settings)
	settings.add_child(_label("01   GENERATION", 17))
	settings.add_child(_label("Family / body plan", 12, MUTED))
	form_filter = OptionButton.new()
	form_filter.add_item("All forms (balanced)")
	for form_name in CreatureSpeciesGenerator.FORM_NAMES:
		form_filter.add_item(form_name.replace("_", " ").capitalize())
	settings.add_child(form_filter)
	settings.add_child(_label("Element / palette", 12, MUTED))
	element_filter = OptionButton.new()
	element_filter.add_item("Any element")
	for element_name in ELEMENT_NAMES:
		element_filter.add_item(element_name)
	settings.add_child(element_filter)
	settings.add_child(_label("Base seed", 12, MUTED))
	seed_input = SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 2000000000
	seed_input.step = 1
	seed_input.rounded = true
	seed_input.value = 4200
	settings.add_child(seed_input)
	settings.add_child(_label("Creatures per batch (1–48)", 12, MUTED))
	count_input = SpinBox.new()
	count_input.min_value = 1
	count_input.max_value = MAX_GALLERY
	count_input.step = 1
	count_input.rounded = true
	count_input.value = 14
	settings.add_child(count_input)
	settings.add_child(_label("Resolution (native pixels)", 12, MUTED))
	size_filter = OptionButton.new()
	for sprite_size in SPRITE_SIZES:
		size_filter.add_item("%d × %d" % [sprite_size, sprite_size])
	size_filter.select(2)
	settings.add_child(size_filter)
	_button(settings, "Generate gallery", _start_batch.bind(false))
	_button(settings, "Compare all 14 forms", _start_batch.bind(true))
	_button(settings, "New random seed", _new_seed)
	settings.add_child(HSeparator.new())
	_button(settings, "Export gallery: PNG + JSON", _export_gallery)
	progress = ProgressBar.new()
	progress.max_value = 14
	progress.value = 0
	progress.show_percentage = false
	settings.add_child(progress)
	status_label = _label("Ready", 12, MUTED)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings.add_child(status_label)
	var hint := _label("Tip: Compare forms keeps one seed and element fixed; Generate gallery explores new seeds.", 12, MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings.add_child(hint)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 8)
	body.add_child(center)
	results_label = _label("02   GALLERY", 17)
	center.add_child(results_label)
	var scroller := ScrollContainer.new()
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center.add_child(scroller)
	gallery_flow = HFlowContainer.new()
	gallery_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_flow.add_theme_constant_override("h_separation", 10)
	gallery_flow.add_theme_constant_override("v_separation", 10)
	scroller.add_child(gallery_flow)

	var right := _panel(PANEL, 304)
	body.add_child(right)
	var inspect_scroll := ScrollContainer.new()
	inspect_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspect_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(inspect_scroll)
	var inspector := VBoxContainer.new()
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector.add_theme_constant_override("separation", 8)
	inspect_scroll.add_child(inspector)
	inspector.add_child(_label("03   GENOME INSPECTOR", 17))
	preview = _preview(Vector2(256, 208))
	inspector.add_child(preview)
	metadata_label = _label("Select a creature to inspect its traits.", 12, PALE)
	metadata_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector.add_child(metadata_label)
	pin_button = _button(inspector, "Pin for visual comparison", _pin_selection)
	save_button = _button(inspector, "Save selected PNG + genome", _save_selected)
	copy_button = _button(inspector, "Copy genome JSON", _copy_genome)
	inspector.add_child(_label("Reproducible genome (schema v1)", 12, MUTED))
	genome_view = TextEdit.new()
	genome_view.editable = false
	genome_view.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	genome_view.custom_minimum_size = Vector2(274, 205)
	inspector.add_child(genome_view)
	inspector.add_child(HSeparator.new())
	inspector.add_child(_label("PINNED REFERENCE", 12, MUTED))
	pinned_info = _label("Nothing pinned yet", 12, MUTED)
	inspector.add_child(pinned_info)
	pinned_preview = _preview(Vector2(170, 144))
	inspector.add_child(pinned_preview)
	pinned_preview.visible = false
	_set_selection_controls(false)


func _label(value: String, points: int = 14, tint: Color = PALE) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", points)
	label.add_theme_color_override("font_color", tint)
	return label


func _panel(color: Color, minimum_width: float = 0.0) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minimum_width
	_style_panel(panel, color)
	return panel


func _style_panel(panel: PanelContainer, color: Color, highlighted: bool = false) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	style.set_border_width_all(2 if highlighted else 1)
	style.border_color = Color("#4fb6cd") if highlighted else Color("#34495c")
	panel.add_theme_stylebox_override("panel", style)


func _button(parent: Node, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _preview(minimum: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.custom_minimum_size = minimum
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return image


func _set_selection_controls(enabled: bool) -> void:
	save_button.disabled = not enabled
	copy_button.disabled = not enabled
	pin_button.disabled = not enabled


func _open_legacy() -> void:
	get_tree().change_scene_to_file("res://demo/test.tscn")


func _new_seed() -> void:
	seed_input.value = random_source.randi_range(0, 2000000000)
	_start_batch(false)


func _start_batch(compare_forms: bool) -> void:
	run_id += 1
	var token: int = run_id
	generated_items.clear()
	selected_index = -1
	card_panels.clear()
	for child in gallery_flow.get_children():
		gallery_flow.remove_child(child)
		child.queue_free()
	preview.texture = null
	genome_view.text = ""
	metadata_label.text = "Generating species..."
	_set_selection_controls(false)
	var count: int = CreatureSpeciesGenerator.Form.size() if compare_forms else int(count_input.value)
	progress.max_value = count
	progress.value = 0
	results_label.text = "02   GALLERY  /  %d requested" % count
	status_label.text = "Generating %d sprites..." % count
	_generate_chunked(token, count, compare_forms)


func _generate_chunked(token: int, count: int, compare_forms: bool) -> void:
	var base_seed: int = int(seed_input.value)
	var native_size: int = SPRITE_SIZES[size_filter.selected]
	var chosen_form: int = form_filter.selected - 1
	var chosen_element: int = element_filter.selected - 1
	var started: int = Time.get_ticks_msec()
	for index in count:
		if token != run_id or not is_inside_tree():
			return
		var chosen_seed: int = base_seed if compare_forms else base_seed + index * SEED_STEP
		var target_form: int = index if compare_forms else (index % CreatureSpeciesGenerator.Form.size() if chosen_form < 0 else chosen_form)
		var candidate: Dictionary = CreatureSpeciesGenerator.generate(
			chosen_seed, Vector2i(native_size, native_size), target_form, chosen_element
		)
		candidate["index"] = index
		generated_items.append(candidate)
		_add_card(candidate, index)
		if index == 0:
			_select(index)
		progress.value = index + 1
		if (index + 1) % 4 == 0 and index + 1 < count:
			status_label.text = "Generated %d / %d" % [index + 1, count]
			await get_tree().process_frame
	if token != run_id:
		return
	var elapsed: int = Time.get_ticks_msec() - started
	status_label.text = "%d sprites generated in %d ms" % [generated_items.size(), elapsed]
	results_label.text = "02   GALLERY  /  %d species  /  %s" % [count, "controlled comparison" if compare_forms else "seed exploration"]


func _add_card(item: Dictionary, index: int) -> void:
	var card := _panel(CARD, 148)
	card.custom_minimum_size.y = 195
	card_panels.append(card)
	gallery_flow.add_child(card)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 4)
	card.add_child(contents)
	var form: int = int(item["form"])
	var element: int = int(item["element"])
	var image := _preview(Vector2(126, 126))
	image.texture = ImageTexture.create_from_image(item["image"])
	image.mouse_filter = Control.MOUSE_FILTER_STOP
	image.gui_input.connect(_on_card_input.bind(index))
	contents.add_child(image)
	contents.add_child(_label(CreatureSpeciesGenerator.FORM_NAMES[form].replace("_", " ").capitalize(), 13))
	contents.add_child(_label("%s  ·  #%d" % [ELEMENT_NAMES[element], int(item["seed"])], 11, MUTED))
	_button(contents, "Inspect", _select.bind(index))


func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select(index)


func _select(index: int) -> void:
	if index < 0 or index >= generated_items.size():
		return
	selected_index = index
	var item: Dictionary = generated_items[index]
	var form: int = int(item["form"])
	var element: int = int(item["element"])
	var genome: Dictionary = item["genome"]
	preview.texture = ImageTexture.create_from_image(item["image"])
	metadata_label.text = "%s  /  %s\nSeed: %d  ·  %d × %d px\nEyes: %d  ·  Horns: %d  ·  Pattern: %d\nBody scale: %.2f × %.2f" % [
		CreatureSpeciesGenerator.FORM_NAMES[form].replace("_", " ").capitalize(),
		ELEMENT_NAMES[element], int(item["seed"]),
		int(item["image"].get_width()) - 2, int(item["image"].get_height()) - 2,
		int(genome["eye_count"]), int(genome["horns"]), int(genome["pattern"]),
		float(genome["body_width"]), float(genome["body_height"])
	]
	genome_view.text = JSON.stringify(genome, "\t")
	_set_selection_controls(true)
	for i in card_panels.size():
		_style_panel(card_panels[i], ACTIVE if i == index else CARD, i == index)


func _pin_selection() -> void:
	if selected_index < 0:
		return
	var item: Dictionary = generated_items[selected_index]
	pinned_genome = item["genome"].duplicate(true)
	pinned_size = Vector2i(item["image"].get_width() - 2, item["image"].get_height() - 2)
	pinned_preview.texture = ImageTexture.create_from_image(item["image"])
	pinned_preview.visible = true
	pinned_info.text = "%s  ·  seed %d" % [
		CreatureSpeciesGenerator.FORM_NAMES[int(item["form"])].replace("_", " ").capitalize(),
		int(item["seed"])
	]


func _copy_genome() -> void:
	if selected_index >= 0:
		DisplayServer.clipboard_set(JSON.stringify(generated_items[selected_index]["genome"], "\t"))
		status_label.text = "Selected genome copied to clipboard"


func _save_selected() -> void:
	if selected_index < 0:
		return
	var problem: Error = _ensure_export_directory()
	if problem != OK:
		_report_export_error(problem)
		return
	var item: Dictionary = generated_items[selected_index]
	var file_stem: String = _filename(item)
	problem = _write_item(item, file_stem)
	if problem == OK:
		status_label.text = "Saved %s.png and .json in %s" % [file_stem, ProjectSettings.globalize_path(SAVE_DIR)]
	else:
		_report_export_error(problem)


func _export_gallery() -> void:
	if generated_items.is_empty():
		status_label.text = "Generate a gallery before exporting"
		return
	var problem: Error = _ensure_export_directory()
	if problem != OK:
		_report_export_error(problem)
		return
	var records: Array[Dictionary] = []
	for item in generated_items:
		var stem: String = _filename(item)
		problem = _write_item(item, stem)
		if problem != OK:
			_report_export_error(problem)
			return
		records.append({"file": stem + ".png", "genome": item["genome"]})
	var manifest_path: String = SAVE_DIR.path_join("gallery_manifest.json")
	var output := FileAccess.open(manifest_path, FileAccess.WRITE)
	if output == null:
		_report_export_error(FileAccess.get_open_error())
		return
	output.store_string(JSON.stringify({"schema_version": 1, "items": records}, "\t"))
	output.close()
	status_label.text = "Saved %d PNGs + genomes in %s" % [records.size(), ProjectSettings.globalize_path(SAVE_DIR)]


func _ensure_export_directory() -> Error:
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))


func _filename(item: Dictionary) -> String:
	return "species_%03d_seed%d_form%d_element%d" % [
		int(item["index"]), int(item["seed"]), int(item["form"]), int(item["element"])
	]


func _write_item(item: Dictionary, stem: String) -> Error:
	var problem: Error = item["image"].save_png(SAVE_DIR.path_join(stem + ".png"))
	if problem != OK:
		return problem
	var output := FileAccess.open(SAVE_DIR.path_join(stem + ".json"), FileAccess.WRITE)
	if output == null:
		return FileAccess.get_open_error()
	output.store_string(JSON.stringify(item["genome"], "\t"))
	output.close()
	return OK


func _report_export_error(problem: Error) -> void:
	status_label.text = "Export failed (Godot error %d)" % int(problem)
