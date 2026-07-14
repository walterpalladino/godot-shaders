shader_type canvas_item;

render_mode unshaded;


uniform float scanline_thickness : hint_range(0.1, 10.0) = 1.0; // Thickness of the lines
uniform float pixel_interval : hint_range(1.0, 100.0) = 10.0; // Interval between lines in pixels
uniform vec4 scanline_color : source_color = vec4(0.4, 0.4, 0.4, 1.0); // Color of the lines


uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


void fragment() {
	
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

	// Get the current pixel's vertical coordinate in screen space
    float y_coord = FRAGCOORD.y;

    // Calculate the remainder when dividing by the pixel_interval
    // This will create a repeating pattern
    float remainder = mod(y_coord, pixel_interval);

    // Determine if the current pixel falls within the line thickness
    // The smoothstep function creates a smooth transition for anti-aliasing
    float line_alpha = smoothstep(0.0, scanline_thickness, remainder) - smoothstep(scanline_thickness, scanline_thickness + 1.0, remainder);

    // Mix the line color and background color based on line_alpha
	vec3 color = mix(screen_color, scanline_color, line_alpha).rgb;

	//	Use color alpha value for transparency
	COLOR = vec4(color, scanline_color.a);
}