shader_type spatial;

group_uniforms material;

uniform sampler2D material_texture : hint_default_white,filter_linear_mipmap;
uniform vec3 color : source_color = vec3(1.0, 1.0, 1.0);

group_uniforms wind;

uniform sampler2D wind_impact_texture : hint_default_white,filter_linear_mipmap;
uniform vec2 wind_strength = vec2(0.0);
uniform float wind_frequency = 0.0f;

group_uniforms noise;

uniform sampler2D noise_texture : hint_default_white,filter_linear_mipmap;
uniform vec2 noise_scale = vec2(1.0);
//uniform float noise_strenght = 1.0;



//	Varying variables
varying vec3 v_view_pos;	//	used to calculate normal based on displaced vertex


void vertex() {

	//	Will get the noise based on the vertex world position
	vec3 vertex_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 position = VERTEX;

	vec2 uv = UV;
	uv = uv * noise_scale + TIME * wind_frequency;
	vec3 noise = vec3(texture(noise_texture, uv).x);
	noise = 0.5 + 0.5 * noise;

	noise.x = noise.x * wind_strength.x * 0.001;
	noise.y = 0.0;
	noise.z = noise.z * wind_strength.y * 0.001;

	position += noise;

	//	How much will affect based on height
	vec3 wind_impact = texture(wind_impact_texture, UV).xyz;
	wind_impact = clamp(wind_impact, 0.0, 1.0);

	VERTEX = mix(VERTEX, position, wind_impact);

	// get the view pos for the low poly normals
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;

}

void fragment() {

	//	Normal calculation based on vertex displacement
	vec3 xTangent = dFdx( v_view_pos );
    vec3 yTangent = dFdy( v_view_pos );
	vec3 normal = -normalize( cross( xTangent, yTangent ) );

	vec4 texture_color = texture(material_texture, UV);
	ALBEDO = color * texture_color.rgb;

	NORMAL = normal;
}

