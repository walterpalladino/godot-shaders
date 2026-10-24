shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;


group_uniforms main;
uniform sampler2D material_texture : source_color,filter_linear_mipmap;
uniform vec2 material_scale = vec2(1.0);
uniform float alpha_cut_off : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform vec3 color : source_color;

uniform float roghness : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.2;

uniform bool draw_back_faces = false;

group_uniforms foliage_normals;
uniform vec3 canopy_center = vec3(0.0, 0.0, 0.0); // Center relative to object origin
uniform vec3 canopy_radius = vec3(1.5, 1.2, 1.5);
uniform float normal_spherical_blend : hint_range(0.0, 1.0) = 1.0; // 0 = original mesh normal, 1 = perfectly spherical

group_uniforms wind;
uniform vec2 wind_strength = vec2(0.0);
uniform float wind_frequency = 0.0f;
uniform float wind_min_height : hint_range(0.0, 5.0, 0.1) = 1.0f;
uniform float wind_max_height : hint_range(0.0, 10.0, 0.1) = 5.0f;

//	Add swag noise
uniform sampler2D noise_texture;


varying vec3 world_normal;
varying vec3 local_vertex;

void vertex() {

	//	Will get the noise based on the vertex world position
	vec3 vertex_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 position = VERTEX;

	position.x += wind_strength.x * sin(TIME * wind_frequency) ;
	position.z += wind_strength.y * cos(TIME * wind_frequency) ;

	//	Adds swag
	vec2 uv = TIME * wind_frequency / 100.0 + vec2( vertex_world_position.x, vertex_world_position.z) ;
	float noise = texture(noise_texture, uv).r;
	noise = (noise - 0.5) * 2.0 ;
	position.x += noise * wind_strength.x * 5.0;
	position.z += noise * wind_strength.y * 5.0 ;

	//	How much will affect based on height
	float factor = 0.0;
	if ((wind_max_height > wind_min_height) && (VERTEX.y >= wind_min_height)) {
		factor = (VERTEX.y - wind_min_height) / (wind_max_height - wind_min_height);
	}
	factor = clamp(factor, 0.0, 1.0);

	VERTEX = mix(VERTEX, position, factor);
	local_vertex = VERTEX;

	// 1. Calculate the direction from the canopy center to the vertex position
	// Using VERTEX (object-space coordinates) ensures the center scales and rotates with the object
	vec3 local_offset = VERTEX - canopy_center;
	vec3 safe_radius = max(canopy_radius, vec3(0.001));
	vec3 sphere_normal = normalize(local_offset/safe_radius/safe_radius);
	
	// 2. Linearly interpolate between the original mesh normal and the spherical normal
	NORMAL = mix(NORMAL, sphere_normal, normal_spherical_blend);
	NORMAL = normalize(NORMAL);

	world_normal = NORMAL;
}

void fragment() {

	vec2 uv = UV * material_scale;
	vec4 texture_color = texture(material_texture, uv * material_scale);

	ALBEDO = color * texture_color.rgb;

	ALPHA = texture_color.a ;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut_off;
	
	ROUGHNESS = roghness;
	SPECULAR = specular;
}
