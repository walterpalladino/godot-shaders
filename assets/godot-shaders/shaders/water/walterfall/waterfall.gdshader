shader_type spatial;

uniform sampler2D waterfall_water_texture : hint_default_white;
uniform vec3 waterfall_color : source_color = vec3(1.0);
uniform vec2 waterfall_texture_scale = vec2(1.0, 1.0);
uniform float waterfall_water_speed = 1.0;

uniform float transparency : hint_range(0.0, 1.0, 0.01) = 0.20;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec3 color = texture(waterfall_water_texture, UV * waterfall_texture_scale + vec2( TIME * waterfall_water_speed, 0.0)).rgb;
	ALBEDO = color + waterfall_color;

	ROUGHNESS = 0.0;
	SPECULAR = 1.0;
	ALPHA = 1.0 - (1.0 - color.r) * transparency;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
