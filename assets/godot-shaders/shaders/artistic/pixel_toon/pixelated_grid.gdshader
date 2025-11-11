shader_type spatial;

render_mode unshaded, depth_draw_opaque;

uniform vec3 albedo : source_color;
uniform int pixel_size : hint_range(2, 32, 1) = 4;
uniform bool only_horizontal_lines = false;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;


void fragment() {

	//	Get coordinate sample based on a grid size pixel_size
	float x = float(int(FRAGCOORD.x) % pixel_size);
	float y = float(int(FRAGCOORD.y) % pixel_size);

	//	Get the center position on that grid
	x = FRAGCOORD.x + floor(float(pixel_size) / 2.0) - x;
	y = FRAGCOORD.y + floor(float(pixel_size) / 2.0) - y;

	//	Get texture color from the screen and from the new calculated position
	vec3 texture_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	vec3 pixelated_texture_color = texture(SCREEN_TEXTURE, vec2(x, y) / (VIEWPORT_SIZE)).rgb;

	vec3 color = texture_color;

	// SCREEN_UV gives normalized UV coordinates (0-1)
    // SCREEN_PIXEL_SIZE gives the size of one pixel in UV coordinates
    // Calculate the screen pixel coordinates
	vec2 SCREEN_PIXEL_SIZE = 1.0 / VIEWPORT_SIZE;
    vec2 screen_pixel_coord = SCREEN_UV / SCREEN_PIXEL_SIZE;
	ivec2 screen_pixel_coord_int = ivec2(screen_pixel_coord);

	if (screen_pixel_coord_int.x % pixel_size == 0  && !only_horizontal_lines) {
		ALBEDO = albedo;
	} else if (screen_pixel_coord_int.y % pixel_size == 0) {
		ALBEDO = albedo;
	} else {
		ALBEDO = pixelated_texture_color;
	}

}
