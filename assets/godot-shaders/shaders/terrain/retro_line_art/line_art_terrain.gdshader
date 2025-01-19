shader_type spatial;

group_uniforms line_settings;
uniform vec3 main_color : source_color = vec3(0.0);
uniform vec3 line_color : source_color = vec3(1.0);
uniform float line_separation = 10.0;
uniform float line_thickness = 0.1;
uniform float line_spread :hint_range(0.0, 10.0, 0.01) = 0.5;
uniform bool draw_x_lines = true;
uniform bool draw_z_lines = true;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	float reminder_x = mod(pixel_world_position.x, line_separation);
	float reminder_z = mod(pixel_world_position.z, line_separation);

	float spread = 0.0;

	if (reminder_x <= line_thickness && draw_x_lines) {
		float spread_x = abs(reminder_x - line_thickness / 2.0);
		spread_x = clamp(spread_x, 0.0, 1.0);
		spread_x = 1.0 - spread_x;
		spread_x = pow(spread_x, line_spread * 10.0);
		spread = spread_x ;
	}
	if (reminder_z <= line_thickness && draw_z_lines) {
		float spread_z = abs(reminder_z - line_thickness / 2.0);
		spread_z = clamp(spread_z, 0.0, 1.0);
		spread_z = 1.0 - spread_z;
		spread_z = pow(spread_z, line_spread * 10.0);
		spread += spread_z;
	}
	if (reminder_x > line_thickness && reminder_z > line_thickness) {
		spread = 0.0;
	}

	spread = clamp(spread, 0.0, 1.0);
	vec3 color = mix(main_color, line_color.rgb, spread);

	ALBEDO = color;

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
