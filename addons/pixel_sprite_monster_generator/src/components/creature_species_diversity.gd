class_name CreatureSpeciesDiversity
extends RefCounted

## Silhouette signature is deliberately alpha-only: recolors are not new species.
## 8x8 occupancy bins plus body dimensions and centroid detect near duplicates.
const GRID: int = 8

static func signature(image: Image) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(GRID * GRID + 4)
	result.fill(0.0)
	if image == null or image.is_empty():
		return result
	var w: int = image.get_width()
	var h: int = image.get_height()
	var min_x: int = w
	var max_x: int = -1
	var min_y: int = h
	var max_y: int = -1
	var cx: float = 0.0
	var cy: float = 0.0
	var count: int = 0
	for y in h:
		for x in w:
			if image.get_pixel(x, y).a < 0.5:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
			cx += float(x)
			cy += float(y)
			count += 1
	if count == 0:
		return result
	var bw: int = maxi(1, max_x - min_x + 1)
	var bh: int = maxi(1, max_y - min_y + 1)
	result[GRID * GRID] = float(bw) / float(w)
	result[GRID * GRID + 1] = float(bh) / float(h)
	result[GRID * GRID + 2] = cx / float(count * w)
	result[GRID * GRID + 3] = cy / float(count * h)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if image.get_pixel(x, y).a < 0.5:
				continue
			var ix: int = mini(GRID - 1, (x - min_x) * GRID / bw)
			var iy: int = mini(GRID - 1, (y - min_y) * GRID / bh)
			result[iy * GRID + ix] += 1.0
	# Normalize bins to occupied-cell fractions instead of image dimensions.
	for i in GRID * GRID:
		result[i] /= float(count)
	return result


static func distance(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	if a.size() != GRID * GRID + 4 or b.size() != a.size():
		return 1.0
	var shape: float = 0.0
	for i in GRID * GRID:
		shape += absf(a[i] - b[i])
	var features: float = 0.0
	for i in range(GRID * GRID, GRID * GRID + 4):
		features += absf(a[i] - b[i])
	return 0.75 * shape + 0.25 * features


static func too_similar(candidate: Image, others: Array[Dictionary], threshold: float = 0.11) -> bool:
	var current: PackedFloat32Array = signature(candidate)
	for item in others:
		if not item.has("image"):
			continue
		if distance(current, signature(item["image"])) < threshold:
			return true
	return false
