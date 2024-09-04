shader_type spatial;

render_mode unshaded, depth_draw_opaque;

#include "res://shaders/includes/noise.gdshaderinc"


uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

group_uniforms fx;

uniform float strength;    //Force of the effect
uniform vec2 fx_speed = vec2(0.0);


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec2 uv = SCREEN_UV;
	vec2 uv_noise = vec2(SCREEN_UV.x + TIME * fx_speed.x, SCREEN_UV.y + TIME * fx_speed.y);// - vec2(0.5);
	vec3 noise = get_noise(scale * vec3(uv_noise, seed)).rgb;

	uv = uv + noise.xy * strength;

	ALBEDO = texture(SCREEN_TEXTURE, uv).rgb;

}
