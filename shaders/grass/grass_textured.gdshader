shader_type spatial;

render_mode cull_disabled, unshaded, depth_draw_opaque;


uniform sampler2D grass_texture : source_color, hint_default_transparent;
uniform vec4 color_top : source_color = vec4(0.75,0.75,0.75, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.25,0.25,0.25, 1.0);
uniform float color_mix : hint_range(0.0, 10.0, 0.1) = 1.0f;

uniform vec2 wind_strength = vec2(0.0);
uniform float wind_frequency = 0.0f;


void vertex() {

	vec3 position = VERTEX;

	position.x += wind_strength.x * sin(TIME * wind_frequency) * pow((1.0 - UV.y), 5.0);
	position.z += wind_strength.y * cos(TIME * wind_frequency) * pow((1.0 - UV.y), 5.0);

	VERTEX = position;

}

void fragment() {

	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	vec4 color = texture(grass_texture,UV);
	vec3 tint = mix(color_top, color_bottom, pow(UV.y, color_mix)).rgb;

	ALBEDO = color.rgb * tint;
	ALPHA = color.a;
}
