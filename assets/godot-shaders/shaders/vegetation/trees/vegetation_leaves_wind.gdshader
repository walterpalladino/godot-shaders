shader_type spatial;

render_mode unshaded, cull_back, blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

group_uniforms main;
uniform sampler2D material_texture : source_color,filter_linear_mipmap;
uniform vec2 material_scale = vec2(1.0);
uniform float alpha_cut_off : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform vec3 color : source_color;

group_uniforms gradient;
uniform vec3 gradient_color : source_color;
uniform float gradient_falloff : hint_range(0.01, 30.0, 0.01) = 5.0;


#include "res://assets/godot-shaders/shaders/includes/wind.gdshaderinc"


varying vec3 world_normal;

void vertex() {

	VERTEX = get_vertex_with_wind(INV_VIEW_MATRIX, VERTEX);
	world_normal = NORMAL;
}

void fragment() {

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
