// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 albedo_a : source_color = vec3(1.0);
uniform vec3 albedo_b : source_color = vec3(0.0);
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
//varying vec3 uv1_triplanar_pos;

//uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv_power_normal;

uniform float uv_scale : hint_range(0.01, 100.0, 0.01) = 1.0;

void vertex() {
}


void fragment() {
	
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;

	vec4 albedo_tex = texture(texture_albedo, pixel_world_position.xz * uv_scale);
	if (abs(world_normal.y) < 0.001) {
		//	Special cases for vertical faces
		if (abs(world_normal.x) < abs(world_normal.z)) {
			albedo_tex = texture(texture_albedo, pixel_world_position.xy * uv_scale);			
		}
		else {
			albedo_tex = texture(texture_albedo, pixel_world_position.zy * uv_scale);			
		}
	}
	
	vec3 albedo_color = mix(albedo_a, albedo_b, albedo_tex.r);
	
	ALBEDO = albedo_color.rgb ;

	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;
}
