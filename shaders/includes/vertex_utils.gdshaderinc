/*
shader_type spatial;

varying float z_dist;

void vertex() {
   z_dist = clamp((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z * -1.0,0.0,50.0);
}

void fragment() {
  ALBEDO = vec3(z_dist/50.0,0.1,50.0-(z_dist/50.0));
}
*/

float get_z_distance(mat4 modelview_matrix, vec3 vertex, float min_value, float max_value) {
	return clamp((modelview_matrix * vec4(vertex, 1.0)).z * -1.0, min_value, max_value);
}
