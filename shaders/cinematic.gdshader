shader_type canvas_item;

uniform float bar_height : hint_range(0.0, 0.5) = 0.0;
uniform float fade_alpha : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float y = UV.y;
	float in_bar = step(y, bar_height) + step(1.0 - bar_height, y);
	float alpha = max(in_bar, fade_alpha);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
