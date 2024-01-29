shader_type spatial;

//render_mode cull_disabled, depth_draw_always;

uniform vec3 color1 : source_color = vec3(0.0,0.0,0.0);
uniform vec3 color2 : source_color = vec3(1.0,1.0,1.0);

uniform float opacity : hint_range(0.0, 1.0, 0.01) = 1.0;

uniform vec3 center = vec3(0.0,0.0,0.0);
uniform vec3 scale = vec3(1.0,1.0,1.0);

uniform float mortar_percentile = 0.15;

uniform float smoothness : hint_range(0.0, 1.0, 0.1) = 0.5;


vec3 get_color(vec3 POINT)
{
	POINT.x = POINT.x - center.x;
	POINT.y = POINT.y - center.y;
	POINT.z = POINT.z - center.z;

	POINT.x = abs(mod(POINT.x + .001f, scale.x));
	POINT.y = abs(mod(POINT.y + .001f, scale.y));
	POINT.z = abs(mod(POINT.z + .001f, scale.z));

	if (((POINT.x > 0.0) && (POINT.x < mortar_percentile * scale.x)) ||
		((POINT.y > 0.0) && (POINT.y < mortar_percentile * scale.y)) ||
		((POINT.z > 0.0) && (POINT.z < mortar_percentile * scale.z)))
	{
		return color1;
	}
	else
	{
		return color2;
	}
}


void fragment() {

	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ALBEDO = get_color(pixel_world_position);

	ALPHA = opacity;
	
	ROUGHNESS = 1.0 - smoothness;
}

