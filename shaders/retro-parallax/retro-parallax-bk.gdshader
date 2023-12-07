shader_type spatial;

group_uniforms screen;
uniform float screen_scale = 4.0;

group_uniforms sky_colors;
uniform vec3 azimut_color : source_color = vec3(1.0);
uniform vec3 horizon_color : source_color = vec3(1.0);
uniform float offset_horizon : hint_range(-1.0, 1.0, 0.1) = 0.0;

//	Get color intensity (at pointgray scale)
float get_intensity(vec3 color)
{
	return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
}

void fragment() {
	/*
	//	Real viewport size as pixels
	vec2 viewport_size = VIEWPORT_SIZE;
	//	Scaled viewport size as pixels
//	ivec2 pixel_scaled = ivec2(viewport_size / screen_scale);

	ivec2 pixel = ivec2( VIEWPORT_SIZE * UV );
	ivec2 pixel_scaled = ivec2(VIEWPORT_SIZE * UV / screen_scale);

	ivec2 pixel_test = ivec2(0, 0);
	if (mod(float(pixel_scaled.y), 2.0) == 0.0) {
		if (mod(float(pixel_scaled.x), 2.0) == 0.0) {
			pixel_test += ivec2(1, 0);
			//ALBEDO = horizon_color;
		} else {
			pixel_test += ivec2(0, 1);
		//	ALBEDO = azimut_color;
		}
	} else {
		if (mod(float(pixel_scaled.x), 2.0) == 0.0) {
	//		ALBEDO = azimut_color;
			pixel_test += ivec2(0, 1);
		} else {
//			ALBEDO = horizon_color;
			pixel_test += ivec2(1, 0);
		}
	}
	vec2 scaled_uv = vec2(pixel_test) * UV;
*/
	vec2 scaled_uv = UV;

	float blend = clamp(scaled_uv.y - offset_horizon, 0.0, 1.0);
	vec3 color = mix(horizon_color, azimut_color, blend);

 	ALBEDO = color;
}
