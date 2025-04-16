shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;


group_uniforms general;
uniform float smoothness : hint_range(0.0, 1.0, 0.1) = 0.5f;
uniform float layer_blend : hint_range(0.0, 10.0, 0.1) = 0.0;
uniform float normal_strength : hint_range(0.01, 6.0, 0.01) = 1.0;
uniform bool make_flat = false;

group_uniforms layer1;
uniform sampler2D layer_1_texture : hint_default_white, filter_nearest, repeat_enable;
uniform vec3 layer_1_color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D layer_1_normal : hint_normal, filter_nearest, repeat_enable;
uniform float layer_1_texture_scale = 1.0f;
uniform bool layer1_rotate_texture = false;

group_uniforms layer2;
uniform sampler2D layer_2_texture : hint_default_white, filter_nearest, repeat_enable;
uniform vec3 layer_2_color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D layer_2_normal : hint_normal, filter_nearest, repeat_enable;
uniform float layer_2_texture_scale = 1.0f;
uniform float layer_2_start = 1.0f;
uniform bool layer2_rotate_texture = false;

group_uniforms layer3;
uniform sampler2D layer_3_texture : hint_default_white, filter_nearest, repeat_enable;
uniform vec3 layer_3_color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D layer_3_normal : hint_normal, filter_nearest, repeat_enable;
uniform float layer_3_texture_scale = 1.0f;
uniform float layer_3_start = 2.0f;
uniform bool layer3_rotate_texture = false;

group_uniforms layer4;
uniform sampler2D layer_4_texture : hint_default_white, filter_nearest, repeat_enable;
uniform vec3 layer_4_color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D layer_4_normal : hint_normal, filter_nearest, repeat_enable;
uniform float layer_4_texture_scale = 1.0f;
uniform float layer_4_start = 4.0f;
uniform bool layer4_rotate_texture = false;

group_uniforms cliff;
uniform sampler2D cliff_texture : hint_default_white, filter_nearest, repeat_enable;
uniform vec3 cliff_color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D cliff_texture_normal : hint_normal, filter_nearest, repeat_enable;
uniform float cliff_texture_scale = 1.0f;
uniform float cliff_presence : hint_range(0.0, 1.0, 0.01) = 0.50f;
uniform float cliff_blend : hint_range(0.0, 5.0, 0.01) = 0.50f;


group_uniforms terrain_stain;
uniform sampler2D stain_texture : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 stain_texture_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float stain_texture_scale = 1.0f;
uniform float stain_texture_strength : hint_range(0.0, 1.0, 0.01) = 0.0f;


//	Varying variables
varying vec3 v_view_pos;	//	used to calculate normal based on displaced vertex


#include "res://assets/godot-shaders/shaders/includes/perlin_noise.gdshaderinc"


vec3 normal_blend(vec3 n1, vec3 n2, float blend) {
	vec3 n1_unpacked = n1 * 2.0 - 1.0;
	vec3 n2_unpacked = n2 * 2.0 - 1.0;
	vec3 n_blended = mix(n1_unpacked, n2_unpacked, blend);
	return (n_blended + 1.0) * 0.5;
}


vec2 rotateUV(vec2 uv, vec2 pivot, float rotation)
{
	mat2 rotation_matrix=mat2(	vec2(sin(rotation),-cos(rotation)),
								vec2(cos(rotation),sin(rotation))
								);
    uv -= pivot;
    uv= uv*rotation_matrix;
    uv += pivot;
    return uv;
}

float rand(vec2 input) {
	return fract(sin(dot(input.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

vec2 get_uv_untiled(vec2 uv) {
	vec2 unique_val = floor(uv) ;
	float rotation = (rand(unique_val) * 2.0 - 1.0) * 3.14;
	return rotateUV(uv, vec2(0.5), rotation);
}

//	calculate data for layer
void calculate_data(vec2 position, float texture_scale, bool rotate_texture, sampler2D tex, vec3 col, sampler2D nor, inout vec2 uv, inout vec3 color, inout vec3 normal) {

	uv = position * texture_scale;
	if (rotate_texture)
		uv = get_uv_untiled(uv);

	color = texture(tex, uv).rgb * col;
	normal = texture(nor, uv).rgb;

}

void get_layer_values(float y, float layer_start, float layer_prev_start, vec3 layer_color, vec3 layer_prev_color, out vec3 color, vec3 layer_normal, vec3 layer_prev_normal, out vec3 normal) {

	float blend = y - layer_start;
	blend /=  layer_blend * (layer_start - layer_prev_start);
	blend = clamp(blend, 0.0, 1.0);
	color = mix(layer_prev_color, layer_color, blend);
	normal = normal_blend(layer_prev_normal, layer_normal, blend);

}

void vertex() {
	// get the view pos for the low poly normals
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;
}


void fragment() {

	//	Normal calculation based on vertex displacement
	vec3 xTangent = dFdx( v_view_pos );
    vec3 yTangent = dFdy( v_view_pos );
	vec3 normal_flat = -normalize( cross( xTangent, yTangent ) );

	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

//	vec3 normal = mat3(INV_VIEW_MATRIX) * NORMAL;
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;

	vec2 uv = UV;

	vec2 layer1_uv ;
	vec2 layer2_uv ;
	vec2 layer3_uv ;
	vec2 layer4_uv ;

	vec3 layer1_color ;
	vec3 layer2_color ;
	vec3 layer3_color ;
	vec3 layer4_color ;

	vec3 layer1_normal ;
	vec3 layer2_normal ;
	vec3 layer3_normal ;
	vec3 layer4_normal ;

	calculate_data(pixel_world_position.xz, layer_1_texture_scale, layer1_rotate_texture, layer_1_texture, layer_1_color, layer_1_normal, layer1_uv, layer1_color, layer1_normal) ;
	calculate_data(pixel_world_position.xz, layer_2_texture_scale, layer2_rotate_texture, layer_2_texture, layer_2_color, layer_2_normal, layer2_uv, layer2_color, layer2_normal) ;
	calculate_data(pixel_world_position.xz, layer_3_texture_scale, layer3_rotate_texture, layer_3_texture, layer_3_color, layer_3_normal, layer3_uv, layer3_color, layer3_normal) ;
	calculate_data(pixel_world_position.xz, layer_4_texture_scale, layer4_rotate_texture, layer_4_texture, layer_4_color, layer_4_normal, layer4_uv, layer4_color, layer4_normal) ;

	vec3 color = layer1_color;	//	default color
	vec3 normal_value = layer1_normal;	//	default normal

	float height = pixel_world_position.y;
	if (layer_blend > 0.0) {
		height += perlin_noise(pixel_world_position.xz);
	}

	float blend = 0.0;
	if (height > layer_4_start) {
		blend = height - layer_4_start;
		blend /=  layer_blend * (layer_4_start - layer_3_start);
		blend = clamp(blend, 0.0, 1.0);
		color = mix(layer3_color, layer4_color, blend);
		normal_value = normal_blend(layer3_normal, layer4_normal, blend);
	} else
	if (height > layer_3_start) {
		blend = height - layer_3_start;
		blend /=  layer_blend * (layer_3_start - layer_2_start);
		blend = clamp(blend, 0.0, 1.0);
		color = mix(layer2_color, layer3_color, blend);
		normal_value = normal_blend(layer2_normal, layer3_normal, blend);
	} else
	if (height > layer_2_start) {
		blend = height - layer_2_start;
		blend /=  layer_blend * (layer_2_start - 0.0);
		blend = clamp(blend, 0.0, 1.0);
		color = mix(layer1_color, layer2_color, blend);
		normal_value = normal_blend(layer1_normal, layer2_normal, blend);
	}


	//	Check cliff
	if (cliff_presence > 0.0) {

		vec3 cliff_normal = abs(world_normal);

		//	Face X
		float side_x_face_blend = clamp(cliff_normal.x, 0.0, 1.0) ;
		//	Calculate the UV coordinate based on the world position and texture scale
		vec2 uv_projected_coordinate_x = pixel_world_position.zy;
		uv = uv_projected_coordinate_x / cliff_texture_scale;
		//	Get the texture color
		vec3 albedo_tex_side_x = texture(cliff_texture, uv).rgb * cliff_color;
		vec3 normal_tex_side_x = texture(cliff_texture_normal, uv).rgb;

		//	Face Z
		float side_z_face_blend = clamp(cliff_normal.z, 0.0, 1.0) ;
		//	Calculate the UV coordinate based on the world position and texture scale
		vec2 uv_projected_coordinate_z = pixel_world_position.xy;
		uv = uv_projected_coordinate_z / cliff_texture_scale;
		//	Get the texture color
		vec3 albedo_tex_side_z = texture(cliff_texture, uv).rgb * cliff_color;
		vec3 normal_tex_side_z = texture(cliff_texture_normal, uv).rgb;

		//	Blend cliff x-z
		vec3 cliff_blended_color = mix(albedo_tex_side_x, albedo_tex_side_z, cliff_normal.z);
		vec3 cliff_normal_value = normal_blend(normal_tex_side_x, normal_tex_side_z, cliff_normal.z);

		//	Blend Cliff on surface
		if (abs(cliff_normal.y) < cliff_presence) {

			float cliff_blend_value = cliff_presence - cliff_normal.y ;
			cliff_blend_value = 20.0 * pow(cliff_blend_value, cliff_blend);
			cliff_blend_value = clamp(cliff_blend_value, 0.0, 1.0);

			color = mix(color, cliff_blended_color, cliff_blend_value);
			normal_value = normal_blend(normal_value, cliff_normal_value, cliff_blend_value);
		}
	}

	//vec3 color = texture(layer_1_texture, pixel_world_position.xz * layer_1_texture_scale).rgb;
	//vec3 normal_value = texture(layer_1_normal, pixel_world_position.xz * uv * layer_1_texture_scale).rgb;

	vec2 stain_uv = pixel_world_position.xz / stain_texture_scale;
	//if (layer1_rotate_texture)
		//stain_uv = get_uv_untiled(stain_uv);

	vec3 stain_color = texture(stain_texture, stain_uv).r * stain_texture_color;

	float stain_blend = stain_texture_strength;
	stain_blend = pow(stain_texture_strength, 0.250);
	stain_blend = clamp(stain_blend, 0.0, 1.0);
	color = mix(color, color * stain_color, stain_blend) ;

	ALBEDO = color;
	ROUGHNESS = 1.0 - smoothness;

	if (make_flat) {
		NORMAL = normal_flat;
	} else {
		NORMAL_MAP = normal_value;
		NORMAL_MAP_DEPTH = -normal_strength;
	}

}
