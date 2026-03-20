shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 3.0) = 1.2;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.8;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.25;
uniform vec4 glow_color : source_color = vec4(0.45, 0.20, 1.00, 1.0);
uniform float edge_width : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge = min(edge_x, edge_y) / edge_width;
	edge = 1.0 - clamp(edge, 0.0, 1.0);
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
	float glow = edge * glow_strength * pulse;
	COLOR = mix(base, glow_color, glow * glow_color.a);
	COLOR.a = base.a;
}
