shader_type spatial;

//render_mode unshaded;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color;

uniform float rim_power = 1.0;
uniform float rim_width : hint_range(0.0, 1.0, 0.01) = 0.005;

uniform float roughness : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec3 view_normal = (VIEW_MATRIX * vec4(world_normal, 0.0)).xyz;

	float rim = pow(view_normal.z, rim_power);

	rim = clamp(rim, 0.0, 1.0);
	rim = step(rim_width, rim);

	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	vec3 color = albedo.rgb * albedo_tex.rgb ;

	ALBEDO	= color * rim;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;

}


//	Force hard shadows cut
//void light() {
//	float attenuation = step(0.001, ATTENUATION);
//	float NdotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
//	vec3 diffuse_light = NdotL * attenuation * LIGHT_COLOR * 0.5;
//	DIFFUSE_LIGHT += diffuse_light;
//}
