//	The shader makes a cut based on the camera direction.
//	the invert_direction flag is used to invert the direction from left to right.

shader_type spatial;

render_mode unshaded, depth_draw_always;


uniform sampler2D material_texture : hint_default_white;
uniform float alpha_cut_off : hint_range(0.0, 1.0) = 0.5;
uniform vec3 color : source_color;
uniform vec3 dark_color : source_color;
uniform float color_cut_off : hint_range(0.0, 1.0) = 0.5;


group_uniforms Lightning;

uniform bool invert_direction = false;

//	Light direction: coming from camera or from a point in space
uniform bool use_custom_direction = false;

//	Light direction: coming from camera or from a point in space
uniform vec3 light_angle_deg = vec3(-60.0, 150.0, 0.0);

varying vec3 light_dir_vs;

// e = Euler angles in radians (x = pitch, y = yaw, z = roll)
vec3 euler_to_dir(vec3 e) {
    float sx = sin(e.x), cx = cos(e.x);
    float sy = sin(e.y), cy = cos(e.y);
    return vec3(-cx * sy, sx, -cx * cy);
}

void vertex() {	
	// travel direction in world space, then into view space (where NORMAL lives)
    vec3 dir_ws = euler_to_dir(radians(light_angle_deg));
    light_dir_vs = normalize(mat3(VIEW_MATRIX) * dir_ws);
}

void fragment() {

	vec4 texture_color = texture(material_texture, UV);

	vec3 world_view = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;
	//	Get the angle between the surface and the light
	//	to calculate how much the light affects it
	float _dot = dot(normalize(world_view), normalize(NORMAL));
	_dot = clamp(_dot, 0.0, 1.0);

	if (use_custom_direction) {
		vec3 n = normalize(NORMAL);
    	_dot = max(dot(n, light_dir_vs), 0.0);
	}

	vec3 _color = dark_color;
	if (_dot < color_cut_off) {
		_color = color * texture_color.rgb;
	}

	if (invert_direction) {
		_color = color * texture_color.rgb;
		if (_dot < color_cut_off) {
			_color = dark_color;
		}
	}

	ALBEDO = _color;
	
	ALPHA = texture_color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut_off;
}
