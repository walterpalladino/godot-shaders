shader_type spatial;

render_mode unshaded;


uniform vec3 color : source_color;
uniform vec3 dark_color : source_color;
uniform float cut_off : hint_range(0.0, 1.0) = 0.5;


void fragment() {

	vec3 world_view = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;	
	
	float _dot = dot(normalize(world_view), normalize(NORMAL));
	_dot = clamp(_dot, 0.0, 1.0);

	vec3 _color = dark_color;	
	if (_dot < cut_off) {
		_color = color;
	}
	
	ALBEDO = _color;
}
