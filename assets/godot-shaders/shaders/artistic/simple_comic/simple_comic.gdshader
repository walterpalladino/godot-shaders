shader_type spatial;

//render_mode unshaded;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture : hint_default_white;

uniform float rim_power = 1.0;
uniform float rim_width : hint_range(0.0, 1.0, 0.01) = 0.005;

uniform float roughness : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec3 view_normal = (VIEW_MATRIX * vec4(world_normal, 0.0)).xyz;

	float rim = pow(view_normal.z, rim_power);

	rim = clamp(rim, 0.0, 1.0);
	rim = step(rim_width, rim);

	vec4 _texture = texture(texture, UV);
	vec3 _color = color.rgb * _texture.rgb * rim;

	ALBEDO	= _color;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
