class_name CellDrawer extends Node2D

var cells: Array[Variant] = []
var draw_size: float = 6.0
var speed: float = 5.0
var smooth_lerp_factor: float = 20.0
var lifetime: float = 0.0
var is_eye: bool = false
var animation: bool = true:
	set(value):
		if value !=  animation:
			animation = value
			set_process(animation)
			
var horizontal_animation: bool = true
var vertical_animation: bool = true

@onready var cell_group_drawer: CellGroupDrawer = get_parent() as CellGroupDrawer


func _enter_tree() -> void:
	name = "CellDrawer"


func _ready():

	set_process(animation)
	

func _process(delta):
	if animation:
		lifetime += delta * speed
		
		if horizontal_animation:
			position.x = cos(lifetime) * smooth_lerp_factor
			
		if vertical_animation:
			position.y = sin(lifetime) * smooth_lerp_factor


func set_eye():
	is_eye = true
	queue_redraw()
	
	
func set_cells(new_cells):
	cells = new_cells
	queue_redraw()


func set_speed(new_speed: float):
	speed = new_speed


func _draw():
	if cells.is_empty():
		return
	var average = Vector2()
	var size = 0
	var eye_cutoff = 0.0
	
	if is_eye:
		for c in cells:
			size += 1
			average += c.position
		eye_cutoff = sqrt(float(size)) * 0.3
	
	average = average / cells.size()
	
	for cell in cells:
		draw_rect(Rect2(cell.position.x * draw_size, cell.position.y * draw_size, draw_size, draw_size), cell.color)
		
		if is_eye && average.distance_to(cell.position) < eye_cutoff:
			draw_rect(Rect2(cell.position.x * draw_size, cell.position.y * draw_size, draw_size, draw_size), cell.color.darkened(0.85))
