shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 center = UV - 0.5;
	float dist = length(center) * 1.42;
	float cutoff = progress;
	float edge = 0.05;
	float alpha = 1.0 - smoothstep(cutoff - edge, cutoff + edge, dist);
	COLOR = vec4(color.rgb, color.a * alpha);
}
