shader_type spatial;

render_mode depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

group_uniforms main;
uniform vec3 main_color : source_color = vec3(1.0);
uniform sampler2D main_texture : source_color,filter_linear_mipmap;
uniform sampler2D main_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform vec2 material_scale = vec2(1.0);
uniform float main_normal_strength : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float alpha_cut_off : hint_range(0.0, 1.0) = 0.5;
uniform float alpha_hidden_power : hint_range(0.0, 10.0) = 2.5;

group_uniforms deposit;
uniform vec3 deposit_color : source_color = vec3(1.0);
uniform sampler2D deposit_texture : source_color,filter_linear_mipmap;
uniform sampler2D deposit_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform vec2 deposit_scale = vec2(1.0);
uniform float deposit_normal_strength : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float deposit_falloff : hint_range(0.01, 50.0, 0.01) = 5.0;
uniform float min_height : hint_range(-5.0, 5.0, 0.01) = 0.0f;
uniform float max_height : hint_range(0.0, 10.0, 0.01) = 5.0f;
//uniform sampler2D wind_noise_texture;

varying float deposit_factor;

//#include "res://assets/godot-shaders/shaders/includes/wind.gdshaderinc"
group_uniforms wind;
uniform vec2 wind_strength = vec2(0.0);
uniform float wind_frequency = 0.0f;
uniform float wind_min_height : hint_range(0.0, 5.0, 0.1) = 1.0f;
uniform float wind_max_height : hint_range(0.0, 10.0, 0.1) = 5.0f;


void vertex() {

	//	VERTEX = get_vertex_with_wind(INV_VIEW_MATRIX, VERTEX);
	//	Will get the noise based on the vertex world position
	vec3 vertex_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 position = VERTEX;

//	position.x += wind_strength.x * sin(TIME * wind_frequency) * (1.0 - UV.y);
//	position.z += wind_strength.y * cos(TIME * wind_frequency) * (1.0 - UV.y);
	position.x += wind_strength.x * sin(TIME * wind_frequency) ;
	position.z += wind_strength.y * cos(TIME * wind_frequency) ;

	//	How much will affect based on height
	float factor = 0.0;
	if ((wind_max_height > wind_min_height) && (VERTEX.y >= wind_min_height)) {
		factor = (VERTEX.y - wind_min_height) / (wind_max_height - wind_min_height);
	}
	factor = clamp(factor, 0.0, 1.0);

	VERTEX = mix(VERTEX, position, factor);

	//	How much will affect deposit based on height
	deposit_factor = 0.0;
	if ((max_height > min_height) && (VERTEX.y >= min_height)) {
		deposit_factor = (VERTEX.y - min_height) / (max_height - min_height);
	}
	deposit_factor = clamp(deposit_factor, 0.0, 1.0);

}

void fragment() {

	vec2 uv = UV * material_scale;
	vec3 color = texture(main_texture, uv).rgb * main_color;
	vec3 normal = texture(main_normal, uv).rgb * main_normal_strength;
	normal = clamp(normal, 0.0, 1.0);

	vec2 deposit_uv = UV * deposit_scale;
	vec3 deposit_color_ = texture(deposit_texture, deposit_uv).rgb * deposit_color;
	vec3 deposit_normal_ = texture(deposit_normal, deposit_uv).rgb * deposit_normal_strength;
	deposit_normal_ = clamp(deposit_normal_, 0.0, 1.0);

	float color_blend = 1.0 - deposit_factor;
	color_blend = pow(color_blend * 2.0, deposit_falloff);
	color_blend= clamp(color_blend, 0.0, 1.0);

	vec3 trunk_color = mix(color, deposit_color_, color_blend) ;
	vec3 trunk_normal = (normal + deposit_normal_) / 2.0 ;


	ALBEDO = trunk_color ;
	//ALBEDO = vec3(color_blend);
	NORMAL_MAP = trunk_normal;
	//NORMAL_MAP_DEPTH = 1.0;

}
