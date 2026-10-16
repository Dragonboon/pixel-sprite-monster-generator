@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("PixelSpriteMonsterGenerator", "Node2D", preload("src/sprite_generator.gd"), preload("assets/pixel-monster-sprite-generator.svg"))
	add_custom_type("ColorPalette", "Resource", preload("assets/color_palettes/color_palette.gd"), preload("assets/pixel-monster-sprite-generator.svg"))


func _exit_tree() -> void:
	remove_custom_type("ColorPalette")
	remove_custom_type("PixelSpriteMonsterGenerator")
