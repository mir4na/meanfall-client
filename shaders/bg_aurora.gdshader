shader_type canvas_item;

uniform float speed : hint_range(0.05, 1.0) = 0.18;
uniform vec4 color_a : source_color = vec4(0.02, 0.04, 0.12, 1.0);
uniform vec4 color_b : source_color = vec4(0.15, 0.04, 0.28, 1.0);
uniform vec4 color_c : source_color = vec4(0.05, 0.08, 0.22, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	float t = TIME * speed;
	vec2 uv = UV;
	float n1 = noise(uv * 2.0 + vec2(t, t * 0.4));
	float n2 = noise(uv * 3.5 - vec2(t * 0.6, t));
	float n3 = noise(uv * 5.0 + vec2(sin(t * 0.3), cos(t * 0.5)));
	float f = n1 * 0.5 + n2 * 0.35 + n3 * 0.15;
	vec4 col = mix(color_a, color_b, smoothstep(0.3, 0.7, f));
	col = mix(col, color_c, smoothstep(0.6, 0.9, f) * 0.6);
	COLOR = col;
}
