shader_type spatial;

render_mode blend_mix, unshaded, ambient_light_disabled, cull_back, fog_disabled,shadows_disabled, specular_disabled;

group_uniforms layers;
uniform sampler2D layer_1_texture : hint_default_transparent, filter_nearest;
uniform sampler2D layer_2_texture : hint_default_transparent, filter_nearest;
uniform sampler2D layer_3_texture : hint_default_transparent, filter_nearest;

uniform float layer_1_speed = 1.0f;
uniform float layer_1_color_strength : hint_range(0.0, 1.0, 0.1) = 1.0f;

uniform float layer_2_speed = 1.0f;
uniform float layer_2_color_strength : hint_range(0.0, 1.0, 0.1) = 1.0f;

uniform float layer_3_speed = 1.0f;
uniform float layer_3_color_strength : hint_range(0.0, 1.0, 0.1) = 1.0f;

void fragment() {

	vec2 uv1 = UV;
	uv1.x += TIME * layer_1_speed;
	vec2 uv2 = UV;
	uv2.x += TIME * layer_2_speed;
	vec2 uv3 = UV;
	uv3.x += TIME * layer_3_speed;

	vec4 layer_1_color = texture(layer_1_texture, uv1);
	vec4 layer_2_color = texture(layer_2_texture, uv2);
	vec4 layer_3_color = texture(layer_3_texture, uv3);

	vec3 color = layer_1_color.rgb * layer_1_color_strength;
	if (layer_2_color.a > 0.0) {
		color = mix(color, layer_2_color.rgb * layer_2_color_strength, layer_2_color.a);
	}
	if (layer_3_color.a > 0.0) {
		color = mix(color, layer_3_color.rgb * layer_3_color_strength, layer_3_color.a);
	}

	ALBEDO = color;
}
