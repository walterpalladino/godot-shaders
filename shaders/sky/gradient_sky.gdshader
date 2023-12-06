shader_type sky;

uniform vec3 azimut : source_color = vec3(1.0);
uniform vec3 horizon : source_color = vec3(1.0);
uniform float blend : hint_range(0.01, 2.0, 0.01) = 1.0;


void sky() {

	float mix_value = EYEDIR.y / blend;
	//mix_value = pow(EYEDIR.y * blend, 0.10);
	mix_value = clamp(mix_value, 0.0, 1.0);
	
	vec3 sky_color = vec3(1.0);

	sky_color = mix(horizon, azimut, mix_value);			

	COLOR = sky_color;

}
