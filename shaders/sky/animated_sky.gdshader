shader_type sky;

group_uniforms sky_colors;
uniform vec3 azimut_color : source_color = vec3(1.0);
uniform vec3 horizon_color : source_color = vec3(1.0);
uniform float offset_horizon : hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float horizon_intensity : hint_range(0.01, 2.0, 0.001) = 0.3;

group_uniforms ground_color;
uniform vec3 ground_color : source_color = vec3(1.0);

group_uniforms sun_settings;
uniform vec4 sun_color : source_color = vec4(1.0);
uniform float sun_radius : hint_range(0.0, 2.0, 0.001) = 0.1;
uniform bool flat_sun = true;


group_uniforms clouds;

uniform float clouds_general_intensity : hint_range(0.0, 5.0, 0.01) = 1.0;

uniform sampler2D clouds_top : hint_default_black;
uniform float clouds_top_speed : hint_range( 0.0, 20.0, 0.01 ) = 2.0;
uniform float clouds_top_scale = 1.0;
uniform float clouds_top_direction : hint_range( -0.5, 0.5, 0.0 ) = 0.2;
uniform float clouds_top_intensity : hint_range(0.0, 1.0, 0.01) = 0.5;

uniform sampler2D clouds_mid : hint_default_black;
uniform float clouds_mid_speed : hint_range( 0.0, 20.0, 0.01 ) = 2.0;
uniform float clouds_mid_scale = 1.0;
uniform float clouds_mid_direction : hint_range( -0.5, 0.5, 0.0 ) = 0.2;
uniform float clouds_mid_intensity : hint_range(0.0, 1.0, 0.01) = 0.5;


vec3 calculate_cloud_color(vec2 sky_uv, float clouds_speed, float clouds_direction, sampler2D clouds_texture, float clouds_scale, float clouds_intensity) {

	float clouds_cluster_speed = TIME * clouds_speed * 0.01;
	float sin_x = sin( clouds_direction * PI * 2.0 );
	float cos_y = cos( clouds_direction * PI * 2.0 );

	vec2 clouds_movement = vec2( sin_x, cos_y ) * clouds_cluster_speed;

	vec3 clouds_cluster_color = texture(clouds_texture, sky_uv / clouds_scale + clouds_movement).rgb;
	clouds_cluster_color *= clouds_intensity;

	return clouds_cluster_color;
}


void sky() {


	//float eyedir_y = abs( sin( EYEDIR.y * PI * 0.5 ));

	float horizon_blend = abs(EYEDIR.y / horizon_intensity) - offset_horizon;
	horizon_blend = clamp(horizon_blend, 0.0, 1.0);

	if (EYEDIR.y / horizon_intensity >= 0.0) {

		vec3 sky_color = vec3(1.0);
		sky_color = mix(horizon_color, azimut_color, horizon_blend);

		COLOR = sky_color;

		//	Light0 is used to follow the sun if exists
		if( LIGHT0_ENABLED ) {

			// Sun
			float sun_distance = distance(EYEDIR.xyz, LIGHT0_DIRECTION);
			// Bigger sun near the horizon
			float sun_size = sun_radius + cos( LIGHT0_DIRECTION.y * PI ) * sun_radius * 0.25;
			float sun_disc = 1.0 - clamp(sun_distance / sun_size, 0.0, 1.0);

			// option to render flat sun
			if (flat_sun == true) {
				sun_disc = roundEven(sun_disc);
			} else {
				sun_disc = 10.0 * pow(sun_disc, 2.5);
				sun_disc = clamp(sun_disc, 0.0, 1.0);
			}
			vec3 sun = mix(sky_color, sun_color.rgb, sun_disc) ;

			if (dot(sun, vec3(1.0)) > 0.0) {
				COLOR = sun;
			}
		}

	} else {

		vec3 under_horizon_color = ground_color;
		float under_horizon_blend = 200.5 * pow(horizon_blend, 2.0);
		under_horizon_blend = clamp(under_horizon_blend, 0.0, 1.0);
		under_horizon_color = mix(horizon_color, ground_color, under_horizon_blend);
		COLOR = under_horizon_color;
		//COLOR = vec3(under_horizon_blend);

	}

	//	Clouds
	if (clouds_general_intensity > 0.0) {

		vec2 sky_uv = EYEDIR.xz / sqrt( EYEDIR.y );

		//	Clouds
		vec3 clouds_color = calculate_cloud_color(sky_uv,clouds_top_speed,clouds_top_direction,clouds_top, clouds_top_scale, clouds_top_intensity);
		clouds_color += calculate_cloud_color(sky_uv,clouds_mid_speed,clouds_mid_direction,clouds_mid,clouds_mid_scale,clouds_mid_intensity);
		//	Reduce impact of clouds on horizon
		clouds_color *= clouds_general_intensity * abs( EYEDIR.y ) ;

		COLOR = COLOR + clouds_color;

	}

}
