shader_type spatial;

render_mode unshaded, depth_draw_opaque;

uniform int pixel_size : hint_range(1, 100, 1) = 4;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	//	Get coordinate sample based on a grid size pixel_size
	float x = float(int(FRAGCOORD.x) % pixel_size);
	float y = float(int(FRAGCOORD.y) % pixel_size);

	//	Get the center position on that grid
	x = FRAGCOORD.x + floor(float(pixel_size) / 2.0) - x;
	y = FRAGCOORD.y + floor(float(pixel_size) / 2.0) - y;

	//	Get texture color from the screen and from the new calculated position
	vec4 texture_color = texture(SCREEN_TEXTURE,SCREEN_UV*1.0);
	vec4 pixelated_texture_color = texture(SCREEN_TEXTURE, vec2(x, y) / (VIEWPORT_SIZE));

	//	Respect transparency
	if (pixelated_texture_color.a==0.0 && texture_color.a==0.0){
		discard;
	}

	//	Set the color
	ALBEDO = pixelated_texture_color.rgb;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
