//	Poor man AO shader
shader_type spatial;

render_mode specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform sampler2D base_texture : hint_default_white;
uniform float ao_intensity : hint_range(0.0, 1.0) = 0.5;

varying vec3 local_normal;


void vertex() {
	// Pass normal to fragment stage
    local_normal = NORMAL;
}

void fragment() {


	vec3 texture_color = texture(base_texture, UV).rgb ;

	ALBEDO = base_color.rgb * texture_color;
    
	
    // Example 1: Procedural cavity/slope-based ambient occlusion
    // Compares normal direction against upward world/object vector
    float cavity = dot(local_normal, vec3(0.0, 1.0, 0.0));
    
    // Remap and invert to darken inward-facing or downward areas (crevices)
    float procedural_ao = clamp(1.0 - (cavity * 0.5 + 0.5), 0.0, 1.0);
    
    // Alternatively, if using vertex colors for baked data:
    // float procedural_ao = COLOR.r;

    // Apply to Godot's built-in AO pipeline
    AO = mix(1.0, procedural_ao, ao_intensity);
    AO_LIGHT_AFFECT = 1.0;

}
