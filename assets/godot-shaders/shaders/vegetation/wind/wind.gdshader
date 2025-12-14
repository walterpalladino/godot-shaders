shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D material_texture : source_color,filter_linear_mipmap;
uniform sampler2D texture_normal : hint_normal;
uniform float normal_strength : hint_range(0.0, 1.0, 0.01) = 0.0;

uniform float alpha_cut_off : hint_range(0.0, 1.0) = 0.5;
uniform vec3 color : source_color;

uniform vec2 wind_strength = vec2(0.0);
uniform float wind_frequency = 0.0f;
uniform float min_height : hint_range(0.0, 5.0, 0.1) = 1.0f;
uniform float max_height : hint_range(0.0, 10.0, 0.1) = 5.0f;



void vertex() {

	//	Will get the noise based on the vertex world position
	vec3 vertex_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 position = VERTEX;

	position.x += wind_strength.x * sin(TIME * wind_frequency) * (1.0 - UV.y);
	position.z += wind_strength.y * cos(TIME * wind_frequency) * (1.0 - UV.y);

	//	How much will affect based on height
	float factor = 0.0;
	if ((max_height > min_height) && (VERTEX.y >= min_height)) {
		factor = (VERTEX.y - min_height) / (max_height - min_height);
	}
	factor = clamp(factor, 0.0, 1.0);

	VERTEX = mix(VERTEX, position, factor);
}

void fragment() {

	vec4 texture_color = texture(material_texture, UV);
	ALBEDO = color * texture_color.rgb;

	ALPHA *= texture_color.a ;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut_off;

	if (normal_strength > 0.0) {
		vec3 normal_texture_value = texture(texture_normal, UV).rgb;
		vec3 scaled_normal = normal_texture_value * normal_strength;
		NORMAL_MAP = scaled_normal;
	}

}
