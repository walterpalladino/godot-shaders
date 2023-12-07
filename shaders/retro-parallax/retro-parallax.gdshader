shader_type spatial;

render_mode blend_mix;

group_uniforms layers;
uniform sampler2D layer_1_texture : hint_default_transparent; 
uniform sampler2D layer_2_texture : hint_default_transparent; 
uniform sampler2D layer_3_texture : hint_default_transparent; 

uniform float layer_1_speed = 1.0f;
uniform float layer_2_speed = 1.0f;
uniform float layer_3_speed = 1.0f;


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

	vec3 color = layer_1_color.rgb;
	if (layer_2_color.a > 0.0) {
		color = mix(color, layer_2_color.rgb, layer_2_color.a);
	}
	if (layer_3_color.a > 0.0) {
		color = mix(color, layer_3_color.rgb, layer_3_color.a);
	}
	
	ALBEDO = color;
}
