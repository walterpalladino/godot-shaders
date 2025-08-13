shader_type spatial;

render_mode unshaded, fog_disabled;

uniform sampler2D SCREEN_TEXTURE : source_color, hint_screen_texture, filter_nearest;
uniform sampler2D NORMAL_TEXTURE : source_color, hint_normal_roughness_texture, filter_nearest;
uniform sampler2D DEPTH_TEXTURE : source_color, hint_depth_texture, filter_nearest;

uniform float depth_treshold : hint_range(0.01, 20.0, 0.01) = 0.05;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 8.0, 0.1) = 1.0;
uniform bool use_only_normals = true;

vec3 get_screen(vec2 screen_uv)
{
	return texture(SCREEN_TEXTURE, screen_uv).rgb;
}

vec3 get_normal(vec2 screen_uv)
{
	return texture(NORMAL_TEXTURE, screen_uv).rgb * 2.0 - 1.0;
}

float get_linear_depth(vec2 screen_uv, mat4 inv_projection_matrix)
{
	float depth = texture(DEPTH_TEXTURE, screen_uv).r;
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
	vec4 view_space = inv_projection_matrix * vec4(ndc, 1.0);
	view_space.xyz /= -view_space.w;
	return view_space.z;
}

void fragment() {

	// SCREEN TEXTURE
	vec3 screen_color = get_screen(SCREEN_UV);

	// NORMAL
	vec3 screen_normal = get_normal(SCREEN_UV);

	// DEPTH
	float screen_depth = get_linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);

	// GET SURROUNDING TEXEL
	vec2 texel_size = outline_width / VIEWPORT_SIZE.xy;
	vec2 uvs[4]; // arrray containing the uvs of the surrounding pixel
	uvs[0] = vec2(SCREEN_UV.x, SCREEN_UV.y + texel_size.y );
	uvs[1] = vec2(SCREEN_UV.x, SCREEN_UV.y - texel_size.y );
	uvs[2] = vec2(SCREEN_UV.x + texel_size.x, SCREEN_UV.y);
	uvs[3] = vec2(SCREEN_UV.x - texel_size.x, SCREEN_UV.y);

	//EDGE DETECTION
	float depth_diff = 0.0;
	float normal_sum = 0.0;
	for (int i = 0; i < 4; i++)
	{
		float d = get_linear_depth(uvs[i], INV_PROJECTION_MATRIX);
		depth_diff += screen_depth - d;

		vec3 n = get_normal(uvs[i]);
		vec3 normal_diff = screen_normal - n;

		vec3 normal_edge_bias = vec3(1.0, 1.0, 1.0);
		float normal_bias_diff = dot(normal_diff, normal_edge_bias);
		float normal_indicator = smoothstep(-0.01, 0.01, normal_bias_diff);

		normal_sum += dot(normal_diff, normal_diff) * normal_indicator;
	}

	float depth_edge = step(depth_treshold, depth_diff);
	float outline = normal_sum;
	if (!use_only_normals) {
		outline += depth_edge;
	}
	outline = clamp(0.0, 1.0, outline);
	ALBEDO = mix(screen_color, outline_color.rgb, outline);
	ALPHA = mix(0.0, outline_color.a, outline);
}

