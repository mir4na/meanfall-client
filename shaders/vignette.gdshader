shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.55;
uniform float radius : hint_range(0.0, 2.0) = 1.2;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 center = UV - 0.5;
	float dist = length(center) * radius;
	float vignette = 1.0 - smoothstep(0.3, 1.0, dist);
	float darkness = (1.0 - vignette) * strength;
	COLOR = mix(base, vec4(vignette_color.rgb, 1.0), darkness);
}
