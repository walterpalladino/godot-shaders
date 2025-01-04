

group_uniforms wind;
uniform float wind_min_height : hint_range(0.0, 5.0, 0.01) = 1.0f;
uniform float wind_max_height : hint_range(0.0, 10.0, 0.01) = 5.0f;
uniform sampler2D wind_noise_texture : filter_linear_mipmap,repeat_enable;
uniform vec2 wind_strength = vec2(1.0);
uniform	float wind_swag = 25.0;
uniform	float wind_noise_scale = 1.0;


vec3 get_wind_at(mat4 inv_view_matrix, vec3 vertex) {

	//	Will get the noise based on the vertex world position
	vec3 position = vertex;
	vec3 vertex_world_position = (inv_view_matrix * vec4(vertex, 1.0)).xyz;

	vec2 wind_noise_uv = (vertex_world_position.xz * wind_noise_scale + TIME / 1000.0 * wind_swag) ;
	float wind_noise_value = texture(wind_noise_texture, wind_noise_uv).r;
	wind_noise_value -= 0.5;

	position.x += wind_noise_value * wind_strength.x ;
	position.z += wind_noise_value * wind_strength.y ;

	return position;
}

float get_wind_factor_at(vec3 vertex) {

	float factor = 0.0;
	if ((wind_max_height > wind_min_height) && (vertex.y >= wind_min_height)) {
		factor = (vertex.y - wind_min_height) / (wind_max_height - wind_min_height);
	}
	factor = clamp(factor, 0.0, 1.0);

	return factor;
}