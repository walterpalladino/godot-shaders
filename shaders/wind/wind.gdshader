shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D material_texture : hint_default_white; 
uniform float alpha_cut_off : hint_range(0.0, 1.0) = 0.5;
uniform vec3 color : source_color;

uniform vec2 wind_strength = vec2(0.0);
uniform float wind_frequency = 0.0f;
uniform float min_height : hint_range(0.0, 5.0, 0.1) = 1.0f;
uniform float max_height : hint_range(0.0, 10.0, 0.1) = 5.0f;


void vertex() {
	
	vec3 position = VERTEX;

	position.x += wind_strength.x * sin(TIME * wind_frequency) * (1.0 - UV.y);
	position.z += wind_strength.y * cos(TIME * wind_frequency) * (1.0 - UV.y);
	
	float factor = 0.0;
	if ((max_height > min_height) && (VERTEX.y >= min_height)) {
		factor = (VERTEX.y - min_height) / (max_height - min_height);
	}
	factor = 1.0 - factor;
	factor = clamp(factor, 0.0, 1.0);
		
	VERTEX = mix(position, VERTEX, factor);
	//VERTEX = position;
}

void fragment() {
	vec4 texture_color = texture(material_texture, UV);
	ALBEDO = color * texture_color.rgb;

	//ALPHA = texture_color.a;
	ALPHA *= texture_color.a ;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut_off;
	
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
