shader_type spatial;

#include "res://shaders/includes/noise.gdshaderinc"

group_uniforms simulation;
uniform vec2 scroll_speed = vec2(0.0);


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec2 uv = vec2(UV.x + TIME * scroll_speed.x, UV.y + TIME * scroll_speed.y);


	vec3 noise = get_noise(scale * vec3(uv, seed)).rgb;

	ALBEDO = noise;

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
