shader_type spatial;

render_mode diffuse_burley;


group_uniforms top_texture;
uniform sampler2D top_texture : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D top_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform vec2 top_texture_scale = vec2(1.0);
uniform float normal_strength = 1.0;

group_uniforms bottom_texture;
uniform sampler2D bottom_texture : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D bottom_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform vec2 bottom_texture_scale = vec2(1.0);

group_uniforms side_texture;
uniform sampler2D side_texture : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D side_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform vec2 side_texture_scale = vec2(1.0);

group_uniforms blend;
uniform float blend_offset : hint_range(-0.5, 0.5, 0.01) = 0.256f;
uniform float blend_exponent : hint_range(1.0, 20.0, 0.1) = 3.57f;

group_uniforms general;
uniform float roughness : hint_range(0.0, 1.0, 0.1) = 1.0;



void fragment() {

	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 normal = mat3(INV_VIEW_MATRIX) * NORMAL;

	vec3 color = vec3(1.0);
	vec3 new_normal = vec3(0.0);


	//	Calculate the blended normal to be used to assign to faces
	vec3 blended_normal = abs(normal);
	blended_normal -= blend_offset;
	blended_normal = clamp(blended_normal, 0.0, 1.0);
	blended_normal = vec3(pow(blended_normal.x, blend_exponent), pow(blended_normal.y, blend_exponent), pow(blended_normal.z, blend_exponent));
	blended_normal /= (blended_normal.x + blended_normal.y + blended_normal.z);

	//	Top Face
	float top_face_blend = clamp(normal.y, 0.0, 1.0) * blended_normal.y;

	//	Calculate the UV coordinate based on the world position and texture scale
	vec2 uv_projected_coordinate = pixel_world_position.xz;
	vec2 uv = uv_projected_coordinate / top_texture_scale;

	//	Get the texture color
	vec3 albedo_tex_top = texture(top_texture, uv).rgb;
	vec3 normal_tex_top = texture(top_normal, uv).rgb;

	color = albedo_tex_top * top_face_blend;
	new_normal = normal_tex_top * top_face_blend;


	//	Bottom Face
	float bottom_face_blend = clamp(-normal.y, 0.0, 1.0) * blended_normal.y;

	//	Calculate the UV coordinate based on the world position and texture scale
	uv_projected_coordinate = pixel_world_position.xz;
	uv = uv_projected_coordinate / bottom_texture_scale;

	//	Get the texture color
	vec3 albedo_tex_bottom = texture(bottom_texture, uv).rgb;
	vec3 normal_tex_bottom = texture(bottom_normal, uv).rgb;

	color += albedo_tex_bottom * bottom_face_blend;
	new_normal += normal_tex_bottom * bottom_face_blend;


	//	Sides
	//	Face X
	float side_x_face_blend = clamp(abs(normal.x), 0.0, 1.0) * blended_normal.x;

	//	Calculate the UV coordinate based on the world position and texture scale
	uv_projected_coordinate = pixel_world_position.zy;
	uv = uv_projected_coordinate / side_texture_scale;

	//	Get the texture color
	vec3 albedo_tex_side_x = texture(side_texture, uv).rgb;
	vec3 normal_tex_side_x = texture(side_normal, uv).rgb;

	color += albedo_tex_side_x * side_x_face_blend;
	new_normal += normal_tex_side_x * side_x_face_blend;

	//	Face Z
	float side_z_face_blend = clamp(abs(normal.z), 0.0, 1.0) * blended_normal.z;

	//	Calculate the UV coordinate based on the world position and texture scale
	uv_projected_coordinate = pixel_world_position.xy;
	uv = uv_projected_coordinate / side_texture_scale;

	//	Get the texture color
	vec3 albedo_tex_side_z = texture(side_texture, uv).rgb;
	vec3 normal_tex_side_z = texture(side_normal, uv).rgb;

	color += albedo_tex_side_z * side_z_face_blend;
	new_normal += normal_tex_side_z * side_z_face_blend;


	ALBEDO = color;

	NORMAL_MAP = new_normal;
	NORMAL_MAP_DEPTH = normal_strength;

	ROUGHNESS = roughness;

	METALLIC = 0.0;
	SPECULAR = 0.0;
}
