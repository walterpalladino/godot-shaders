//	Inspired by https://godotshaders.com/shader/pencil-screen-space-shader/

shader_type spatial;
//render_mode unshaded;

uniform vec3 albedo : source_color = vec3(1.0) ;
uniform sampler2D texture_material;

uniform sampler2D texture_pattern;
uniform vec2 pattern_tiling = vec2(1.0, 1.0);
uniform float threshold_1: hint_range(0.0, 1.0) = 0.75;
uniform float threshold_2: hint_range(0.0, 1.0) = 0.50;
uniform float threshold_3: hint_range(0.0, 1.0) = 0.25;
uniform float threshold_4: hint_range(0.0, 1.0) = 0.05;


const float C2_SQRT2 = 0.707106781;
const mat2 ROT_45 = mat2(vec2(C2_SQRT2, -C2_SQRT2), vec2(C2_SQRT2, C2_SQRT2));
const vec4 COLOR_WHITE = vec4(1.0, 1.0, 1.0, 1.0);

const float brightness = 1.0;

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

	//patternUV1 = vec2(-uv.x, uv.y) ;
	//pCol1 = texture(u_patternTexture, patternUV1);
	//pCol1 = vec4(0.0);
	//return pCol1;
}

void fragment() {

	vec3 vertex_color = albedo * brightness;
	float intensity = getIntensity(vertex_color);
	//vec3 color = vec3(intensity);
	
	vec4 pattern_color = getPatternColor(SCREEN_UV, intensity);
	//vec3 final_color = mix(color.rgb, vertex_color, 0.750);
	//vec3 final_color = color.rgb + vertex_color * 0.5;
	vec3 color = pattern_color.rgb;
	//ALBEDO = color;
	//ALBEDO = vec3(intensity);
	vec4 background_color = vec4(0.0, 0.0, 0.0, 1.0);
	ALBEDO = pattern_color.rgb * (intensity + 0.25);
	//ALBEDO = pattern_color.rgb * (intensity) * albedo;
//	ALBEDO = pattern_color.rgb;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	//ALPHA = color.a;
	//ALBEDO = albedo;
}

/*
void light() {
//    DIFFUSE_LIGHT = albedo;
	//DIFFUSE_LIGHT += dot(NORMAL, LIGHT) * ATTENUATION * ALBEDO;
	DIFFUSE_LIGHT += dot(NORMAL, LIGHT) * ATTENUATION;
}
*/