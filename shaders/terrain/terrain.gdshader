shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;


group_uniforms general;
uniform float smoothness : hint_range(0.0, 1.0, 0.1) = 0.5f;
uniform float layer_blend : hint_range(0.0, 10.0, 0.1) = 0.0;
uniform float normal_strength : hint_range(0.01, 6.0, 0.01) = 1.0;

group_uniforms layer1;
uniform sampler2D layer_1_texture : hint_default_white, filter_nearest, repeat_enable;
uniform sampler2D layer_1_normal : hint_normal, filter_nearest, repeat_enable;
uniform float layer_1_texture_scale = 1.0f;

group_uniforms layer2;
uniform sampler2D layer_2_texture : hint_default_white, filter_nearest, repeat_enable;
uniform sampler2D layer_2_normal : hint_normal, filter_nearest, repeat_enable;
uniform float layer_2_texture_scale = 1.0f;
uniform float layer_2_start = 1.0f;

group_uniforms layer3;
uniform sampler2D layer_3_texture : hint_default_white, filter_nearest, repeat_enable;
uniform sampler2D layer_3_normal : hint_normal, filter_nearest, repeat_enable;
uniform float layer_3_texture_scale = 1.0f;
uniform float layer_3_start = 2.0f;

group_uniforms layer4;
uniform sampler2D layer_4_texture : hint_default_white, filter_nearest, repeat_enable;
uniform sampler2D layer_4_normal : hint_normal, filter_nearest, repeat_enable;
uniform float layer_4_texture_scale = 1.0f;
uniform float layer_4_start = 4.0f;

group_uniforms cliff;
uniform sampler2D cliff_texture : hint_default_white, filter_nearest, repeat_enable;
uniform sampler2D cliff_texture_normal : hint_normal, filter_nearest, repeat_enable;
uniform float cliff_texture_scale = 1.0f;
uniform float cliff_presence : hint_range(0.0, 1.0, 0.01) = 0.50f;
uniform float cliff_blend : hint_range(0.0, 10.0, 0.01) = 0.50f;


vec2 random(vec2 uv){
    uv = vec2( dot(uv, vec2(127.1,311.7) ),
               dot(uv, vec2(269.5,183.3) ) );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix( mix( dot( random(uv_index + vec2(0.0,0.0) ), uv_fract - vec2(0.0,0.0) ),
                     dot( random(uv_index + vec2(1.0,0.0) ), uv_fract - vec2(1.0,0.0) ), blur.x),
                mix( dot( random(uv_index + vec2(0.0,1.0) ), uv_fract - vec2(0.0,1.0) ),
                     dot( random(uv_index + vec2(1.0,1.0) ), uv_fract - vec2(1.0,1.0) ), blur.x), blur.y) + 0.5;
}

vec3 normal_blend(vec3 n1, vec3 n2, float blend) {
	vec3 n1_unpacked = n1 * 2.0 - 1.0;
	vec3 n2_unpacked = n2 * 2.0 - 1.0;
	vec3 n_blended = mix(n1_unpacked, n2_unpacked, blend);
	return (n_blended + 1.0) * 0.5;
}

//	Get color intensity (at pointgray scale)
float get_intensity(vec3 color)
{
	return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
}

void fragment() {

	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

//	vec3 normal = mat3(INV_VIEW_MATRIX) * NORMAL;
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;

	vec2 uv = UV;

	vec3 layer1_color = texture(layer_1_texture, pixel_world_position.xz * layer_1_texture_scale).rgb;
	vec3 layer2_color = texture(layer_2_texture, pixel_world_position.xz * layer_2_texture_scale).rgb;
	vec3 layer3_color = texture(layer_3_texture, pixel_world_position.xz * layer_3_texture_scale).rgb;
	vec3 layer4_color = texture(layer_4_texture, pixel_world_position.xz * layer_4_texture_scale).rgb;

	vec3 layer1_normal = texture(layer_1_normal, pixel_world_position.xz * layer_1_texture_scale).rgb;
	vec3 layer2_normal = texture(layer_2_normal, pixel_world_position.xz * layer_2_texture_scale).rgb;
	vec3 layer3_normal = texture(layer_3_normal, pixel_world_position.xz * layer_3_texture_scale).rgb;
	vec3 layer4_normal = texture(layer_4_normal, pixel_world_position.xz * layer_4_texture_scale).rgb;

	vec3 color = layer1_color;
	vec3 normal_value = layer1_normal;
	float height = pixel_world_position.y;
	if (layer_blend > 0.0) {
		height += noise(pixel_world_position.xz);
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
		//blend /=  layer_blend;
		blend /=  layer_blend * (layer_3_start - layer_2_start);
		blend = clamp(blend, 0.0, 1.0);
		color = mix(layer2_color, layer3_color, blend);
		normal_value = normal_blend(layer2_normal, layer3_normal, blend);
	} else
	if (height > layer_2_start) {
		blend = height - layer_2_start;
		//blend /=  layer_blend;
		blend /=  layer_blend * (layer_2_start - 0.0);
		blend = clamp(blend, 0.0, 1.0);
		color = mix(layer1_color, layer2_color, blend);
		normal_value = normal_blend(layer1_normal, layer2_normal, blend);
	}

	//	Check cliff
	if (cliff_presence > 0.0) {
		float noise_value = noise(pixel_world_position.xz) * 0.01;
		vec3 cliff_normal = abs(world_normal);
		//float cliff_blend = 0.0;
		if (abs(cliff_normal.y) < cliff_presence - noise_value) {

			//	Face X
			float side_x_face_blend = clamp(cliff_normal.x, 0.0, 1.0) ;
			//	Calculate the UV coordinate based on the world position and texture scale
			vec2 uv_projected_coordinate_x = pixel_world_position.zy;
			uv = uv_projected_coordinate_x / cliff_texture_scale;
			//	Get the texture color
			vec3 albedo_tex_side_x = texture(cliff_texture, uv).rgb;
			vec3 normal_tex_side_x = texture(cliff_texture_normal, uv).rgb;

			//	Face Z
			float side_z_face_blend = clamp(cliff_normal.z, 0.0, 1.0) ;
			//	Calculate the UV coordinate based on the world position and texture scale
			vec2 uv_projected_coordinate_z = pixel_world_position.xy;
			uv = uv_projected_coordinate_z / cliff_texture_scale;
			//	Get the texture color
			vec3 albedo_tex_side_z = texture(cliff_texture, uv).rgb;
			vec3 normal_tex_side_z = texture(cliff_texture_normal, uv).rgb;

			//	Blend cliff
			vec3 cliff_blended_color = mix(albedo_tex_side_x, albedo_tex_side_z, cliff_normal.z);
			vec3 cliff_normal_value = normal_blend(normal_tex_side_x, normal_tex_side_z, cliff_normal.z);

			float cliff_blend_value = 1.0 - cliff_normal.y ;
			//cliff_blend = 3.0 * cliff_blend;
			cliff_blend_value = 10.0 * pow(cliff_blend_value, cliff_blend);
			cliff_blend_value = clamp(cliff_blend_value, 0.0, 1.0);

			color = mix(color, cliff_blended_color, cliff_blend_value);
			normal_value = normal_blend(normal_value, cliff_normal_value, cliff_blend_value);
		}
	}

	//vec3 color = texture(layer_1_texture, pixel_world_position.xz * layer_1_texture_scale).rgb;
	//vec3 normal_value = texture(layer_1_normal, pixel_world_position.xz * uv * layer_1_texture_scale).rgb;


	ALBEDO = color;
	ROUGHNESS = 1.0 - smoothness;
	NORMAL_MAP = normal_value;
	NORMAL_MAP_DEPTH = normal_strength;
}
