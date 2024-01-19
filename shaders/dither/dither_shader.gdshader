//	Based on : https://godotshaders.com/shader/retro-dither/

shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley;


uniform vec4 color : source_color = vec4(0.75,0.75,0.75, 1.0);
uniform sampler2D texture_material : source_color,filter_linear_mipmap,repeat_enable;
uniform float alpha_cut_off : hint_range(0.0, 1.0) = 0.5;

uniform float shade_tweak = 0.5;
uniform float light_tweak = 1.0;
uniform float sharpness = 1.0;
uniform float scale = 2.0;


const mat4 dither = mat4(
	vec4(0.0, 0.5333333333, 0.1333333333,  0.6666666667),
	vec4(0.8, 0.2666666667, 0.9333333333,  0.4),
	vec4(0.2, 0.7333333333, 0.06666666667, 0.6),
	vec4(1.0, 0.4666666667, 0.8666666667,  0.3333333333)
);

float sample(vec2 coord, float alpha, float shade, float lit) {
	int x = int(mod(coord.x, 4));
	int y = int(mod(coord.y, 4));
	if (y == 0) {
		if (x == 0 && dither[0][0] >= alpha) {
			return shade;
		} else if (x == 1 && dither[0][1] >= alpha) {
			return shade;
		} else if (x == 2 && dither[0][2] >= alpha) {
			return shade;
		} else if (x == 3 && dither[0][3] >= alpha) {
			return shade;
		}
	} else if (y == 1) {
		if (x == 0 && dither[1][0] >= alpha) {
			return shade;
		} else if (x == 1 && dither[1][1] >= alpha) {
			return shade;
		} else if (x == 2 && dither[1][2] >= alpha) {
			return shade;
		} else if (x == 3 && dither[1][3] >= alpha) {
			return shade;
		}
	} else if (y == 2) {
		if (x == 0 && dither[2][0] >= alpha) {
			return shade;
		} else if (x == 1 && dither[2][1] >= alpha) {
			return shade;
		} else if (x == 2 && dither[2][2] >= alpha) {
			return shade;
		} else if (x == 3 && dither[2][3] >= alpha) {
			return shade;
		}
	} else if (y == 3) {
		if (x == 0 && dither[3][0] >= alpha) {
			return shade;
		} else if (x == 1 && dither[3][1] >= alpha) {
			return shade;
		} else if (x == 2 && dither[3][2] >= alpha) {
			return shade;
		} else if (x == 3 && dither[3][3] >= alpha) {
			return shade;
		}
	}
	return lit;
}


void vertex() {
}

void fragment() {
	vec4 material_tex = texture(texture_material, UV);
	ALBEDO = color.rgb * material_tex.rgb;
	ALPHA *= material_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut_off;
}

void light() {
	float f = ATTENUATION;
	float a = sample(
		FRAGCOORD.xy * (1.0 / scale),
		clamp(dot(NORMAL, LIGHT) + sharpness, 0.0, 1.0 + sharpness) * f,
		shade_tweak,
		light_tweak);
	DIFFUSE_LIGHT += ALBEDO * a;
}
