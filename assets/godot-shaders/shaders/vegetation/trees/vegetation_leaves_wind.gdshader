shader_type spatial;

render_mode cull_back, blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

group_uniforms main;
uniform sampler2D material_texture : source_color,filter_linear_mipmap;
uniform vec2 material_scale = vec2(1.0);
uniform float alpha_cut_off : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform vec3 color : source_color;

group_uniforms gradient;
uniform vec3 gradient_color : source_color;
uniform float gradient_falloff : hint_range(0.01, 50.0, 0.01) = 5.0;
uniform float gradient_min_height : hint_range(-10.0, 10.0, 0.01) = 1.0f;
uniform float gradient_max_height : hint_range(0.0, 20.0, 0.01) = 5.0f;


#include "res://assets/godot-shaders/shaders/includes/wind.gdshaderinc"


varying float vertical_factor;


void vertex() {

	VERTEX = get_vertex_with_wind(INV_VIEW_MATRIX, VERTEX);

}

void fragment() {

	vec2 uv = UV * material_scale;
	vec4 texture_color = texture(material_texture, uv * material_scale);

	float color_blend = 0.0;
	if ((gradient_max_height > gradient_min_height) && (VERTEX.y >= gradient_min_height)) {
		color_blend = (VERTEX.y - gradient_min_height) / (gradient_max_height - gradient_min_height);
	}
	color_blend = pow(color_blend, gradient_falloff);
	color_blend = clamp(color_blend, 0.0, 1.0);
	vec3 leaves_color = mix(color, gradient_color, color_blend) ;

	ALBEDO = leaves_color * texture_color.rgb;

	ALPHA = texture_color.a ;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut_off;
}
