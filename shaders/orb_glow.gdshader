shader_type canvas_item;

uniform vec4 orb_color : source_color = vec4(0.5, 0.1, 0.9, 1.0);
uniform float softness : hint_range(0.1, 1.0) = 0.55;
uniform float pulse_speed : hint_range(0.0, 3.0) = 0.7;
uniform float pulse_amount : hint_range(0.0, 0.3) = 0.08;

void fragment() {
	vec2 center = UV - 0.5;
	float dist = length(center) * 2.0;
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
	float alpha = 1.0 - smoothstep(0.0, softness * pulse, dist);
	alpha = alpha * alpha;
	COLOR = vec4(orb_color.rgb, orb_color.a * alpha);
}
