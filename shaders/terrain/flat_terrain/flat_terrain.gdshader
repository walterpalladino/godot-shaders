shader_type spatial;

render_mode diffuse_burley;

group_uniforms top_texture;
uniform sampler2D top_texture : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D top_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform vec2 top_texture_scale = vec2(1.0);
uniform float top_texture_normal_strength : hint_range(0.0, 4.0, 0.01) = 1.0;

group_uniforms top_mix_texture;
uniform sampler2D top_mix_texture : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D top_mix_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform vec2 top_mix_texture_scale = vec2(1.0);
uniform float top_texture_mix_normal_strength : hint_range(0.0, 4.0, 0.01) = 1.0;

uniform float top_texture_mix_strength : hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms general;
uniform float roughness : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float specular : hint_range(0.0, 1.0, 0.1) = 0.0;

#include "res://shaders/includes/noise.gdshaderinc"


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 normal = mat3(INV_VIEW_MATRIX) * NORMAL;

		//	Calculate the UV coordinate based on the world position and texture scale
	vec2 uv_projected_coordinate = pixel_world_position.xz;

	vec2 uv = uv_projected_coordinate / top_texture_scale;
	vec2 uv_mix = uv_projected_coordinate / top_mix_texture_scale;

	float noise = get_noise(scale * vec3(uv_projected_coordinate * 0.01, seed)).g;
	//noise = step(noise, top_texture_mix_strength);
	noise = smoothstep(noise * 0.95, noise * 1.05, top_texture_mix_strength);
	noise = clamp(noise, 0.0, 1.0);

	//	Get the texture color
	vec3 albedo_tex_top = texture(top_texture, uv).rgb;
	vec3 normal_tex_top = texture(top_normal, uv).rgb;

	vec3 albedo_tex_mix_top = texture(top_mix_texture, uv_mix).rgb;
	vec3 normal_tex_mix_top = texture(top_mix_normal, uv_mix).rgb;

	ALBEDO = mix(albedo_tex_top, albedo_tex_mix_top, noise) ;
	//ALBEDO = vec3(noise);
	//ALBEDO = mix(normal_tex_top, normal_tex_mix_top, noise) ;

	NORMAL_MAP = mix(normal_tex_top, normal_tex_mix_top, noise) ;
	NORMAL_MAP_DEPTH = mix(top_texture_normal_strength, top_texture_mix_strength, noise) ;

	ROUGHNESS = roughness;

	METALLIC = 0.0;
	SPECULAR = specular;

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
