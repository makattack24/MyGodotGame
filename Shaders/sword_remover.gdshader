shader_type canvas_item;

// The color of the sword to remove (adjust RGB values to match your sword)
uniform vec3 target_color : source_color = vec3(0.7, 0.7, 0.7); // Light gray default
uniform float tolerance : hint_range(0.0, 1.0) = 0.1; // How close colors need to be

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Calculate color difference
	float diff = distance(tex_color.rgb, target_color);
	
	// If color matches the sword color (within tolerance), make it transparent
	if (diff < tolerance && tex_color.a > 0.5) {
		COLOR.a = 0.0; // Make transparent
	} else {
		COLOR = tex_color;
	}
}
