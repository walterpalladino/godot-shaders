shader_type spatial;

render_mode unshaded, cull_back;


uniform sampler2D material_texture : hint_default_white;
uniform vec4 base_color : source_color = vec4(0.75,0.75,0.75, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float pixel_size : hint_range(1.0, 64.0, 0.1) = 1.0;

uniform float color_cut_off : hint_range(0.0, 1.0) = 0.5;

group_uniforms Lightning;

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

	ivec2 pixel_pos = ivec2(round(FRAGCOORD.xy / pixel_size));
	bool is_shadow_pixel = ((pixel_pos.x % 2) == 0) != ((pixel_pos.y % 2) == 0);

	vec4 texture_color = texture(material_texture, UV);

	vec3 world_view = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;

	//	Get the angle between the surface and the light
	//	to calculate how much the light affects it
	float _dot = dot(normalize(world_view), normalize(NORMAL));
	_dot = clamp(_dot, 0.0, 1.0);
	
	if (use_custom_direction) {
		vec3 n = normalize(NORMAL);
    	_dot = max(dot(n, -light_dir_vs), 0.0);
	}

	_dot = step(color_cut_off, _dot);

	vec3 _color = base_color.rgb * texture_color.rgb;
	if (_dot < color_cut_off && !is_shadow_pixel) {
		_color = shadow_color.rgb;
	}

	ALBEDO = _color;
}
