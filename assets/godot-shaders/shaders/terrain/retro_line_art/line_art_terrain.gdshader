shader_type spatial;

group_uniforms line_settings;
uniform vec3 main_color : source_color = vec3(0.0);
uniform vec3 line_color : source_color = vec3(1.0);
uniform float line_separation = 10.0;
uniform float line_thickness : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float line_spread :hint_range(0.0, 10.0, 0.01) = 0.5;
uniform bool draw_x_lines = true;
uniform bool draw_z_lines = true;


//	calculate spread for value
float get_spread(float value) {

	float reminder = mod(value, line_separation) / line_separation;

	if ((reminder > line_thickness / 2.0) && (reminder <= (1.0 - line_thickness / 2.0))) {
		return 0.0;
	}

	if (reminder > 1.0 - line_thickness / 2.0) {
		reminder = 1.0 - reminder;
	}

	reminder = reminder / (line_thickness / 2.0);
	reminder = 1.0 - reminder;
	reminder = pow(reminder, line_spread * 10.0);

	return reminder;
}

void vertex() {
}

void fragment() {

	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	float spread_x = 0.0;
	float spread_z = 0.0;

	if (draw_x_lines)
		spread_x = get_spread(pixel_world_position.x);
	if (draw_z_lines)
		spread_z = get_spread(pixel_world_position.z);

	float spread = spread_x + spread_z;
	spread = spread / 2.0;

	spread = clamp(spread, 0.0, 1.0);
	vec3 color = mix(main_color, line_color.rgb, spread);

	ALBEDO = color;
}

