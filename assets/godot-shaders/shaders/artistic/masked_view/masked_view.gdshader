shader_type spatial;

render_mode unshaded, depth_draw_opaque;


uniform sampler2D mask_texture : source_color, hint_default_transparent;
uniform vec2 mask_scale = vec2(1.0, 1.0);

uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


void vertex() {
	POSITION = vec4(vec3(VERTEX.x, VERTEX.y, 0.1), 1.0);
}

void fragment() {

	vec2 uv = SCREEN_UV;
	vec2 uv_fixed_on_center = (uv - 0.5) * 2.0;

	vec3 screen_color = texture(SCREEN_TEXTURE, uv).rgb;

	vec3 mask_color = texture(mask_texture, uv).rgb;

	float cut = mask_color.r;

	vec3 final_color = mix(background_color.rgb, screen_color, cut);

	ALBEDO = final_color;

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
