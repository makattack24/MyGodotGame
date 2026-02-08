shader_type canvas_item;

uniform float shimmer_speed : hint_range(0.1, 5.0) = 0.7;
uniform float shimmer_width : hint_range(0.05, 0.5) = 0.18;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 shimmer_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform float pulse_speed : hint_range(0.1, 3.0) = 1.0;
uniform float pulse_amount : hint_range(0.0, 0.3) = 0.06;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Shimmer wave sweeping left to right
	float shimmer_pos = fract(TIME * shimmer_speed);
	float dist = abs(UV.x - shimmer_pos);
	// Wrap-around for seamless looping
	dist = min(dist, 1.0 - dist);
	float shimmer = smoothstep(shimmer_width, 0.0, dist);

	// Subtle overall pulse
	float pulse = sin(TIME * pulse_speed * TAU) * pulse_amount + 1.0;

	// Combine: brighten with shimmer color, apply pulse
	vec3 final_color = tex.rgb + shimmer_color.rgb * shimmer * glow_strength;
	final_color *= pulse;

	COLOR = vec4(final_color, tex.a);
}
