shader_type spatial;

group_uniforms line_settings;
uniform vec3 main_color : source_color = vec3(0.0);
uniform vec3 line_color : source_color = vec3(1.0);
uniform float line_separation = 10.0;
uniform float line_thickness : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float line_spread :hint_range(0.0, 10.0, 0.01) = 0.5;
uniform bool draw_x_lines = true;
uniform bool draw_z_lines = true;
uniform bool use_aa = false;

group_uniforms emission_settings;
uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);
uniform float emission_spread_minimum : hint_range(0.0, 1.0, 0.01) = 0.0;

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

float get_spread_at(vec3 position) {
	float spread_x = 0.0;
	float spread_z = 0.0;

	if (draw_x_lines)
		spread_x = get_spread(position.x);
	if (draw_z_lines)
		spread_z = get_spread(position.z);

	float spread = spread_x + spread_z;
	spread = spread / 2.0;

	spread = clamp(spread, 0.0, 1.0);

	return spread;
}


vec3 get_color_at(vec3 position) {

	return mix(main_color, line_color.rgb, get_spread_at(position));

}


void vertex() {
}

void fragment() {

	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 color = get_color_at(pixel_world_position);

	if (use_aa) {
		float vertex_delta = line_thickness / 2.0;
		color *= 0.5;

		color += 0.125 * get_color_at(pixel_world_position + vec3(-vertex_delta, 0.0, 0.0));
		color += 0.125 * get_color_at(pixel_world_position + vec3( vertex_delta, 0.0, 0.0));
		color += 0.125 * get_color_at(pixel_world_position + vec3(0.0, 0.0,  vertex_delta));
		color += 0.125 * get_color_at(pixel_world_position + vec3(0.0, 0.0, -vertex_delta));
	}

	ALBEDO = color;


	float spread = get_spread_at(pixel_world_position);

	if (length(spread) > emission_spread_minimum) {
		// Emission: Enabled
		vec3 emission_tex = texture(texture_emission, UV).rgb;
		// Emission Operator: Add
		EMISSION = (emission.rgb + emission_tex) * emission_energy;
	}

}
