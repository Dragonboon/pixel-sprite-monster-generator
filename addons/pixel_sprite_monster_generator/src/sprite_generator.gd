class_name PixelSpriteMonsterGenerator extends Node2D


## The sprite size at which the sprite will be generated
@export var sprite_size: Vector2 = Vector2(48, 48)
@export var sprite_draw_size: Vector2 = Vector2(128, 128)
## A symmetry of 100 % draw a more organic monster with symmetrical sides, the less symmetry, the more chaotic the final monster.
@export_range(0, 100.0, 0.1) var symmetry: float = 100.0
## When pixel perfect it's enabled, the final result will be more 'pixelated' and squared
@export var pixel_perfect: bool = false
@export var outlined: bool = true
@export_category("Silhouette")
## Zero preserves the original procedural output. Higher values trim organic contours.
@export_range(0.0, 1.0, 0.05) var organic_shape_strength: float = 0.0
## Optional removal of detached filled islands after cellular smoothing.
@export var keep_largest_body: bool = false
## The number of colors to generate the sprie palette
@export var number_of_colors: int = 12:
	set(value):
		if value != number_of_colors:
			number_of_colors = value
			update_group_drawer()
## The randomization of seed when it comes to generate the sprite. When this is false, the manual seed is used instead
@export var randomize_seed: bool = true
@export var manual_seed: int = 0
@export_category("Cell Draw")
@export var cell_animation: bool = true:
	set(value):
		if value != cell_animation:
			cell_animation = value
			update_group_drawer()
@export var cell_horizontal_animation: bool = false:
	set(value):
		if value != cell_horizontal_animation:
			cell_horizontal_animation = value
			update_group_drawer()
@export var cell_vertical_animation: bool = true:
	set(value):
		if value != cell_vertical_animation:
			cell_vertical_animation = value
			update_group_drawer()
@export var cell_animation_speed: float =  5.0:
	set(value):
		if value != cell_animation_speed:
			cell_animation_speed = value
			update_group_drawer()
@export var cell_smooth_lerp_factor: float =  20.0:
	set(value):
		if value != cell_smooth_lerp_factor:
			cell_smooth_lerp_factor = value
			update_group_drawer()
@export_category("Color scheme")
@export var custom_color_palette: PixelSpriteMonsterGeneratorColorPalette
## The method to generate the colors, rgb is more random and hsv keeps a consistency on the color palette generated
@export var color_generation_method: ColorSchemeGenerator.ColorGenerationMethod = ColorSchemeGenerator.ColorGenerationMethod.GoldenRatioHSV
@export var color_saturation: float = 0.5
@export var color_value: float = 0.95
@export var eye_color_generation_method: ColorSchemeGenerator.ColorGenerationMethod = ColorSchemeGenerator.ColorGenerationMethod.GoldenRatioHSV
@export var eye_color_saturation: float = 0.5
@export var eye_color_value: float = 0.95
@export_category("Color filler")
## This noise shapes the color fill using the generated palette
@export var main_noise: FastNoiseLite = preload("res://addons/pixel_sprite_monster_generator/src/noises/main_noise.tres")
## This secondary noise shapes the color fill using the generated palette
@export var secondary_noise: FastNoiseLite = preload("res://addons/pixel_sprite_monster_generator/src/noises/secondary_noise.tres")
@export_category("Cellular automata")
## More the steps, more detailed the final result
@export var steps: int = 4
## A cell is born if it has exactly "n" neighbors.
@export var birth_limit: int = 5
## A cell dies if it has fewer than "n" or more than "n" neighbors.
@export var death_limit: int = 4


## Seed used for the most recent generation; save it to reproduce a random result.
var last_seed: int = 0
var rng := RandomNumberGenerator.new()

var map_generator: MapGenerator
var cellular_automata: CellularAutomata
var color_scheme_generator: ColorSchemeGenerator
var color_filler: ColorFiller

var cell_group_drawer: CellGroupDrawer
var scheme: PackedColorArray 
var eye_scheme: PackedColorArray
var all_color_groups: Dictionary = {}


func _ready() -> void:
	draw_sprite()


func draw_sprite() -> void:
	clear()
	
	# Validate before allocating a map; isolate RNG and noise from the host game.
	sprite_size = Vector2(clampi(int(sprite_size.x), 4, 256), clampi(int(sprite_size.y), 4, 256))
	number_of_colors = clampi(number_of_colors, 1, 64)
	if randomize_seed:
		rng.randomize()
		last_seed = rng.seed
	else:
		last_seed = manual_seed
	rng.seed = last_seed
	map_generator = MapGenerator.new(rng)
	cellular_automata = CellularAutomata.new(clampi(steps, 0, 20), clampi(birth_limit, 0, 8), clampi(death_limit, 0, 8))
	color_scheme_generator = ColorSchemeGenerator.new(rng)
	color_filler = ColorFiller.new(main_noise, secondary_noise, rng)

	var map: Array[Variant] = map_generator.generate_new(sprite_size, symmetry)
	map = cellular_automata.do_steps(map)
	if organic_shape_strength > 0.0 or keep_largest_body:
		map = SilhouetteRefiner.refine(map, organic_shape_strength, keep_largest_body, symmetry)
	
	var custom_color_palette_exists: bool = custom_color_palette != null and custom_color_palette.colors.size() > 0
	var num_of_colors: int = custom_color_palette.colors.size() if custom_color_palette_exists  else number_of_colors
	
	if custom_color_palette_exists:
		scheme = custom_color_palette.colors
		eye_scheme = custom_color_palette.colors
	else:
		if _color_generation_is_hsv():
			scheme = color_scheme_generator.generate_random_hsv_colors(num_of_colors, color_saturation, color_value)
		elif _color_generation_is_random_rgb():
			scheme = color_scheme_generator.generate_random_rgb_colors(num_of_colors)
		
		if _eye_color_generation_is_hsv():
			eye_scheme = color_scheme_generator.generate_random_hsv_colors(num_of_colors, eye_color_saturation, eye_color_value)
		elif _eye_color_generation_is_random_rgb():
			eye_scheme = color_scheme_generator.generate_random_rgb_colors(num_of_colors)
			
	all_color_groups = color_filler.fill_colors(map, scheme, eye_scheme, num_of_colors, outlined)
	
	update_group_drawer()


func update_group_drawer() -> void:
	if not is_instance_valid(cell_group_drawer):
		cell_group_drawer = CellGroupDrawer.new()
	
	if all_color_groups.is_empty():
		return
		
	cell_group_drawer.position = Vector2.ZERO
	cell_group_drawer.groups = all_color_groups.groups
	cell_group_drawer.negative_groups = all_color_groups.negative_groups
	cell_group_drawer.draw_size = 1 if pixel_perfect else maxf(0.01, minf(sprite_draw_size.x / sprite_size.x, sprite_draw_size.y / sprite_size.y))
	cell_group_drawer.animation = cell_animation
	cell_group_drawer.horizontal_animation = cell_horizontal_animation
	cell_group_drawer.vertical_animation = cell_vertical_animation
	cell_group_drawer.speed = cell_animation_speed
	cell_group_drawer.smooth_lerp_factor = cell_smooth_lerp_factor
	
	if not cell_group_drawer.is_inside_tree():
		add_child(cell_group_drawer)
	
	
func clear() -> void:
	if is_instance_valid(cell_group_drawer):
		cell_group_drawer.free()
	cell_group_drawer = null
	all_color_groups.clear()


#region Helpers
func _color_generation_is_hsv() -> bool:
	return color_generation_method == ColorSchemeGenerator.ColorGenerationMethod.GoldenRatioHSV


func _color_generation_is_random_rgb() -> bool:
	return color_generation_method == ColorSchemeGenerator.ColorGenerationMethod.RandomRGB


func _eye_color_generation_is_hsv() -> bool:
	return eye_color_generation_method == ColorSchemeGenerator.ColorGenerationMethod.GoldenRatioHSV


func _eye_color_generation_is_random_rgb() -> bool:
	return eye_color_generation_method == ColorSchemeGenerator.ColorGenerationMethod.RandomRGB


func _set_owner_to_edited_scene_root(node: Node) -> void:
	if Engine.is_editor_hint() and node.get_tree():
		node.owner = node.get_tree().edited_scene_root
#endregion


## Static, unscaled sprite in its neutral pose, with one transparent pixel of padding.
## Animation is deliberately not baked into the image. Works without a renderer.
func get_image() -> Image:
	if not is_instance_valid(cell_group_drawer) or cell_group_drawer.cells().is_empty():
		return null
	var result := Image.create(int(sprite_size.x) + 2, int(sprite_size.y) + 2, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	for drawer in cell_group_drawer.cells():
		var center := Vector2.ZERO
		for cell in drawer.cells:
			center += cell.position
		center /= maxf(1.0, drawer.cells.size())
		var eye_radius := sqrt(float(drawer.cells.size())) * 0.3
		for cell in drawer.cells:
			var point := Vector2i(cell.position) + Vector2i.ONE
			if point.x < 0 or point.y < 0 or point.x >= result.get_width() or point.y >= result.get_height():
				continue
			var color: Color = cell.color
			if drawer.is_eye and center.distance_to(cell.position) < eye_radius:
				color = color.darkened(0.85)
			result.set_pixelv(point, color)
	return result


## Use user:// in exported games. Parent directory must already exist.
func export_png(path: String) -> Error:
	var result := get_image()
	if result == null:
		return ERR_UNCONFIGURED
	return result.save_png(path)
