shader_type spatial;

render_mode ambient_light_disabled;
//render_mode unshaded;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D main_texture : source_color;

uniform float shadow_strength : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float brightness : hint_range(0.0, 1.0, 0.01) = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec3 texture_color = texture(main_texture, UV).rgb;
	vec3 color = texture_color * albedo_color;
	ALBEDO = color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}

const float TINY_NUMBER = 0.001;
void light() {

	vec3 light_color = LIGHT_COLOR;
	float shadow = 1.0 - ATTENUATION;

	light_color *= mix(ATTENUATION, 1.0, (1.0 - shadow_strength));

	light_color *= brightness;


	DIFFUSE_LIGHT += light_color ;
}
