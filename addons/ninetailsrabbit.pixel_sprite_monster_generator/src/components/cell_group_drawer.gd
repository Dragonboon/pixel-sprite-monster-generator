class_name CellGroupDrawer extends Node2D

var groups: Array[Variant] = []
var negative_groups: Array[Variant] = []
var draw_size: float = 6.0:
	set(value):
		draw_size = value
		for cell in cells():
			cell.draw_size = value
			cell.queue_redraw()
var animation = true:
	set(value):
		if value != animation:
			animation = value
			
			for cell: CellDrawer in cells():
				cell.animation = animation
var horizontal_animation = true:
	set(value):
		if value != horizontal_animation:
			horizontal_animation = value
			
			for cell: CellDrawer in cells():
				cell.horizontal_animation = horizontal_animation
				
var vertical_animation = true:
	set(value):
		if value != vertical_animation:
			vertical_animation = value
			
			for cell: CellDrawer in cells():
				cell.vertical_animation = vertical_animation
var speed: float = 5.0:
	set(value):
		if value != speed:
			speed = value
			
			for cell: CellDrawer in cells():
				cell.speed = speed
var smooth_lerp_factor: float = 20.0:
	set(value):
		if value != smooth_lerp_factor:
			smooth_lerp_factor = value
			
			for cell: CellDrawer in cells():
				cell.smooth_lerp_factor = smooth_lerp_factor


func _enter_tree() -> void:
	name = "CellGroupDrawer"

	
func _ready():
	var largest = 0
	
	for g in groups:
		largest = maxi(largest, g.arr.size())
	
	for i in range(groups.size() - 1, -1, -1):
		var g = groups[i].arr
		groups[i]["start_time"] = g.size() + groups.size()
		
		if g.size() >= largest * 0.25:
			var cell = create_cell(g, animation, groups[i].start_time, speed, smooth_lerp_factor) 
			add_child(cell)
		else:
			groups.remove_at(i)
		
	for g in negative_groups:
		if g.valid:
			var touching = false
			
			for g2 in groups:
				if group_is_touching_group(g.arr, g2.arr):
					touching = true
					
					if g.has("start_time"):
						g2["start_time"] = g["start_time"]
					else:
						g["start_time"] = g2["start_time"]
						
			if touching:
				var cell = create_cell(g.arr, animation, 0, speed, smooth_lerp_factor) 
				add_child(cell)

				if (g.arr.size() + negative_groups.size()) % 5 >= 3:
					cell.set_eye()


func create_cell(cells, cell_animation: bool, cell_lifetime: int, cell_speed: float, cell_smooth_lerp_factor: float) -> CellDrawer:
	var cell =  CellDrawer.new()
	cell.set_cells(cells)
	cell.draw_size = draw_size
	
	cell.speed = cell_speed
	cell.lifetime = cell_lifetime
	cell.animation = cell_animation
	cell.horizontal_animation = horizontal_animation
	cell.vertical_animation = vertical_animation
	cell.smooth_lerp_factor = cell_smooth_lerp_factor
	
	return cell
	
	
func cells() -> Array[CellDrawer]:
	var cells: Array[CellDrawer] = []
	cells.assign(get_children().filter(func(child: Node): return child is CellDrawer))
	
	return cells
	
	
func enable_animation():
	animation = true
	

func disable_animation():
	animation = false


func group_is_touching_group(g1, g2) -> bool:
	# Avoid comparing every pair of pixels when joining large colored groups.
	var occupied: Dictionary = {}
	for cell in g2:
		occupied[Vector2i(cell.position)] = true
	for cell in g1:
		var point := Vector2i(cell.position)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if occupied.has(point + offset):
				return true
	return false
