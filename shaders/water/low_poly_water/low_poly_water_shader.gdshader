shader_type spatial;

render_mode depth_draw_always, cull_disabled, diffuse_lambert, specular_schlick_ggx;

group_uniforms water_color;

//	Deep
uniform vec3 deep_color : source_color;
uniform vec3 shallow_color : source_color;
uniform float beers_law = 2.0;	//	Attenuation of light
uniform float depth_offset = -0.75;

uniform sampler2D riples ;
uniform vec2 riples_velocity = vec2(0.1, 0.1);
uniform float riples_scale = 1.0;
uniform float riples_strength : hint_range(0.0, 1.0) = 0.25;

uniform float metallic : hint_range(0.0,1.0) = 0;
uniform float specular : hint_range(0.0,1.0) = 0.8;
uniform float roughness : hint_range(0.0,1.0) = 0.02;
uniform float opacity : hint_range(0.0,1.0) = 0.8;

group_uniforms water_waves;

uniform sampler2D wave_noise_texture;
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;


//foam
group_uniforms water_foam;
uniform vec2 foam_speed = vec2(0.02, 0.02);
uniform	float foam_amount : hint_range(0.0, 10.0, 0.01) = 0.40;
uniform float edge_scale : hint_range(0.0, 5.0, 0.01) = 0.25;
uniform sampler2D foam_texture;
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


//	Fresnel will adjust the color of albedo depending
//	on the angle the camera is viewing the mesh.
float fresnel (float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}


void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height = texture(wave_noise_texture, world_position.xz /  noise_scale + TIME * time_scale).r;
	VERTEX.y += height * height_scale;

	// get the view pos for the low poly normals
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;
}

void fragment() {

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
	vec2 riple_coords = UV * riples_scale + (TIME * riples_velocity) ;
	vec2 riple_coords2 = UV * riples_scale - (TIME * riples_velocity) ;

	vec3 riple_color = texture(riples, riple_coords).rgb;
	vec3 riple_color2 = texture(riples, riple_coords2).rgb;

	vec3 riple = vec3( pow(riple_color.r * riple_color2.r, 1.2) * riples_strength);

	vec3 color_based_on_depth = mix (deep_color, shallow_color, vec3(1.0 - depth_blend_power));

	vec3 color = color_based_on_depth ;

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

	//	Set the shader attributes
	ALBEDO = mixed_color;

	EMISSION = riple + fresnel_color * fresnel_value;

	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;

    NORMAL = normal;

}
