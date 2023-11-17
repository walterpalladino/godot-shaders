shader_type spatial;

render_mode cull_disabled;
//render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;
//depth_test_disable;


uniform sampler2D shield_texture : hint_default_white; 
uniform vec4 shield_albedo : source_color = vec4(1.0);
uniform vec4 shield_emission : source_color = vec4(1.0);
uniform float emission_amount: hint_range(0.0, 24.0) = 5.0f; 
uniform float rim_steepness : hint_range(0.0f, 24.0f) = 3.0f; //higher values mean a smaller rim.


uniform vec3 uv_scale = vec3(1.0, 1.0, 0.0);
uniform vec3 uv_offset;

//uniform float pulsing_strength = 0.25;
//uniform float pulsing_speed = 1.0;

uniform float pattern_scroll_speed = 0.025;


void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
	
//	float pulse_distance = sin(TIME * pulsing_speed) * 0.1 * pulsing_strength;
//	VERTEX += NORMAL * pulse_distance;
}

void fragment() {
	
	float scrolling_time = TIME * pattern_scroll_speed;

	vec2 base_uv = UV + vec2(0.0, scrolling_time);

	vec4 albedo_tex = texture(shield_texture, base_uv);
	ALBEDO = shield_albedo.rgb * albedo_tex.rgb;
	//ALBEDO = shield_albedo.rgb * (vec3(1.0) - albedo_tex.rgb);
	EMISSION = shield_emission.rgb * emission_amount;
	float NdotV = dot(NORMAL, VIEW);
	float rim_light = pow(1.0 - NdotV, rim_steepness);
	ALPHA = rim_light * shield_emission.a / PI;
}
