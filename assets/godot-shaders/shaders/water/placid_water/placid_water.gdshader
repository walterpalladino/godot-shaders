shader_type spatial;

group_uniforms water_color;

uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law = 2.0;	//	Attenuation of light
uniform float depth_offset = -0.75;

uniform float metallic : hint_range(0.0,1.0) = 0;
uniform float roughness : hint_range(0.0,1.0) = 0.02;
uniform float specular : hint_range(0.0,1.0) = 0.8;
uniform float opacity : hint_range(0.0,1.0) = 0.8;


group_uniforms waves_settings;
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;

uniform float normal_texture_scale = 1.0f;
uniform float normal_texture_scale2 = 1.0f;
uniform float normal_texture_strength = 1.0f;

uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);

group_uniforms water_riples;
uniform sampler2D riples ;
uniform vec2 riples_velocity = vec2(0.1, 0.1);
uniform float riples_scale = 1.0;
uniform float riples_strength : hint_range(0.0, 1.0) = 0.25;


uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;



//	Varying variables
varying vec3 vertex_view_position;	//	used to calculate normal based on displaced vertex


void vertex() {
	vertex_view_position = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;
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
	vec3 color = mix(screen_color, vec3(1.0), depth_blend_power);
	color = mix(color * depth_color, depth_color, opacity);

	ALBEDO = color;

	float depth_value = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	depth_value = VERTEX.z + depth_value;
	depth_value = 1.0 - depth_value / 4000.0;
	//ALBEDO = vec3( depth_value );


	//	Riples added later as emmission
	vec2 riple_coords = UV * riples_scale + (TIME * riples_velocity) ;
	vec2 riple_coords2 = UV * riples_scale - (TIME * riples_velocity) ;

	vec3 riple_color = texture(riples, riple_coords).rgb;
	vec3 riple_color2 = texture(riples, riple_coords2).rgb;

	vec3 riple = vec3( pow(riple_color.r * riple_color2.r, 1.2) * riples_strength);

	ALBEDO = color + riple * depth_blend * depth_value * (1.0 - opacity);

	vec4 vertex_world_position = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	//	Time calculations
	vec2 time = (TIME / 1000.0 * wave_direction) ;
	vec2 time2 = (TIME / 1000.0 * wave_direction2) ;
	//	Blend
	vec3 normal_blend = mix(texture(texture_normal, vertex_world_position.xz / normal_texture_scale + time).rgb, texture(texture_normal2, vertex_world_position.xz / normal_texture_scale2 + time2).rgb, 0.5);
	NORMAL_MAP = normal_blend;
	NORMAL_MAP_DEPTH = normal_texture_strength ;

	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;


}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
