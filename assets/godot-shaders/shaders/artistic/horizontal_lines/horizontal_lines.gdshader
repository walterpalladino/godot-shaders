shader_type spatial;

render_mode unshaded, depth_draw_opaque;


uniform float line_thickness : hint_range(0.1, 10.0) = 1.0; // Thickness of the lines
uniform float pixel_interval : hint_range(1.0, 100.0) = 10.0; // Interval between lines in pixels
uniform vec4 line_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Color of the lines



uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

	// Get the current pixel's vertical coordinate in screen space
    float y_coord = FRAGCOORD.y;

    // Calculate the remainder when dividing by the pixel_interval
    // This will create a repeating pattern
    float remainder = mod(y_coord, pixel_interval);

    // Determine if the current pixel falls within the line thickness
    // The smoothstep function creates a smooth transition for anti-aliasing
    float line_alpha = smoothstep(0.0, line_thickness, remainder) - smoothstep(line_thickness, line_thickness + 1.0, remainder);

    // Mix the line color and background color based on line_alpha
    //COLOR = mix(background_color, line_color, line_alpha);

	vec3 color = mix(screen_color, line_color, line_alpha).rgb;

	ALBEDO = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
