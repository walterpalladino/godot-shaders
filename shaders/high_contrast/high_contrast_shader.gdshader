//	The shader makes a cut based on the camera direction.
//	the invert_direction flag is used to invert the direction from left to right.

shader_type spatial;

render_mode unshaded;


uniform sampler2D material_texture ; 
uniform vec3 color : source_color;
uniform vec3 dark_color : source_color;
uniform float cut_off : hint_range(0.0, 1.0) = 0.5;
uniform bool invert_direction = false;

uniform bool use_custom_direction = false;
uniform vec3 custom_direction = vec3(0.0, 0.0, 1.0);

void fragment() {

	vec4 texture_color = texture(material_texture, UV);

	vec3 world_view = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;	

	if (use_custom_direction) {
		world_view = normalize(custom_direction);
	}

	float _dot = dot(normalize(world_view), normalize(NORMAL));
	_dot = clamp(_dot, 0.0, 1.0);

	vec3 _color = dark_color;	
	if (_dot < cut_off) {
		_color = color * texture_color.rgb;
	}
	
	if (invert_direction) {
		_color = color * texture_color.rgb;
		if (_dot < cut_off) {
		_color = dark_color;
	}
	}
	
	ALBEDO = _color;
}
