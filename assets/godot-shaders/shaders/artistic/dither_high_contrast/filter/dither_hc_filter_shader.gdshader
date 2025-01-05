shader_type spatial;

render_mode unshaded, depth_draw_opaque;

#include "res://assets/godot-shaders/shaders/includes/color_utils.gdshaderinc"

group_uniforms input;
uniform float brightness : hint_range(0.01, 4.0, 0.01) = 1.0;
uniform float contrast : hint_range(0.01, 2.0, 0.01)= 1.0;
uniform float saturation : hint_range(0.0, 1.0, 0.01) = 1.0;

group_uniforms output;
uniform float sharpness = 1.0;
uniform int scale : hint_range(1, 10, 1) = 2;
uniform float light_base : hint_range(-2.0, 2.0, 0.1) = 0.0;
uniform float light_strength : hint_range(0.01, 2.0, 0.01) = 1.0;



uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

const mat4 dither = mat4(
	vec4(0.0, 0.5333333333, 0.1333333333,  0.6666666667),
	vec4(0.8, 0.2666666667, 0.9333333333,  0.4),
	vec4(0.2, 0.7333333333, 0.06666666667, 0.6),
	vec4(1.0, 0.4666666667, 0.8666666667,  0.3333333333)
);

bool is_shaded(vec2 coord, float alpha) {

	int x = int(mod(coord.x, 4));
	int y = int(mod(coord.y, 4));

	if (y == 0) {
		if (x == 0 && dither[0][0] >= alpha) {
			return false;
		} else if (x == 1 && dither[0][1] >= alpha) {
			return false;
		} else if (x == 2 && dither[0][2] >= alpha) {
			return false;
		} else if (x == 3 && dither[0][3] >= alpha) {
			return false;
		}
	} else if (y == 1) {
		if (x == 0 && dither[1][0] >= alpha) {
			return false;
		} else if (x == 1 && dither[1][1] >= alpha) {
			return false;
		} else if (x == 2 && dither[1][2] >= alpha) {
			return false;
		} else if (x == 3 && dither[1][3] >= alpha) {
			return false;
		}
	} else if (y == 2) {
		if (x == 0 && dither[2][0] >= alpha) {
			return false;
		} else if (x == 1 && dither[2][1] >= alpha) {
			return false;
		} else if (x == 2 && dither[2][2] >= alpha) {
			return false;
		} else if (x == 3 && dither[2][3] >= alpha) {
			return false;
		}
	} else if (y == 3) {
		if (x == 0 && dither[3][0] >= alpha) {
			return false;
		} else if (x == 1 && dither[3][1] >= alpha) {
			return false;
		} else if (x == 2 && dither[3][2] >= alpha) {
			return false;
		} else if (x == 3 && dither[3][3] >= alpha) {
			return false;
		}
	}
	return true;
}


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec3 texture_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	//Brightness adjustment
	texture_color = mix(vec3(0.0), texture_color, brightness);
	//Contrast adjustment
    texture_color = mix(vec3(0.5), texture_color, contrast);
	//	Saturation
	texture_color = mix(vec3(dot(vec3(1.0), texture_color) * 0.33333), texture_color, saturation);

	float gray_value = intensity_from_color(texture_color.rgb);

	bool shaded = is_shaded(
		FRAGCOORD.xy * (1.0 / float(scale)),
		light_base + clamp(gray_value + sharpness, 0.0, 1.0 + sharpness) * light_strength);

	vec3 color = vec3(1.0);
	if (!shaded) {
		color = vec3(0.0);
	}

	ALBEDO = vec3(gray_value);
	ALBEDO = color;
}
