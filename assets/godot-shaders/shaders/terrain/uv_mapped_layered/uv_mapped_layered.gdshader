shader_type spatial;

render_mode diffuse_burley;

group_uniforms general_settings;
uniform float roughness : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float specular : hint_range(0.0, 1.0, 0.1) = 0.0;


group_uniforms main_texture;
uniform sampler2D main_texture : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D main_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float main_normal_strength = 1.0;
uniform vec2 main_texture_scale = vec2(1.0);

group_uniforms layer_texture;
uniform sampler2D layer_texture : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D layer_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float layer_normal_strength = 1.0;
uniform vec2 layer_texture_scale = vec2(1.0);
uniform float layer_blend_strength : hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms layer_blend;
uniform float blend_offset : hint_range(-0.5, 0.5, 0.01) = 0.256f;
uniform float blend_exponent : hint_range(1.0, 20.0, 0.1) = 3.57f;
uniform bool blend_layered_normals = true;




void fragment() {

	vec3 normal = mat3(INV_VIEW_MATRIX) * NORMAL;

	vec3 new_color = vec3(1.0);
	vec3 new_normal = vec3(0.0);
	float new_normal_strength = 0.0;

	//	Scale the UV coordinates
	vec2 uv_layer = UV / layer_texture_scale;
	vec2 uv_main = UV / main_texture_scale;

	//	Get the texture color
	vec3 albedo_tex_layer = texture(layer_texture, uv_layer).rgb;
	vec3 normal_tex_layer = texture(layer_normal, uv_layer).rgb;

	vec3 albedo_tex_main = texture(main_texture, uv_main).rgb;
	vec3 normal_tex_main = texture(main_normal, uv_main).rgb;

	new_color = albedo_tex_main;
	new_normal = normal_tex_main ;
	new_normal_strength = main_normal_strength;

	if (normal.y > 0.0) {

		vec3 blended_normal = abs(normal);
		blended_normal -= blend_offset;
		blended_normal = clamp(blended_normal, 0.0, 1.0);
		blended_normal = vec3(pow(blended_normal.x, blend_exponent), pow(blended_normal.y, blend_exponent), pow(blended_normal.z, blend_exponent));
		blended_normal /= (blended_normal.x + blended_normal.y + blended_normal.z);

		//	Top Face
		float top_face_blend = clamp(normal.y, 0.0, 1.0) * blended_normal.y;
		top_face_blend = normal.y * blended_normal.y;

		new_color = mix(albedo_tex_main, albedo_tex_layer, top_face_blend);
		if (blend_layered_normals) {
			new_normal = mix(normal_tex_main, normal_tex_layer, top_face_blend);
			new_normal_strength = mix(main_normal_strength, layer_normal_strength, top_face_blend) ;
		}
	}
/*
	//	Calculate the blended normal to be used to assign to faces
	vec3 blended_normal = abs(normal);
	blended_normal -= blend_offset;
	blended_normal = clamp(blended_normal, 0.0, 1.0);
	blended_normal = vec3(pow(blended_normal.x, blend_exponent), pow(blended_normal.y, blend_exponent), pow(blended_normal.z, blend_exponent));
	blended_normal /= (blended_normal.x + blended_normal.y + blended_normal.z);

	//	Top Face
	float top_face_blend = clamp(normal.y, 0.0, 1.0) * blended_normal.y;
	top_face_blend = normal.y * blended_normal.y;

	//color = albedo_tex_top * top_face_blend;
	float blend = 2.0 * layer_blend_strength * top_face_blend;
	blend = clamp(blend, 0.0, 1.0);
	new_color = mix(albedo_tex_main, albedo_tex_layer, blend);

	if (!blend_layered_normals)
		new_normal = normal_tex_main * top_face_blend;
	else
		new_normal = mix(normal_tex_main, normal_tex_layer, blend);
	new_normal_strength = layer_normal_strength * top_face_blend;
*/




	//new_normal = clamp(new_normal, 0.0, 1.0);

	ALBEDO = new_color;
//new_normal = normal * new_normal;
//new_normal = clamp(new_normal, 0.0, 1.0);
//NORMAL = mat3(VIEW_MATRIX) * normal;
	NORMAL_MAP = new_normal;
	NORMAL_MAP_DEPTH = new_normal_strength;

	ROUGHNESS = roughness;

	METALLIC = 0.0;
	SPECULAR = specular;
}
