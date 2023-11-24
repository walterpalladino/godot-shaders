shader_type spatial;

render_mode cull_disabled, blend_mix, depth_draw_always;


uniform sampler2D shield_texture : hint_default_white; 
uniform vec4 shield_albedo : source_color = vec4(1.0);
uniform vec4 shield_emission : source_color = vec4(1.0);
uniform float emission_amount : hint_range(0.0, 24.0) = 5.0f; 
uniform float rim_steepness : hint_range(0.0f, 24.0f) = 3.0f; //higher values mean a smaller rim.

uniform float pulsing_strength : hint_range(0.0, 1.0) = 0.5;
uniform float pulsing_speed : hint_range(0.0, 5.0, 0.1) = 2.0;

uniform float energy_strength : hint_range(0.0, 10.0, 0.1) = 1.0;

void vertex() {
	float pulse_distance = (sin(TIME * pulsing_speed) + 1.0) * pulsing_strength * 0.1;
	VERTEX += NORMAL * pulse_distance;
}

void fragment() {
	
	//if (!FRONT_FACING) {
		//NORMAL = -NORMAL;
	//}
	
	vec4 albedo_tex = texture(shield_texture, UV);
	//ALBEDO = shield_albedo.rgb ;//* albedo_tex.rgb;
	//ALBEDO = albedo_tex.rgb;

	//EMISSION = shield_emission.rgb * emission_amount;

	float NdotV = dot(NORMAL, VIEW);
	float rim_light = pow(1.0 - NdotV, rim_steepness);
	ALPHA = rim_light * shield_emission.a * albedo_tex.a;
	
	float grad = sin(VERTEX.y * 5.0 - TIME * 10.0) ;
	grad = (grad + 1.0) * 0.5;
	grad = grad * energy_strength;

	ALBEDO = shield_albedo.rgb + grad;

	EMISSION = shield_emission.rgb * (emission_amount + grad);
	
}
