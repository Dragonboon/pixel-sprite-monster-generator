class_name CreatureVariety
extends RefCounted

## Image-space silhouette diagnostics. Color is intentionally ignored to
## detect creatures that only differ by their palette.
const GRID: int = 12
const NEAR_DUPLICATE_DISTANCE: float = 0.12


static func signature(image: Image) -> PackedByteArray:
	var sample := PackedByteArray()
	sample.resize(GRID * GRID)
	if image == null or image.is_empty():
		return sample
	var left: int = image.get_width()
	var top: int = image.get_height()
	var right: int = -1
	var bottom: int = -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5:
				left = mini(left, x)
				right = maxi(right, x)
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if right < left:
		return sample
	var w: int = right - left + 1
	var h: int = bottom - top + 1
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if image.get_pixel(x, y).a < 0.5:
				continue
			var gx: int = mini(GRID - 1, (x - left) * GRID / w)
			var gy: int = mini(GRID - 1, (y - top) * GRID / h)
			sample[gy * GRID + gx] = 1
	return sample


## Normalized Jaccard distance in [0..1], where 0 means identical masks.
static func distance(a: PackedByteArray, b: PackedByteArray) -> float:
	if a.size() != b.size() or a.is_empty():
		return 1.0
	var union_count: int = 0
	var different: int = 0
	for i in a.size():
		if a[i] != 0 or b[i] != 0:
			union_count += 1
			if a[i] != b[i]:
				different += 1
	if union_count == 0:
		return 0.0
	return float(different) / float(union_count)


## Evaluates 1..128 images in O(N² * GRID²), without retaining textures.
## Adds novelty and near_duplicate to the item dictionaries in place.
static func summarize(items: Array[Dictionary]) -> Dictionary:
	var silhouettes: Array[PackedByteArray] = []
	var unique_exact: Dictionary = {}
	var unique_shapes: int = 0
	var near_count: int = 0
	var novelty_total: float = 0.0
	for item in items:
		var image: Image = item.get("image")
		if image == null:
			continue
		var data: PackedByteArray = image.get_data()
		unique_exact[hash(data)] = true
		var current: PackedByteArray = signature(image)
		var nearest: float = 1.0
		for previous in silhouettes:
			nearest = minf(nearest, distance(current, previous))
		var is_duplicate: bool = not silhouettes.is_empty() and nearest < NEAR_DUPLICATE_DISTANCE
		if is_duplicate:
			near_count += 1
		else:
			unique_shapes += 1
		item["novelty"] = nearest
		item["near_duplicate"] = is_duplicate
		novelty_total += nearest
		silhouettes.append(current)
	return {
		"exact_unique": unique_exact.size(),
		"silhouette_unique": unique_shapes,
		"near_duplicates": near_count,
		"mean_novelty": novelty_total / float(maxi(1, silhouettes.size())),
		"silhouette_unique_ratio": float(unique_shapes) / float(maxi(1, silhouettes.size()))
	}
