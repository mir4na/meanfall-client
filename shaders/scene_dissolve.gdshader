shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
		f.y);
}

void fragment() {
	float n = noise(UV * 6.0) * 0.5 + noise(UV * 12.0) * 0.5;
	float threshold = mix(-0.05, 1.05, progress);
	float alpha = 1.0 - smoothstep(threshold - 0.08, threshold + 0.08, n);
	alpha *= smoothstep(0.0, 0.02, progress);
	alpha = max(alpha, smoothstep(0.98, 1.0, progress));
	COLOR = vec4(wipe_color.rgb, wipe_color.a * clamp(alpha, 0.0, 1.0));
}
