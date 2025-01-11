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


group_uniforms water_texture_waves;
uniform bool wave_texture_enabled;
uniform vec2 wave_texture_speed = vec2(-50.0, -50.0);
uniform sampler2D wave_texture;
uniform float wave_texture_scale = 1.0;
uniform float wave_texture_strength = 2.5;

uniform sampler2D riples ;
uniform vec2 riples_velocity = vec2(0.1, 0.1);
uniform float riples_scale = 1.0;
uniform float riples_strength : hint_range(0.0, 1.0) = 0.25;


uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
//uniform sampler2D NORMAL_ROUGHNESS_TEXTURE : hint_normal_roughness_texture, filter_linear_mipmap;


//	Foam
group_uniforms foam_settings;
uniform bool enable_foam = true;
uniform vec2 foam_speed = vec2(0.02, 0.02);
uniform	float foam_amount = 0.40;
uniform float edge_scale = 0.1;
uniform vec3 foam_color : source_color;
uniform sampler2D foam_texture;
uniform vec2 foam_tiling = vec2(4.0, 4.0);





//	Varying variables
//varying float height;
varying vec3 v_view_pos;	//	used to calculate normal based on displaced vertex
varying vec3 vertex_world_position;
varying float wave_height_at_pos;



vec3 get_vertex_position(mat4 model_matrix, vec3 vertex) {

	vec3 world_position = (model_matrix * vec4(vertex, 1.0)).xyz;
	float height = texture(wave, world_position.xz /  noise_scale + TIME * wave_direction / 1000.0).r;
	vertex.y += height * height_scale;

	return vertex;
}


float get_wave_height(mat4 model_matrix, vec3 vertex) {

	vec3 world_position = (model_matrix * vec4(vertex, 1.0)).xyz;
	vec2 wave_uv = world_position.xz / wave_texture_speed + TIME * wave_direction / 1000.0;
	wave_uv /= wave_texture_scale;
	float wave_height = wave_texture_strength * texture(wave_texture, wave_uv).r;
	return wave_height * height_scale;

}


void vertex () {
/*
	vertex_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_position.xz /  noise_scale + TIME / 1000.0  * wave_direction).r;
	VERTEX.y += height * height_scale;
*/
	VERTEX = get_vertex_position(MODEL_MATRIX, VERTEX);
	if (wave_texture_enabled) {
		wave_height_at_pos = get_wave_height(MODEL_MATRIX, VERTEX);
		VERTEX.y += wave_height_at_pos ;
	}
	vertex_world_position = VERTEX;
	// get the view pos for the low poly normals
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;

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

	//	Add Foam
	//	Calculate the area mask affected by the foam
	float foam_mask = step(edge_scale, depth_blend);
	foam_mask = smoothstep(0.0, edge_scale, depth_blend);
	foam_mask = 1.0 - foam_mask;

	//	shore foam
	vec2 offset = TIME * foam_speed;
	vec2 tiling = foam_tiling;
	vec2 uv_i = vec2( UV.x, foam_amount * depth);

	vec2 uv_o = uv_i * tiling + offset;
	vec3 foam = texture(foam_texture, uv_o).rgb;
	foam = clamp(foam, 0.0, 1.0);


	//	Riples added later as emmission
	vec2 riple_coords = UV * riples_scale + (TIME * riples_velocity) ;
	vec2 riple_coords2 = UV * riples_scale - (TIME * riples_velocity) ;

	vec3 riple_color = texture(riples, riple_coords).rgb;
	vec3 riple_color2 = texture(riples, riple_coords2).rgb;

	vec3 riple = vec3( pow(riple_color.r * riple_color2.r, 1.2) * riples_strength);

	if (enable_foam)
		EMISSION =  mix(riple, foam, foam_mask);
	else
		EMISSION = riple;

	if (enable_foam)
		ALBEDO = mix(color, foam_color, foam_mask);
	else
		ALBEDO = color;

	if (wave_height_at_pos > 0.05) {
		ALBEDO += pow(wave_height_at_pos, 2.0);
	}


	//	Time calculations
	vec2 time = (TIME / 1000.0 * wave_direction) ;
	vec2 time2 = (TIME / 1000.0 * wave_direction2) ;
	//	Blend
	vec3 normal_blend = mix(texture(texture_normal, vertex_world_position.xz / normal_texture_scale + time).rgb, texture(texture_normal2, vertex_world_position.xz / normal_texture_scale + time2).rgb, 0.5);
	NORMAL_MAP = normal_blend;
	NORMAL_MAP_DEPTH = normal_texture_strength;

	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;

//	ALBEDO = texture(NORMAL_ROUGHNESS_TEXTURE, SCREEN_UV).rgb;

}
