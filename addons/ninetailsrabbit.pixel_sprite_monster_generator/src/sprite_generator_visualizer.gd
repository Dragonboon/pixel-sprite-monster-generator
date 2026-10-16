extends Control

@export var main_noise: FastNoiseLite
@export var secondary_noise: FastNoiseLite
@onready var sprite_result_container: CenterContainer = $CenterContainer
@onready var generate_button: Button = $GenerateButton
var generator: PixelSpriteMonsterGenerator

func _ready() -> void:
	generator = PixelSpriteMonsterGenerator.new()
	generator.main_noise = main_noise
	generator.secondary_noise = secondary_noise
	generator.sprite_size = Vector2(64, 64)
	generator.sprite_draw_size = Vector2(400, 400)
	sprite_result_container.add_child(generator)
	generate_button.pressed.connect(draw_sprite)

func draw_sprite() -> void:
	if is_instance_valid(generator):
		generator.draw_sprite()

func on_generate_button_pressed() -> void:
	draw_sprite()
