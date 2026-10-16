extends Control

# Exploration gallery lives outside addons; generator API remains reusable.
const PRESETS: Array[Dictionary] = [
	{"name": "Original", "shape": 0.0, "anatomy": CreatureMorphology.Archetype.ORIGINAL, "symmetry": 100.0, "steps": 4, "colors": 12, "size": Vector2(48, 48)},
	{"name": "Forest biped", "shape": 0.35, "anatomy": CreatureMorphology.Archetype.BIPED, "symmetry": 100.0, "steps": 4, "colors": 9, "size": Vector2(48, 48)},
	{"name": "Insectoid", "shape": 0.2, "anatomy": CreatureMorphology.Archetype.INSECTOID, "symmetry": 100.0, "steps": 3, "colors": 7, "size": Vector2(48, 48)},
	{"name": "Soft slime", "shape": 0.6, "anatomy": CreatureMorphology.Archetype.SLIME, "symmetry": 100.0, "steps": 3, "colors": 8, "size": Vector2(48, 48)},
	{"name": "Winged creature", "shape": 0.4, "anatomy": CreatureMorphology.Archetype.WINGED, "symmetry": 100.0, "steps": 4, "colors": 10, "size": Vector2(48, 48)},
	{"name": "Wild biped", "shape": 0.15, "anatomy": CreatureMorphology.Archetype.BIPED, "symmetry": 83.0, "steps": 5, "colors": 6, "size": Vector2(48, 48)}
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
var view_selector: OptionButton
var active_style: int = 0


func _ready() -> void:
	random_source.randomize()
	generator = PixelSpriteMonsterGenerator.new()
	generator.visible = false
	generator.cell_animation = false
	generator.randomize_seed = false
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
	_add_button(controls, "Export six PNGs", _export_gallery)
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
	for item in ["Front", "3/4 experimental"]:
		view_selector.add_item(item)
	art_controls.add_child(view_selector)
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
	mood_selector.item_selected.connect(func(_v: int) -> void: _regenerate())
	style_selector.item_selected.connect(func(_v: int) -> void: _regenerate())
	view_selector.item_selected.connect(func(_v: int) -> void: _regenerate())
	quality_slider.drag_ended.connect(func(_v: bool) -> void: _regenerate())
	shade_slider.drag_ended.connect(func(_v: bool) -> void: _regenerate())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	gallery = GridContainer.new()
	gallery.columns = 3
	gallery.add_theme_constant_override("h_separation", 12)
	gallery.add_theme_constant_override("v_separation", 12)
	scroll.add_child(gallery)
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
	for child in gallery.get_children():
		gallery.remove_child(child)
		child.queue_free()
	rendered_images.clear()
	var base_seed := int(seed_input.value)
	for index in 6:
		var preset: Dictionary = PRESETS[index]
		generator.sprite_size = preset["size"]
		generator.symmetry = float(preset["symmetry"])
		generator.steps = int(preset["steps"])
		generator.number_of_colors = int(preset["colors"])
		generator.organic_shape_strength = float(preset["shape"])
		generator.keep_largest_body = true
		generator.creature_archetype = preset["anatomy"]
		generator.anatomy_strength = 0.95
		generator.facial_eyes = true
		generator.silhouette_mood = mood_selector.selected
		generator.quality_enabled = true
		generator.quality_min_score = quality_slider.value
		generator.quality_max_attempts = 8
		generator.visual_style = style_selector.selected
		generator.view_mode = view_selector.selected
		generator.shading_strength = shade_slider.value
		generator.dithering_strength = 0.18
		generator.manual_seed = base_seed + index * 7919
		generator.draw_sprite()
		var generated: Image = generator.get_image()
		if generated == null:
			continue
		rendered_images.append(generated)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(285, 210)
		var contents := VBoxContainer.new()
		card.add_child(contents)
		var label := Label.new()
		label.text = "%s  ·  seed %d  ·  Q %.0f" % [preset["name"], generator.last_seed, generator.last_quality_score]
		contents.add_child(label)
		var preview := TextureRect.new()
		preview.texture = ImageTexture.create_from_image(generated)
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.custom_minimum_size = Vector2(270, 168)
		contents.add_child(preview)
		gallery.add_child(card)
	status_label.text = "Four anatomy families plus original and an asymmetric biped. Export preserves pixel size."


func _export_gallery() -> void:
	var base_seed := int(seed_input.value)
	for index in rendered_images.size():
		var path := "user://monster_%d_%02d.png" % [base_seed, index + 1]
		var error: Error = rendered_images[index].save_png(path)
		if error != OK:
			status_label.text = "Export failed: %s" % error_string(error)
			return
	status_label.text = "Saved %d images to %s" % [rendered_images.size(), ProjectSettings.globalize_path("user://")]
