shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float from_top : hint_range(0.0, 1.0) = 1.0;
uniform vec4 color : source_color = vec4(0.04, 0.03, 0.12, 1.0);

void fragment() {
	float uv = from_top > 0.5 ? UV.y : (1.0 - UV.y);
	COLOR = vec4(color.rgb, step(uv, progress));
}
