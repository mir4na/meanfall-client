shader_type canvas_item;

uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform vec4 color_a : source_color = vec4(0.08, 0.04, 0.22, 1.0);
uniform vec4 color_b : source_color = vec4(0.02, 0.01, 0.10, 1.0);
uniform float noise_strength : hint_range(0.0, 0.15) = 0.04;
uniform float grain_speed : hint_range(0.0, 10.0) = 3.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	float t = TIME * time_scale;
	vec2 uv = UV;

	float n1 = noise(uv * 3.0 + vec2(t * 0.12, t * 0.08));
	float n2 = noise(uv * 6.0 - vec2(t * 0.09, t * 0.14));
	float n = n1 * 0.6 + n2 * 0.4;

	float grain = hash(uv + vec2(fract(t * grain_speed)));
	n = clamp(n + (grain - 0.5) * noise_strength, 0.0, 1.0);

	COLOR = mix(color_b, color_a, n);
}
