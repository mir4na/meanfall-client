shader_type canvas_item;

uniform float scroll_speed : hint_range(0.0, 2.0) = 0.3;
uniform float grid_size : hint_range(10.0, 120.0) = 48.0;
uniform float line_width : hint_range(0.005, 0.1) = 0.025;
uniform vec4 bg_color : source_color = vec4(0.03, 0.03, 0.07, 1.0);
uniform vec4 line_color : source_color = vec4(0.25, 0.15, 0.6, 0.35);
uniform vec4 dot_color : source_color = vec4(0.45, 0.2, 1.0, 0.6);

void fragment() {
	vec2 uv = UV;
	uv.y += TIME * scroll_speed * 0.04;
	vec2 grid = fract(uv * (1.0 / (1.0 / SCREEN_PIXEL_SIZE.x / grid_size)));
	float lx = smoothstep(line_width, 0.0, grid.x) + smoothstep(1.0 - line_width, 1.0, grid.x);
	float ly = smoothstep(line_width, 0.0, grid.y) + smoothstep(1.0 - line_width, 1.0, grid.y);
	float lines = clamp(lx + ly, 0.0, 1.0);
	float dot_r = 0.06;
	float dot = 1.0 - smoothstep(dot_r - 0.01, dot_r + 0.01, length(grid - 0.5));
	vec4 col = bg_color;
	col = mix(col, line_color, lines * line_color.a);
	col = mix(col, dot_color, dot * dot_color.a);
	COLOR = col;
}
