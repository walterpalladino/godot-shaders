//	The shader makes a cut based on the camera direction.
//	the invert_direction flag is used to invert the direction from left to right.

shader_type spatial;

render_mode unshaded;


uniform vec3 color : source_color;
uniform vec3 dark_color : source_color;
uniform float cut_off : hint_range(0.0, 1.0) = 0.5;
uniform bool invert_direction = false;

void fragment() {

	vec3 world_view = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;	
	
	float _dot = dot(normalize(world_view), normalize(NORMAL));
	_dot = clamp(_dot, 0.0, 1.0);

	vec3 _color = dark_color;	
	if (_dot < cut_off) {
		_color = color;
	}
	
	if (invert_direction) {
		_color = color;
		if (_dot < cut_off) {
		_color = dark_color;
	}
	}
	
	ALBEDO = _color;
}
