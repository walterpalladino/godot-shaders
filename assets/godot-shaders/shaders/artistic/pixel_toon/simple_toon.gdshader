// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.

shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;


uniform float roughness : hint_range(0.0, 1.0);

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);


void vertex() {
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;
}
