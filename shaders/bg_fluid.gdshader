shader_type canvas_item;

uniform float speed : hint_range(0.1, 3.0) = 0.8;
uniform float warp_amount : hint_range(0.0, 0.6) = 0.22;
uniform vec4 color_dark : source_color = vec4(0.0, 0.02, 0.06, 1.0);
uniform vec4 color_mid : source_color = vec4(0.0, 0.08, 0.20, 1.0);
uniform vec4 color_bright : source_color = vec4(0.05, 0.18, 0.35, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(311.7, 127.1))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float t = TIME * speed;
	vec2 uv = UV;
	vec2 warp = vec2(
		noise(uv * 2.5 + vec2(t * 0.3, 0.0)) - 0.5,
		noise(uv * 2.5 + vec2(0.0, t * 0.25)) - 0.5
	) * warp_amount;
	vec2 warped = uv + warp;
	float n = noise(warped * 4.0 + vec2(t * 0.15));
	n = n * 0.6 + noise(warped * 8.0 - vec2(t * 0.1)) * 0.4;
	vec4 col = mix(color_dark, color_mid, smoothstep(0.3, 0.65, n));
	col = mix(col, color_bright, smoothstep(0.65, 0.88, n));
	COLOR = col;
}
