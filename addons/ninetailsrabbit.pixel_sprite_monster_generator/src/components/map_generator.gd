class_name MapGenerator

var rng: RandomNumberGenerator

func _init(random_source: RandomNumberGenerator = null) -> void:
	rng = random_source if random_source != null else RandomNumberGenerator.new()



func generate_new(size: Vector2, symmetry: float) -> Array[Variant]:
	symmetry = clampf(symmetry, 0.0, 100.0)
	
	var map = get_random_map(size, symmetry)
	
	for i in 2:
		random_walk(size, map)
	
	for x in range(ceilf(size.x * 0.5), size.x):
		for y in size.y:
			if rng.randi_range(0, 100) > symmetry:
				map[x][y] = chance(0.48)
				
				var to_center = (abs(y - size.y * 0.5) * 2.0) / size.y
				
				if x == floor(size.x  *0.5) - 1 || x == floor(size.x * 0.5) - 2:
					
					if rng.randf_range(0.0, 0.4) > to_center:
						map[x][y] = true
	return map
	
	
func get_random_map(size: Vector2, symmetry: float):
	var map: Array[Variant] = []
	
	for x in size.x:
		map.append([])
	
	for x in range(0, ceil(size.x * 0.5)):
		var arr = []
		
		for y in size.y:
			arr.append(chance(0.48))
			
			# When close to center increase the cances to fill the map, so it's more likely to end up with a sprite that's connected in the middle
			var to_center: float = (absf(y - size.y * 0.5) * 2.0) / size.y
			
			if x == floor(size.x * 0.5) - 1 || x == floor(size.x * 0.5) - 2:
				if rng.randf_range(0.0, 0.4) > to_center:
					arr[y] = true


		map[x] = arr.duplicate(true)
		map[size.x - x - 1] = arr.duplicate(true)
			
	return map
	
	
func random_walk(size: Vector2, map: Array[Variant]):
	var pos: Vector2 = Vector2(rng.randi() % int(size.x), rng.randi() % int(size.y))
	
	for i in 100:
		set_at_position(map, pos, true)
		set_at_position(map, Vector2(size.x - pos.x - 1, pos.y), true)
		
		pos += Vector2(rng.randi() % 3 - 1, rng.randi() %3 - 1)
	
	
func set_at_position(map: Array[Variant], pos: Vector2, val: bool) -> bool:
	if pos.x < 0 || pos.x >= map.size() || pos.y < 0 || pos.y >= map[pos.x].size():
		return false
	
	map[pos.x][pos.y] = val
	
	return true


func chance(probability_chance: float = 0.5, less_than: bool = true) -> bool:
	probability_chance = clamp(probability_chance, 0.0, 1.0)
	
	return rng.randf() < probability_chance if less_than else rng.randf() > probability_chance
