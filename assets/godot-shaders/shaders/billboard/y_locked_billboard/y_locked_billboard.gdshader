shader_type spatial;

render_mode cull_back, blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;


uniform sampler2D texture_albedo : source_color, hint_default_white, filter_linear_mipmap, repeat_disable;
uniform vec4 base_color : source_color = vec4(1.0);


void vertex() {
	vec3 direction = CAMERA_DIRECTION_WORLD;

	vec3 local_x = MODEL_MATRIX[0].xyz;
	vec3 local_y = MODEL_MATRIX[1].xyz;
	vec3 local_z = MODEL_MATRIX[2].xyz;

	// local_y cross direction_to_camera = right
	vec3 billboard_x = normalize(cross(local_y, direction));
	// billboard_x cross local_y = forward
	vec3 billboard_z = normalize(cross(billboard_x, local_y));

	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(billboard_x * length(local_x), 0.0), vec4(local_y, 0.0), vec4(billboard_z * length(local_z), 0.0), MODEL_MATRIX[3] );
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 color = texture(texture_albedo, UV) * base_color;
	ALBEDO = color.rgb;
	ALPHA = color.a;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
