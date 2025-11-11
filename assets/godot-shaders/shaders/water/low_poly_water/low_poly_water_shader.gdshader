shader_type spatial;

render_mode depth_draw_always, cull_disabled, diffuse_lambert, specular_schlick_ggx;

group_uniforms water_color;

//	Deep
uniform vec3 deep_color : source_color;
uniform vec3 shallow_color : source_color;
uniform float beers_law = 2.0;	//	Attenuation of light
uniform float depth_offset = -0.75;


uniform float metallic : hint_range(0.0,1.0) = 0;
uniform float specular : hint_range(0.0,1.0) = 0.8;
uniform float roughness : hint_range(0.0,1.0) = 0.02;
uniform float opacity : hint_range(0.0,1.0) = 0.8;

group_uniforms water_riples;
uniform sampler2D riples ;
uniform vec3 riples_color : source_color = vec3(1.0);
uniform vec2 riples_velocity = vec2(0.1, 0.1);
uniform float riples_scale = 1.0;
uniform float riples_strength : hint_range(0.0, 1.0) = 0.25;


// waves settings
group_uniforms water_waves_base;

uniform sampler2D wave_noise_texture;
uniform vec2 waves_speed = vec2(1.0, 0.0);
uniform float water_waves_noise_scale = 10.0;
uniform float water_waves_height_scale = 0.15;

group_uniforms water_big_waves;
uniform bool wave_texture_enabled;
uniform vec2 wave_texture_speed = vec2(-50.0, -50.0);
uniform sampler2D wave_texture;
uniform float wave_texture_strength = 2.5;

//foam
group_uniforms water_foam;
uniform vec2 foam_speed = vec2(0.02, 0.02);
uniform	float foam_amount : hint_range(0.0, 10.0, 0.01) = 0.40;
uniform float edge_scale : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform sampler2D foam_texture;
uniform vec2 foam_shore_tiling = vec2(4.0, 4.0);
uniform vec2 foam_tiling = vec2(4.0, 4.0);
uniform vec3 foam_color : source_color;


//fresnel
group_uniforms water_fresnel;
uniform vec3 fresnel_color : source_color;
uniform float fresnel_strength : hint_range(0.0, 1.0) = 0.5;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


//	Varying variables
varying vec3 v_view_pos;	//	used to calculate normal based on displaced vertex
varying vec3 vertex_world_pos;
varying float wave_height_at_pos;



//	Fresnel will adjust the color of albedo depending
//	on the angle the camera is viewing the mesh.
float fresnel (float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

vec3 get_vertex_position(mat4 model_matrix, vec3 vertex) {

	vec3 world_position = (model_matrix * vec4(vertex, 1.0)).xyz;
	float height = texture(wave_noise_texture, world_position.xz / water_waves_noise_scale + TIME * waves_speed / 1000.0).r;
	vertex.y += height * water_waves_height_scale;

	return vertex;
}

float get_wave_height(mat4 model_matrix, vec3 vertex) {

	vec3 world_position = (model_matrix * vec4(vertex, 1.0)).xyz;
	float wave_height = wave_texture_strength * texture(wave_texture, world_position.xz / wave_texture_speed + TIME * waves_speed / 1000.0).r;
	wave_height = pow(wave_height, 2.0);
	return wave_height * water_waves_height_scale;

}

void vertex() {

	VERTEX = get_vertex_position(MODEL_MATRIX, VERTEX);
	if (wave_texture_enabled) {
		wave_height_at_pos = get_wave_height(MODEL_MATRIX, VERTEX);
		VERTEX.y += wave_height_at_pos;
	}
	vertex_world_pos = VERTEX;
	// get the view pos for the low poly normals
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;

}

void fragment() {

	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 water_uv = pixel_world_position.xz;

//	vec3 world_normal = cross( dFdx(vertex_world_pos), dFdy(vertex_world_pos) );
//	world_normal = -normalize(world_normal);

	//	Normal calculation based on vertex displacement
	vec3 xTangent = dFdx( v_view_pos );
    vec3 yTangent = dFdy( v_view_pos );
	vec3 normal = -normalize( cross( xTangent, yTangent ) );


	//	Depth calculations
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r ;
	float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	depth = depth + VERTEX.z;
	depth = depth - depth_offset;

	float depth_blend = exp(depth * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	//	Riples added later as emmission
	vec2 riple_coords = water_uv * riples_scale + (TIME * riples_velocity) ;
	vec2 riple_coords2 = water_uv * riples_scale - (TIME * riples_velocity) ;

	vec3 riple_color = texture(riples, riple_coords).rgb;
	vec3 riple_color2 = texture(riples, riple_coords2).rgb;

	vec3 riple = vec3( pow(riple_color.r * riple_color2.r, 1.2) * riples_strength);

	vec3 color_based_on_depth = mix (deep_color, shallow_color, vec3(1.0 - depth_blend_power));

	vec3 color = color_based_on_depth ;

	//	Add Foam
	//	Calculate the area mask affected by the foam
	//float foam_mask = step(edge_scale, depth_blend);
	float foam_mask = smoothstep(0.0, edge_scale, depth_blend);
	foam_mask = 1.0 - foam_mask;

	//	shore foam
	vec2 offset = TIME * foam_speed;
	vec2 tiling = foam_shore_tiling;
	vec2 uv_i = vec2( water_uv.x, foam_amount * depth);

	vec2 uv_o = uv_i * tiling + offset;
	vec3 foam = texture(foam_texture, uv_o).rgb;
	foam = foam + foam_color ;
	foam = clamp(foam, 0.0, 1.0);

	float fresnel_value = fresnel(5.0, normal, VIEW) * fresnel_strength;
	//color = mix(color, fresnel_color, fresnel_value);

	//	blend the foam based on the masked area
	vec3 mixed_color = mix(color, foam, foam_mask);


	//	Color down the water
	vec3 screen_background_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	//	Mix water color with background based on opacity
	vec3 color_with_opacity = mix(mixed_color, screen_background_color, (1.0 - depth_blend_power) * (1.0 - opacity));

	//	Set water or foam color
	mixed_color = mix(color_with_opacity, foam, foam_mask);

	vec3 emission_color = riple * riples_color + fresnel_color * fresnel_value;

	if (wave_height_at_pos > 0.05) {
		vec2 wave_foam_uv = water_uv * foam_tiling - TIME * waves_speed / 1000.0;
		vec3 wave_foam_color = texture(foam_texture, wave_foam_uv).rgb;
		//mixed_color += wave_foam_color * pow(wave_height_at_pos, 2.0) * 6.0;
		emission_color = mix(emission_color, wave_foam_color * 8.0, pow(wave_height_at_pos, 1.850));
		//mixed_color = mix(mixed_color, wave_foam_color * 6.0, pow(wave_height_at_pos, 2.0));
//		mixed_color += pow(wave_height_at_pos, 2.0);
	}

	//	Set the shader attributes
	ALBEDO = mixed_color;

	EMISSION = emission_color;

	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;

    NORMAL = normal;
}
