shader_type spatial;

render_mode unshaded;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D main_texture : source_color;

uniform float brightness : hint_range(0.0, 1.0, 0.01) = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec3 texture_color = texture(main_texture, UV).rgb;
	vec3 color = texture_color * albedo_color;
	color *= brightness;

	ALBEDO = color;
}
