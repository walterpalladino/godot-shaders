shader_type spatial;

render_mode fog_disabled;


group_uniforms water_color;

uniform vec4 color_deep : source_color = vec4(1) ;
uniform vec4 color_shallow : source_color = vec4(1);
uniform float beers_law = 2.0;	//	Attenuation of light
uniform float depth_offset = -0.75;



uniform float metallic : hint_range(0.0,1.0) = 0;
uniform float roughness : hint_range(0.0,1.0) = 0.02;
uniform float specular : hint_range(0.0,1.0) = 0.8;
uniform float opacity_level : hint_range(0.0,1.0) = 1.0;


// waves settings
group_uniforms water_waves_base;

uniform sampler2D wave_noise_texture;
uniform vec2 waves_speed = vec2(1.0, 0.0);
uniform float water_waves_noise_scale = 10.0;
uniform float water_waves_height_scale = 0.15;


group_uniforms water_riples;
uniform sampler2D riples_texture ;
uniform vec4 riples_color : source_color = vec4(1) ;
uniform vec2 riples_velocity = vec2(0.1, 0.1);
uniform float riples_scale = 1.0;
uniform float riples_strength : hint_range(0.0, 1.0) = 0.25;


//foam
group_uniforms water_foam;

uniform float foam_speed = 0.1;
uniform	float foam_amount : hint_range(0.0, 20.0, 0.01) = 3.0;
uniform float edge_scale : hint_range(0.0, 10.0, 0.01) = 2.0;
uniform sampler2D foam_texture;
uniform float foam_shore_tiling = 0.1;
uniform vec3 foam_color : source_color = vec3(1.0);
uniform float foam_strength : hint_range(0.0, 5.0, 0.1) = 2.5;

//fresnel
group_uniforms water_fresnel;
uniform vec3 fresnel_color : source_color;
uniform float fresnel_strength : hint_range(0.0, 10.0) = 0.5;



uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;


//	Varying variables
varying vec3 v_view_pos;	//	used to calculate normal based on displaced vertex
varying vec3 vertex_world_pos;
varying float wave_height_at_pos;



vec3 get_vertex_position(mat4 model_matrix, vec3 vertex) {

	vec3 world_position = (model_matrix * vec4(vertex, 1.0)).xyz;
	float height = texture(wave_noise_texture, world_position.xz / water_waves_noise_scale + TIME * waves_speed / 1000.0).r;
	vertex.y += height * water_waves_height_scale;

	return vertex;
}

//	Fresnel will adjust the color of albedo depending
//	on the angle the camera is viewing the mesh.
float fresnel (float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}


void vertex() {

	VERTEX = get_vertex_position(MODEL_MATRIX, VERTEX);

	vertex_world_pos = VERTEX;
	// get the view pos for the low poly normals
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;

}

void fragment() {

	//	Get the world position
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 water_uv = pixel_world_position.xz;
	
	vec3 screen_texture = texture(SCREEN_TEXTURE, SCREEN_UV).rgb ;
	float depth_raw_value = texture(DEPTH_TEXTURE, SCREEN_UV).x;


#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth_raw_value) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw_value);
#endif
	vec4 position_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);

	position_view.xyz /= position_view.w;
	float linear_depth = -position_view.z;
		
	linear_depth = linear_depth + VERTEX.z;
	linear_depth = linear_depth - depth_offset;
	
	//	blend shallow and deep water color
	float depth_blend = exp(linear_depth * -beers_law);
	depth_blend = clamp(depth_blend, 0.0, 1.0);

	vec3 water_color = mix(color_deep, color_shallow, depth_blend).rgb;

	//	blend water color with surface under it
	float alpha_depth_blend = exp((linear_depth + depth_offset) * -(opacity_level * 15.0));
	alpha_depth_blend = clamp(alpha_depth_blend, 0.0, 1.0);

	vec3 color = mix(water_color, screen_texture, alpha_depth_blend);
	ALBEDO = color;


	SPECULAR = specular;
	METALLIC = metallic;
	SPECULAR = specular;
	
	//	Normal calculation based on vertex displacement
	vec3 xTangent = dFdx( v_view_pos );
    vec3 yTangent = dFdy( v_view_pos );
	vec3 normal = -normalize( cross( xTangent, yTangent ) );

	float fresnel_value = fresnel(5.0, normal, VIEW) * fresnel_strength;


	//	Riples added later as emmission
	vec2 riple_coords = UV * riples_scale + (TIME * riples_velocity) ;
	vec2 riple_coords2 = UV * riples_scale - (TIME * riples_velocity) ;

	vec3 riple_texture1 = texture(riples_texture, riple_coords).rgb;
	vec3 riple_texture2 = texture(riples_texture, riple_coords2).rgb;

	vec3 riple = vec3( pow(riple_texture1.r * riple_texture2.r, 1.2) ) * riples_color.rgb;


	//	Add Foam
	//	Calculate the area mask affected by the foam
	//float foam_mask = step(edge_scale, depth_blend);
	float foam_mask = smoothstep(0.0, edge_scale, depth_blend);
	//foam_mask = 1.0 - foam_mask;

	//	shore foam
	vec2 offset = vec2(0.0, TIME * foam_speed);
	vec2 uv_i = vec2( water_uv.x, foam_amount * linear_depth );

	vec2 uv_o = uv_i * foam_shore_tiling + offset;
	vec3 foam = texture(foam_texture, uv_o).rgb;
	foam = foam * foam_color ;
	foam = clamp(foam, 0.0, 1.0);

	//	blend the foam based on the masked area
	vec3 mixed_color = mix(color, foam, foam_mask);
	//ALBEDO = vec3(foam_mask);
	//ALBEDO = mix(vec3(0.0), foam, foam_mask);
	//ALBEDO = mixed_color;

	//vec3 emission_color = riple * riples_color + fresnel_color * fresnel_value;
	vec3 emission_color = fresnel_color * fresnel_value + riple * riples_strength;
	
	emission_color = mix(emission_color, foam * foam_strength, foam_mask);
	
	EMISSION = emission_color;
}

	
	
