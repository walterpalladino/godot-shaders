shader_type spatial;

render_mode vertex_lighting, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

group_uniforms general;
uniform float smoothness : hint_range(0.0, 1.0, 0.1) = 0.5f;



//	Varying variables
varying vec3 v_view_pos;	//	used to calculate normal based on displaced vertex
varying vec4 vertex_color; // Varying to pass color from vertex to fragment


void vertex() {
	// get the view pos for the low poly normals
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;
	
	vertex_color = COLOR; // COLOR built-in contains vertex color data
}


void fragment() {

	//	Normal calculation based on vertex displacement
	vec3 xTangent = dFdx( v_view_pos );
    vec3 yTangent = dFdy( v_view_pos );
	vec3 normal_flat = -normalize( cross( xTangent, yTangent ) );



	ALBEDO = vertex_color.rgb;
	ROUGHNESS = 1.0 - smoothness;

	NORMAL = normal_flat;

}
