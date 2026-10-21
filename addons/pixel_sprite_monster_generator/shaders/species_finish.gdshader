shader_type canvas_item;
render_mode unshaded;

// Native-resolution, nearest-filtered alpha-edge lighting only.
// No Y-based thresholds, blurry samples, screen-space artifacts or sprite bleed.
uniform float finish_strength : hint_range(0.0, 1.0) = 0.7;

float alpha_at(vec2 uv) {
	return texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0))).a;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	if (base.a < 0.5) {
		COLOR = vec4(0.0);
	} else {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float upper = alpha_at(UV - vec2(0.0, px.y));
		float lower = alpha_at(UV + vec2(0.0, px.y));
		float left_side = alpha_at(UV - vec2(px.x, 0.0));
		float right_side = alpha_at(UV + vec2(px.x, 0.0));
		float rim = (2.0 - upper - left_side) * 0.09 * finish_strength;
		float occlusion = (2.0 - lower - right_side) * 0.07 * finish_strength;
		vec3 lit = mix(base.rgb, vec3(1.0), clamp(rim, 0.0, 1.0));
		lit *= 1.0 - clamp(occlusion, 0.0, 1.0);
		COLOR = vec4(lit, base.a);
	}
}
