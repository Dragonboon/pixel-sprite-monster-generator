class_name CellularAutomata

var default_birth_limit: int
var default_death_limit: int
var default_steps: int


func _init(steps: int, birth_limit: int = 5, death_limit: int = 4) -> void:
	default_birth_limit = birth_limit
	default_death_limit = death_limit
	default_steps = steps


func do_steps(map: Array[Variant], steps: int = default_steps, birth_limit: int = default_birth_limit, death_limit: int = default_death_limit):
	for i in steps:
		map = step(map,  birth_limit, death_limit)
		
	return map


func step(map: Array[Variant],  birth_limit: int, death_limit: int) -> Array[Variant]:
	var duplicated_map: Array[Variant] = map.duplicate(true)
	
	for x in map.size():
		for y in map[x].size():
			var cell = duplicated_map[x][y]
			var neighbours = get_neighbours(map, Vector2(x,y))
			
			if cell && neighbours < death_limit:
				duplicated_map[x][y] = false
			elif !cell && neighbours > birth_limit:
				duplicated_map[x][y] = true
	
	
	return duplicated_map


func get_neighbours(map:Array[Variant], pos: Vector2) -> int:
	var count: int = 0
	
	for i in range(-1, 2):
		for j in range(-1, 2):
			if !(i == 0 && j ==0):
				if get_at_position(map, pos + Vector2(i, j)):
					count += 1

	return count


func get_at_position(map: Array[Variant], pos: Vector2):
	if pos.x < 0 || pos.x >= map.size() || pos.y < 0 || pos.y >= map[pos.x].size():
		return null
	
	return map[pos.x][pos.y]
