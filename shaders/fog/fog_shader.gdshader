shader_type spatial;
render_mode unshaded;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_linear_mipmap;

uniform vec3 fog_color : source_color = vec3(1.0);

//uniform float depth_range:hint_range(0.01, 1.0, 0.1);
uniform float depth_range:hint_range(0.1, 10000.0, 0.1);

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	/*
	//	Depth calculations
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r ;
	float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	depth = depth + VERTEX.z;
	depth = depth ;//- depth_offset;
	depth = clamp(depth, 0.0, 1.0);

	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;

	vec3 color = mix(fog_color, screen_color, 1.0 - depth );

	ALBEDO = screen_color;
	ALBEDO = vec3(depth * 0.0001);
	//ALBEDO = vec3(VERTEX.z * 1000.01);
	//ALBEDO = color;
	ALBEDO = vec3(0.0);
	*/

	vec2 uv = SCREEN_UV;

	vec3 screen_color = texture(SCREEN_TEXTURE, uv).rgb;
	vec3 normal = texture(NORMAL_TEXTURE, uv).rgb;
	float roughness =  texture(NORMAL_TEXTURE, uv).w;

	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z / depth_range;

	// your code goes here!

	vec3 fog = vec3(linear_depth);
	vec3 final_color = fog + screen_color;

	ALBEDO = final_color;

	//ALBEDO = vec3(linear_depth); 	// showing depth texture
	//ALBEDO = normal; 				// showing normal texture
	//ALBEDO = vec3(roughness); 	// showing roughness texture
	//ALBEDO = screen_color;		// showing screen texture
	//ALBEDO=vec3(0.0);

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
