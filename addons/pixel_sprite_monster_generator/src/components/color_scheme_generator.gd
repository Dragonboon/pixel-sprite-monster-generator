class_name ColorSchemeGenerator

var rng: RandomNumberGenerator

func _init(random_source: RandomNumberGenerator = null) -> void:
	rng = random_source if random_source != null else RandomNumberGenerator.new()


const golden_ratio_conjugate: float = 0.618033988749895

enum ColorGenerationMethod {
	RandomRGB,
	GoldenRatioHSV
}

## Shared method dispatch for body and eye palette generation.
## Calls the original implementations, preserving RNG draw order.
func generate_palette(method: ColorGenerationMethod, count: int, saturation: float, value: float) -> PackedColorArray:
	match method:
		ColorGenerationMethod.RandomRGB:
			return generate_random_rgb_colors(count)
		_:
			return generate_random_hsv_colors(count, saturation, value)


# Using ideas from https://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
func generate_random_hsv_colors(number_of_colors: int = 12, saturation: float = 0.5, value: float = 0.95) -> PackedColorArray:
	var colors: PackedColorArray = PackedColorArray()
	
	for i in number_of_colors:
		var h = rng.randf()
		h += golden_ratio_conjugate
		h = fmod(h, 1.0)
		
		colors.append(Color.from_hsv(h, saturation, value))
		
	return colors

# Using ideas from https://www.iquilezles.org/www/articles/palettes/palettes.htm
func generate_random_rgb_colors(number_of_colors: int = 12, darkened_value: float = 0.2) -> PackedColorArray:
	var a = Vector3(rng.randf_range(0.0, 0.5), rng.randf_range(0.0, 0.5), rng.randf_range(0.0, 0.5))
	var b = Vector3(rng.randf_range(0.1, 0.6), rng.randf_range(0.1, 0.6), rng.randf_range(0.1, 0.6))
	var c = Vector3(rng.randf_range(0.15, 0.8), rng.randf_range(0.15, 0.8), rng.randf_range(0.15, 0.8))
	var d = Vector3(rng.randf_range(0.4, 0.6), rng.randf_range(0.4, 0.6), rng.randf_range(0.4, 0.6))

	var colors: PackedColorArray = PackedColorArray()
	var n: float = maxf(1.0, number_of_colors - 1.0)
	
	for i in number_of_colors:
		var vec3 = Vector3(
			(a.x + b.x * cos(TAU * (c.x * float(i / n) + d.x))) + (i / n),
			(a.y + b.y * cos(TAU * (c.y * float(i / n) + d.y))) + (i / n),
			(a.z + b.z * cos(TAU * (c.z * float(i / n) + d.z))) + (i / n)
		)
		
		colors.append(Color(vec3.x, vec3.y, vec3.z).darkened(darkened_value))

	return colors
