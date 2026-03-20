shader_type canvas_item;

uniform float flash_alpha : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.1, 0.05, 1.0);
uniform float scanline_density : hint_range(0.0, 200.0) = 80.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	float scan = sin(UV.y * scanline_density * 3.14159) * 0.5 + 0.5;
	float scanlines = 1.0 - scan * scanline_strength;
	COLOR = vec4(flash_color.rgb * scanlines, flash_color.a * flash_alpha);
}
