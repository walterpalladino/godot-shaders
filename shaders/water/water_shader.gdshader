shader_type spatial;

group_uniforms water_color;
uniform vec3 albedo : source_color ;
uniform vec3 albedo2 : source_color ;
uniform float fresnel_strength : hint_range(0.0, 10.0, 0.1) = 5.0 ;

uniform float metallic : hint_range(0.0,1.0) = 0; 
uniform float roughness : hint_range(0.0,1.0) = 0.02; 

group_uniforms waves_settings;
uniform sampler2D wave;
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
uniform float normal_texture_scale = 1.0f;
uniform float normal_texture_strength = 1.0f;

uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
//uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025; 
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;

group_uniforms water_depth;
uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law = 2.0;	//	Attenuation of light
uniform float depth_offset = -0.75;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


//	Foam
group_uniforms foam_settings;
uniform float edge_scale = 0.1;
uniform float near = 0.5;
uniform float far = 100.0;
uniform vec3 foam_color : source_color;
uniform sampler2D foam_texture;



//	Varying variables
varying float height;
varying vec3 world_position;



float fresnel (float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);	
}

float edge(float depth) {
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

void vertex () {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_position.xz /  noise_scale + TIME / 1000.0  * wave_direction).r;
	VERTEX.y += height * height_scale;
}

void fragment() {
	
	
	//	Depth calculations
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r ;
	float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	depth = VERTEX.z + depth;
	depth = depth - depth_offset;

	float depth_blend = exp(depth * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);	
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);
	
	// Getting edge depth calc
	float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = edge(FRAGCOORD.z);
	float z_dif = z_depth - z_pos;

	//	Fresnel	
	float fresnel = fresnel(fresnel_strength, NORMAL, VIEW);
	vec3 surface_color = mix(albedo, albedo2, fresnel);
	
	//ALBEDO = mix(surface_color, color, 0.75);
	vec3 depth_color_adj = mix(foam_color, color, step(edge_scale, z_dif));
	
	ALBEDO = clamp(surface_color + depth_color_adj,vec3(0.0),vec3(1.0));
	//ALBEDO = vec3(depth - depth_offset);

	METALLIC = metallic;
	ROUGHNESS = roughness;

	//	Time calculations
	vec2 time = (TIME / 1000.0 * wave_direction) ; 
	vec2 time2 = (TIME / 1000.0 * wave_direction2) ; 
	//	Blend
	vec3 normal_blend = mix(texture(texture_normal, world_position.xz / normal_texture_scale + time).rgb, texture(texture_normal2, world_position.xz / normal_texture_scale + time2).rgb, 0.5);
	NORMAL_MAP = normal_blend;
	NORMAL_MAP_DEPTH = normal_texture_strength;
}
