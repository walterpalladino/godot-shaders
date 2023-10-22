//	Inspired by https://godotshaders.com/shader/pencil-screen-space-shader/

shader_type spatial;

render_mode unshaded, depth_draw_opaque;


uniform sampler2D texture_pattern;
uniform vec2 pattern_tiling = vec2(1.0, 1.0);
uniform float threshold_1: hint_range(0.0, 1.0) = 0.75;
uniform float threshold_2: hint_range(0.0, 1.0) = 0.50;
uniform float threshold_3: hint_range(0.0, 1.0) = 0.25;
uniform float threshold_4: hint_range(0.0, 1.0) = 0.05;


const float C2_SQRT2 = 0.707106781;
const mat2 ROT_45 = mat2(vec2(C2_SQRT2, -C2_SQRT2), vec2(C2_SQRT2, C2_SQRT2));
const vec4 COLOR_WHITE = vec4(1.0, 1.0, 1.0, 1.0);


uniform float input_brightness : hint_range(0.0, 2.0) = 1.0;
uniform float input_contrast : hint_range(0.0, 2.0) = 1.0;

uniform float output_brightness : hint_range(0.0, 2.0) = 1.0;
uniform float output_contrast : hint_range(0.0, 2.0) = 1.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


//	Get color intensity (at pointgray scale)
float getIntensity(vec3 color)
{
	return 0.299*color.r + 0.587*color.g + 0.114*color.b;
}

vec4 getPatternColor(vec2 uv, float intensity)
{
	vec2 patternUV1 = fract(vec2(-uv.x, uv.y) * pattern_tiling);
	vec2 patternUV2 = fract(uv * pattern_tiling);
	vec2 patternUV3 = fract(ROT_45*(uv + vec2(0.2358, 0.9123)) * pattern_tiling);
	vec2 patternUV4 = fract((vec2(uv.x, -uv.y) + vec2(0.4123, 0.7218)) * pattern_tiling);
	vec4 pCol1 = texture(texture_pattern, patternUV1);
	vec4 pCol2 = texture(texture_pattern, patternUV2);
	vec4 pCol3 = texture(texture_pattern, patternUV3);
	vec4 pCol4 = texture(texture_pattern, patternUV4);
	
	if(intensity > threshold_1)
		return vec4(1.0, 1.0, 1.0, 1.0);
	if(intensity > threshold_2)
		return mix(pCol1, COLOR_WHITE, 0.5);
	if(intensity > threshold_3)
		return mix(pCol1*pCol2, COLOR_WHITE, 0.3);
	if(intensity > threshold_4)
		return mix(pCol1*pCol2*pCol3, COLOR_WHITE, 0.1);
	return pCol1*pCol2*pCol3*pCol4*0.8;

}

void fragment() {

	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	
	screen_color = mix(vec3(0.0), screen_color, input_brightness);
	screen_color = mix(vec3(0.5), screen_color, input_contrast);
	
	screen_color = clamp(screen_color, 0.0, 1.0);
	
	float intensity = getIntensity(screen_color);

	vec4 pattern_color = getPatternColor(SCREEN_UV, intensity);

	pattern_color = mix(vec4(0.0), pattern_color, output_brightness);
	pattern_color = mix(vec4(0.5), pattern_color, output_contrast);

	ALBEDO = pattern_color.rgb;

	METALLIC = 0.0;
	SPECULAR = 0.0;
}