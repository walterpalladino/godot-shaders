shader_type spatial;

render_mode unshaded;


uniform sampler2D material_texture : hint_default_white;
uniform vec4 base_color : source_color = vec4(0.75,0.75,0.75, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float pixel_size : hint_range(1.0, 64.0, 0.1) = 1.0;

group_uniforms Lightning;

uniform bool invert_direction = false;

//	Light direction: coming from camera or from a point in space
uniform bool use_custom_direction = false;
uniform vec3 custom_direction = vec3(0.0, 0.0, 1.0);

uniform float color_cut_off : hint_range(0.0, 1.0) = 0.5;


varying bool is_shadow_pixel ;

void vertex() {
}

void fragment() {

	ivec2 pixel_pos = ivec2(round(FRAGCOORD.xy / pixel_size));
	is_shadow_pixel = ((pixel_pos.x % 2) == 0) != ((pixel_pos.y % 2) == 0);

	vec4 texture_color = texture(material_texture, UV);

	vec3 world_view = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;

	if (use_custom_direction) {
		world_view = normalize(custom_direction);
	}

	//	Get the angle between the surface and the light
	//	to calculate how much the light affects it
	float _dot = dot(normalize(world_view), normalize(NORMAL));
	_dot = clamp(_dot, 0.0, 1.0);

	vec3 _color = shadow_color.rgb;
	if (_dot < color_cut_off && !is_shadow_pixel) {
		_color = base_color.rgb * texture_color.rgb;
	}

	if (invert_direction) {
		_color = base_color.rgb * texture_color.rgb;
		if (_dot < color_cut_off && is_shadow_pixel) {
			_color = shadow_color.rgb;
		}
	}

	ALBEDO = _color;
}
