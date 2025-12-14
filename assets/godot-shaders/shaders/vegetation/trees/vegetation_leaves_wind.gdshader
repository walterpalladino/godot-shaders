shader_type spatial;

render_mode unshaded, cull_disabled, blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

group_uniforms main;
uniform sampler2D material_texture : source_color,filter_linear_mipmap;
uniform vec2 material_scale = vec2(1.0);
uniform float alpha_cut_off : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform vec3 color : source_color;

uniform bool draw_back_faces = false;

group_uniforms gradient;
uniform vec3 gradient_color : source_color;
uniform float gradient_falloff : hint_range(0.01, 30.0, 0.01) = 5.0;


//#include "res://assets/godot-shaders/shaders/includes/wind.gdshaderinc"
group_uniforms wind;
uniform vec2 wind_strength = vec2(0.0);
uniform float wind_frequency = 0.0f;
uniform float wind_min_height : hint_range(0.0, 5.0, 0.1) = 1.0f;
uniform float wind_max_height : hint_range(0.0, 10.0, 0.1) = 5.0f;

//	Add swag noise
uniform sampler2D noise_texture;


varying vec3 world_normal;

void vertex() {

	//	Will get the noise based on the vertex world position
	vec3 vertex_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 position = VERTEX;

	position.x += wind_strength.x * sin(TIME * wind_frequency) ;
	position.z += wind_strength.y * cos(TIME * wind_frequency) ;

	//	Adds swag
	vec2 uv = TIME * wind_frequency / 100.0 + vec2( vertex_world_position.x, vertex_world_position.z) ;
	float noise = texture(noise_texture, uv).r;
	noise = (noise - 0.5) * 2.0 ;
	position.x += noise * wind_strength.x * 5.0;
	position.z += noise * wind_strength.y * 5.0 ;

	//	How much will affect based on height
	float factor = 0.0;
	if ((wind_max_height > wind_min_height) && (VERTEX.y >= wind_min_height)) {
		factor = (VERTEX.y - wind_min_height) / (wind_max_height - wind_min_height);
	}
	factor = clamp(factor, 0.0, 1.0);

	VERTEX = mix(VERTEX, position, factor);

	world_normal = NORMAL;
}

void fragment() {

	if (FRONT_FACING || draw_back_faces) {

		float normal_dot = dot(world_normal, vec3(0.0,1.0,0.0)) ;

		vec2 uv = UV * material_scale;
		vec4 texture_color = texture(material_texture, uv * material_scale);

		float color_blend = 0.0;
		color_blend = normal_dot * 0.5 + 0.5 ;// from -1 to 1 to 0 to 1
		color_blend = pow(color_blend, 30.0 - gradient_falloff);
		color_blend = clamp(color_blend, 0.0, 1.0);

		vec3 leaves_color = mix(color, gradient_color, color_blend) ;

		ALBEDO = leaves_color * texture_color.rgb;

		ALPHA = texture_color.a ;
		ALPHA_SCISSOR_THRESHOLD = alpha_cut_off;
	
	}
	else {
		ALPHA = 0.0;
	}

}
