shader_type canvas_item;

uniform float glitch_strength : hint_range(0.0, 1.0) = 0.0;
uniform float scan_speed : hint_range(0.1, 5.0) = 1.5;
uniform vec4 line_color : source_color = vec4(0.45, 0.20, 1.0, 0.6);
uniform float line_density : hint_range(5.0, 100.0) = 20.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float t = TIME * scan_speed;
	float scan_y = fract(UV.y * line_density - t);
	float scan_line = smoothstep(0.92, 1.0, scan_y);
	vec2 offset = vec2(hash(floor(UV.y * 30.0) + floor(t * 10.0)) - 0.5, 0.0) * glitch_strength * 0.03;
	vec4 shifted = texture(TEXTURE, UV + offset);
	float shimmer = scan_line * line_color.a;
	COLOR = mix(shifted, line_color, shimmer);
	COLOR.a = base.a;
}
