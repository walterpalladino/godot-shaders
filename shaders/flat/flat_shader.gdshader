shader_type spatial;

uniform vec3 color : source_color = vec3(1.0);


varying flat vec3 flat_vertex;
varying  vec3 v_view_pos;

void vertex() {
	flat_vertex = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;
}

void fragment() {

	//	Normal calculation based on vertex displacement
	vec3 xTangent = dFdx( v_view_pos );
    vec3 yTangent = dFdy( v_view_pos );
	vec3 normal = -normalize( cross( xTangent, yTangent ) );

	NORMAL = normal;
	//LIGHT_VERTEX = flat_vertex;
	ALBEDO = color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
