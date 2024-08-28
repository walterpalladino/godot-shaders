shader_type spatial;

render_mode depth_draw_always;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	//	Working with compatibility
	//	depth_texture = depth_texture * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	depth = VERTEX.z + depth;	//	Adjust camera position

	ALBEDO = vec3(depth * 0.01);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
