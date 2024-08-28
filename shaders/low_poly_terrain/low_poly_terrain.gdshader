shader_type spatial;


uniform float tolerance : hint_range(0.0, 1.0, 0.01) = 1.0;

group_uniforms top_texture;
uniform sampler2D top_texture;
uniform vec2 top_texture_tiling = vec2(1.0, 1.0);
uniform vec3 top_texture_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float top_texture_roughness : hint_range(0.0, 1.0, 0.01) = 1.0;
//uniform float top_normal_strength : hint_range(0.01, 6.0, 0.01) = 1.0;

group_uniforms side_texture;
uniform sampler2D side_texture;
uniform vec2 side_texture_tiling = vec2(1.0, 1.0);
uniform vec3 side_texture_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float side_texture_roughness : hint_range(0.0, 1.0, 0.01) = 1.0;
//uniform float side_normal_strength : hint_range(0.01, 6.0, 0.01) = 1.0;


//	Varying variables
varying vec3 v_view_pos;	//	used to calculate normal based on displaced vertex


void vertex() {

	// get the view pos for the low poly normals
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;
}

void fragment() {

	float normal_tolerance = 1.0 - clamp(tolerance, 0.01, 0.99);
	//float normal_tolerance = tolerance;

	//	Get the world position
	vec3 world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;

	vec2 uv = world_position.xz * top_texture_tiling;
	vec3 texture_color = texture(top_texture, uv).rgb;
	vec3 tint_color = top_texture_color;
	float roughness = top_texture_roughness;

	if (abs(world_normal.y) < normal_tolerance) {

		if (abs(world_normal.x) <= 0.5) {

			uv = world_position.xy * side_texture_tiling;
			tint_color = side_texture_color;
			texture_color = texture(side_texture, uv).rgb;
			roughness = side_texture_roughness;

		} else {

			uv = world_position.zy * side_texture_tiling;
			tint_color = side_texture_color;
			texture_color = texture(side_texture, uv).rgb;
			roughness = side_texture_roughness;

		}

	}



	vec3 surface_color = tint_color * texture_color;


	ALBEDO = surface_color;
	//ALBEDO = vec3(world_normal.y);
	ROUGHNESS = roughness;
	//NORMAL_MAP = normal_value;
	//NORMAL_MAP_DEPTH = normal_strength;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
