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


uniform float shade_tweak = 0.5;
uniform float light_tweak = 1.0;
uniform float sharpness = 1.0;
uniform float scale = 2.0;

const mat4 dither = mat4(
	vec4(0.0, 0.5333333333, 0.1333333333,  0.6666666667),
	vec4(0.8, 0.2666666667, 0.9333333333,  0.4),
	vec4(0.2, 0.7333333333, 0.06666666667, 0.6),
	vec4(1.0, 0.4666666667, 0.8666666667,  0.3333333333)
);

float sample(vec2 coord, float alpha, float shade, float lit) {
	int x = int(mod(coord.x, 4));
	int y = int(mod(coord.y, 4));
	if (y == 0) {
		if (x == 0 && dither[0][0] >= alpha) {
			return shade;
		} else if (x == 1 && dither[0][1] >= alpha) {
			return shade;
		} else if (x == 2 && dither[0][2] >= alpha) {
			return shade;
		} else if (x == 3 && dither[0][3] >= alpha) {
			return shade;
		}
	} else if (y == 1) {
		if (x == 0 && dither[1][0] >= alpha) {
			return shade;
		} else if (x == 1 && dither[1][1] >= alpha) {
			return shade;
		} else if (x == 2 && dither[1][2] >= alpha) {
			return shade;
		} else if (x == 3 && dither[1][3] >= alpha) {
			return shade;
		}
	} else if (y == 2) {
		if (x == 0 && dither[2][0] >= alpha) {
			return shade;
		} else if (x == 1 && dither[2][1] >= alpha) {
			return shade;
		} else if (x == 2 && dither[2][2] >= alpha) {
			return shade;
		} else if (x == 3 && dither[2][3] >= alpha) {
			return shade;
		}
	} else if (y == 3) {
		if (x == 0 && dither[3][0] >= alpha) {
			return shade;
		} else if (x == 1 && dither[3][1] >= alpha) {
			return shade;
		} else if (x == 2 && dither[3][2] >= alpha) {
			return shade;
		} else if (x == 3 && dither[3][3] >= alpha) {
			return shade;
		}
	}
	return lit;
}

void sky() {

	float f = 1.0; //	ATTENUATION
	float a = sample(
		FRAGCOORD.xy * (1.0 / scale),
		//EYEDIR.y ,
		clamp(EYEDIR.y + sharpness, 0.0, 1.0) * f,
		shade_tweak,
		light_tweak);

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

		sky_color *= a;

		COLOR = sky_color;

	} else {

		vec3 under_horizon_color = vec3(1.0);
		float under_horizon_blend = 2.0 * pow(1.0 - horizon_blend, 10.0);
		under_horizon_blend = clamp(under_horizon_blend, 0.0, 1.0);
		under_horizon_color = mix(ground_color, horizon_color, under_horizon_blend);
		COLOR = under_horizon_color;

	}



}
