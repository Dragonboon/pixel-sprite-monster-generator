extends Control

## Self-contained original top-down creature laboratory.
var genome: Dictionary = {}
var family_select: OptionButton
var action_select: OptionButton
var seed_box: SpinBox
var output_size: OptionButton
var status: Label
var gallery: GridContainer
var frame_images: Array[TextureRect] = []
var sheet_preview: TextureRect
var next_seed: int = 4102
var clock: float = 0.0
var frame_index: int = 0
const BG := Color("#111923")

func _ready() -> void:
	var surface := ColorRect.new()
	surface.color = BG
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(surface)
	var panel := MarginContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		panel.add_theme_constant_override("margin_" + side, 16)
	add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	layout.add_child(_label("TOP-DOWN SPECIES SHEET LAB", 24))
	layout.add_child(_label("8 directions • 7 actions • original procedural artwork • nearest filtering", 13))
	var controls := HBoxContainer.new()
	layout.add_child(controls)
	seed_box = SpinBox.new()
	seed_box.min_value = 0
	seed_box.max_value = 2000000000
	seed_box.value = next_seed
	seed_box.rounded = true
	controls.add_child(seed_box)
	family_select = OptionButton.new()
	family_select.add_item("Random anatomy")
	for family_name in CreatureTopdownGenerator.FAMILIES:
		family_select.add_item(family_name)
	controls.add_child(family_select)
	output_size = OptionButton.new()
	for dimension in [48, 64, 96, 128]:
		output_size.add_item("%d px" % dimension, dimension)
	output_size.select(1)
	controls.add_child(output_size)
	_button(controls, "Generate", _regenerate)
	_button(controls, "New seed", _randomize_seed)
	_button(controls, "Export complete pack", _export)
	_button(controls, "Back to Species Lab", func() -> void: get_tree().change_scene_to_file("res://demo/species_lab.tscn"))
	var action_row := HBoxContainer.new()
	layout.add_child(action_row)
	action_row.add_child(_label("Animation: ", 15))
	action_select = OptionButton.new()
	for item in CreatureTopdownGenerator.ACTIONS:
		action_select.add_item(item)
	action_select.item_selected.connect(_change_action)
	action_row.add_child(action_select)
	status = _label("Ready", 13)
	layout.add_child(status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var contents := VBoxContainer.new()
	scroll.add_child(contents)
	contents.add_child(_label("Directional inspection — each sprite is rendered from the same anatomical DNA", 17))
	gallery = GridContainer.new()
	gallery.columns = 4
	contents.add_child(gallery)
	for direction in CreatureTopdownGenerator.DIRECTIONS:
		var cell := VBoxContainer.new()
		gallery.add_child(cell)
		cell.add_child(_label(direction, 14))
		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(170, 170)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cell.add_child(preview)
		frame_images.append(preview)
	contents.add_child(_label("Exported sheet preview (rows: S, SW, W, NW, N, NE, E, SE)", 16))
	sheet_preview = TextureRect.new()
	sheet_preview.custom_minimum_size = Vector2(400, 640)
	sheet_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sheet_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	contents.add_child(sheet_preview)
	_regenerate()
	set_process(true)


func _process(delta: float) -> void:
	clock += delta
	if clock >= 0.125:
		clock = fmod(clock, 0.125)
		frame_index = (frame_index + 1) % CreatureTopdownGenerator.FRAMES
		_refresh_frames()


func _label(message: String, size: int) -> Label:
	var label := Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#d5e7f0"))
	return label


func _button(parent: Node, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(callback)
	parent.add_child(button)


func _randomize_seed() -> void:
	next_seed = posmod(next_seed * 53 + 8347, 2000000000)
	seed_box.value = next_seed
	_regenerate()


func _regenerate() -> void:
	genome = CreatureTopdownGenerator.species(int(seed_box.value), family_select.selected - 1)
	frame_index = 0
	_refresh_frames()
	_refresh_sheet()
	status.text = "Species seed %d • %s • %s" % [int(genome["seed"]), CreatureTopdownGenerator.FAMILIES[int(genome["family"])], CreatureTopdownGenerator.ACTIONS[action_select.selected]]


func _change_action(_index: int) -> void:
	frame_index = 0
	_refresh_frames()
	_refresh_sheet()


func _refresh_frames() -> void:
	if genome.is_empty():
		return
	for direction in frame_images.size():
		var image: Image = CreatureTopdownGenerator.render(genome, direction, action_select.selected, frame_index, output_size.get_selected_id())
		frame_images[direction].texture = ImageTexture.create_from_image(image)


func _refresh_sheet() -> void:
	if genome.is_empty():
		return
	var result: Dictionary = CreatureTopdownSheets.build(genome, action_select.selected, output_size.get_selected_id())
	sheet_preview.texture = ImageTexture.create_from_image(result["image"])


func _export() -> void:
	if genome.is_empty():
		return
	var folder: String = "user://topdown_species/seed_%d" % int(genome["seed"])
	var error: Error = CreatureTopdownSheets.export_pack(genome, folder, output_size.get_selected_id())
	status.text = ("Saved in " + ProjectSettings.globalize_path(folder)) if error == OK else ("Export error: %d" % int(error))
