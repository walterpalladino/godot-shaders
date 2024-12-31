shader_type spatial;

render_mode cull_back, blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

group_uniforms main;
uniform sampler2D material_texture : source_color,filter_linear_mipmap;
uniform vec2 material_scale = vec2(1.0);
uniform float alpha_cut_off : hint_range(0.0, 1.0) = 0.5;
uniform float alpha_hidden_power : hint_range(0.0, 10.0) = 2.5;
uniform vec3 color : source_color;

group_uniforms gradient;
uniform vec3 gradient_color : source_color;
uniform float gradient_falloff : hint_range(0.01, 50.0, 0.01) = 5.0;
uniform float gradient_min_height : hint_range(0.0, 5.0, 0.1) = 1.0f;
uniform float gradient_max_height : hint_range(0.0, 10.0, 0.1) = 5.0f;


group_uniforms wind;
uniform float min_height : hint_range(0.0, 5.0, 0.1) = 1.0f;
uniform float max_height : hint_range(0.0, 10.0, 0.1) = 5.0f;
uniform sampler2D wind_noise_texture : filter_linear_mipmap,repeat_enable;
uniform vec2 wind_strength = vec2(1.0);
uniform	float wind_swag = 25.0;
uniform	float wind_noise_scale = 1.0;


varying float vertical_factor;


void vertex() {

	//	Will get the noise based on the vertex world position
	vec3 position = VERTEX;
	vec3 vertex_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 wind_noise_uv = (vertex_world_position.xz * wind_noise_scale + TIME / 1000.0 * wind_swag) ;
	float wind_noise_value = texture(wind_noise_texture, wind_noise_uv).r;
	wind_noise_value -= 0.5;

	position.x += wind_noise_value * wind_strength.x ;
	position.z += wind_noise_value * wind_strength.y ;

	//	How much will affect based on height
	vertical_factor = 0.0;
	if ((max_height > min_height) && (VERTEX.y >= min_height)) {
		vertical_factor = (VERTEX.y - min_height) / (max_height - min_height);
	}
	vertical_factor = clamp(vertical_factor, 0.0, 1.0);

	VERTEX = mix(VERTEX, position, vertical_factor);

}

void fragment() {

	vec2 uv = UV * material_scale;
	vec4 texture_color = texture(material_texture, uv);

	float color_blend = 0.0;
	if ((max_height > gradient_min_height) && (VERTEX.y >= gradient_min_height)) {
		color_blend = (VERTEX.y - gradient_min_height) / (gradient_max_height - gradient_min_height);
	}
	color_blend = pow(color_blend, gradient_falloff);
	color_blend = clamp(color_blend, 0.0, 1.0);
	vec3 leaves_color = mix(color, gradient_color, color_blend) ;

	ALBEDO = leaves_color * texture_color.rgb;

	float alpha_factor = dot(NORMAL, vec3(0,0,1)) ;
	alpha_factor = pow(alpha_factor, alpha_hidden_power) * 5.0;
	alpha_factor = clamp( alpha_factor, 0.0, 1.0);

	ALPHA = texture_color.a ;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut_off;
}
