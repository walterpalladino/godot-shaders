shader_type sky;

group_uniforms sky_colors;
uniform vec3 azimut_color : source_color = vec3(1.0);
uniform vec3 horizon_color : source_color = vec3(1.0);
uniform float offset_horizon : hint_range(-1.0, 1.0, 0.1) = 0.0;
uniform float horizon_intensity : hint_range(0.01, 2.0, 0.001) = 0.3;

group_uniforms ground_color;
uniform vec3 ground_color : source_color = vec3(1.0);

group_uniforms sun_settings;
uniform vec4 sun_color : source_color = vec4(1.0);
uniform float sun_radius : hint_range(0.0, 2.0, 0.001) = 0.1;
uniform bool flat_sun = true;



void sky() {

	float horizon_blend = abs(EYEDIR.y / horizon_intensity) - offset_horizon;
	horizon_blend = clamp(horizon_blend, 0.0, 1.0);

	if (EYEDIR.y / horizon_intensity >= 0.0) {

		vec3 sky_color = vec3(1.0);
		sky_color = mix(horizon_color, azimut_color, horizon_blend);

		// Sun
		float sun_distance = distance(EYEDIR.xyz, LIGHT0_DIRECTION);
		float sun_disc = 1.0 - clamp(sun_distance / sun_radius, 0.0, 1.0);

		// option to render flat sun
		if (flat_sun == true) {
			sun_disc = roundEven(sun_disc);
		} else {
			sun_disc = 10.0 * pow(sun_disc, 2.5);
			sun_disc = clamp(sun_disc, 0.0, 1.0);
		}
		vec3 sun = mix(sky_color, sun_color.rgb, sun_disc) ;

		if (dot(sun, vec3(1.0)) > 0.0) {

			sky_color = sun;

		} else {

		}


		COLOR = sky_color;

	} else {

		vec3 under_horizon_color = vec3(1.0);
		float under_horizon_blend = 2.0 * pow(1.0 - horizon_blend, 10.0);
		under_horizon_blend = clamp(under_horizon_blend, 0.0, 1.0);
		under_horizon_color = mix(ground_color, horizon_color, under_horizon_blend);
		COLOR = under_horizon_color;

	}



}
