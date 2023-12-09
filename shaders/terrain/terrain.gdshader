shader_type spatial;


group_uniforms general;
uniform float smoothness : hint_range(0.0, 1.0, 0.1) = 0.5f;
uniform float layer_blend :hint_range(0.0, 10.0, 0.1) = 0.0;

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
uniform sampler2D cliff_normal : hint_normal, filter_nearest, repeat_enable; 
uniform float cliff_texture_scale = 1.0f;


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

void fragment() {
	
	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 normal = mat3(INV_VIEW_MATRIX) * NORMAL;

	
	vec2 uv = UV;
	
	vec3 layer1_color = texture(layer_1_texture, pixel_world_position.xz * uv * layer_1_texture_scale).rgb;
	vec3 layer2_color = texture(layer_2_texture, pixel_world_position.xz * uv * layer_2_texture_scale).rgb;
	vec3 layer3_color = texture(layer_3_texture, pixel_world_position.xz * uv * layer_3_texture_scale).rgb;
	vec3 layer4_color = texture(layer_4_texture, pixel_world_position.xz * uv * layer_4_texture_scale).rgb;
	vec3 cliff_color = texture(cliff_texture, pixel_world_position.xz * uv * cliff_texture_scale).rgb;

	vec3 layer1_normal = texture(layer_1_normal, pixel_world_position.xz * uv * layer_1_texture_scale).rgb;
	vec3 layer2_normal = texture(layer_2_normal, pixel_world_position.xz * uv * layer_2_texture_scale).rgb;
	vec3 layer3_normal = texture(layer_3_normal, pixel_world_position.xz * uv * layer_3_texture_scale).rgb;
	vec3 layer4_normal = texture(layer_4_normal, pixel_world_position.xz * uv * layer_4_texture_scale).rgb;
	vec3 cliff_normal_value = texture(cliff_normal, pixel_world_position.xz * uv * cliff_texture_scale).rgb;
	
	vec3 color = layer1_color;
	vec3 normal_value = layer1_normal;
	float height = pixel_world_position.y;
	if (layer_blend > 0.0) {
		height += noise(pixel_world_position.xz);		
	}
	float blend = 0.0;
	if (height > layer_4_start) {
		blend = height - layer_4_start;
		blend /=  layer_blend;
		blend = clamp(blend, 0.0, 1.0);	
		color = mix(layer3_color, layer4_color, blend);
		normal_value = mix(layer3_normal, layer4_normal, blend);
	} else
	if (height > layer_3_start) {
		blend = height - layer_3_start;
		blend /=  layer_blend;
		blend = clamp(blend, 0.0, 1.0);	
		color = mix(layer2_color, layer3_color, blend);
		normal_value = mix(layer2_normal, layer3_normal, blend);
	} else
	if (height > layer_2_start) {
		blend = height - layer_2_start;
		blend /=  layer_blend;
		blend = clamp(blend, 0.0, 1.0);	
		color = mix(layer1_color, layer2_color, blend);
		normal_value = mix(layer1_normal, layer2_normal, blend);
	}
		
	ALBEDO = color;// * ((noise(pixel_world_position.xz * 0.20) + 1.0) / 2.0);
//	ALBEDO = vec3(blend);
	ROUGHNESS = 1.0 - smoothness;
	NORMAL_MAP = normal_value;
	NORMAL_MAP_DEPTH = 2.0;
}
