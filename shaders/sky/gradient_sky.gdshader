shader_type sky;

group_uniforms sky_colors;
uniform vec3 azimut_color : source_color = vec3(1.0);
uniform vec3 horizon_color : source_color = vec3(1.0);
uniform float offset_horizon : hint_range(-1.0, 1.0, 0.1) = 0.0;
uniform float horizon_intensity : hint_range(0.01, 2.0, 0.001) = 0.3;

group_uniforms sun_settings;
uniform vec4 sun_color : source_color = vec4(1.0);
uniform float sun_radius : hint_range(0.0, 2.0, 0.001) = 0.1;
uniform bool flat_sun = true;


void sky() {

	float horizon_blend = abs(EYEDIR.y / horizon_intensity) - offset_horizon;
	//mix_value = pow(EYEDIR.y * blend, 0.10);
	horizon_blend = clamp(horizon_blend, 0.0, 1.0);
	
	vec3 sky_color = vec3(1.0);

	sky_color = mix(horizon_color, azimut_color, horizon_blend);			


	// Sun
	float sun_distance = distance(EYEDIR.xyz, LIGHT0_DIRECTION);
	float sun_disc = 1.0 - clamp(sun_distance / sun_radius, 0.0, 1.0);
	
	// option to render flat sun
	if (flat_sun == true) {
		sun_disc = roundEven(sun_disc);
	}
	
	vec3 sun = (sun_disc * sun_color.rgb) ;
	
	
	sky_color += sun;

	COLOR = sky_color;

}
