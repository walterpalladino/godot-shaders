shader_type spatial;


uniform vec3 color1 : source_color = vec3(0.0,0.0,0.0);
uniform vec3 color2 : source_color = vec3(1.0,1.0,1.0);

uniform float opacity : hint_range(0.0, 1.0, 0.01) = 1.0;

uniform vec3 center = vec3(0.0,0.0,0.0);
uniform vec3 scale = vec3(1.0,1.0,1.0);

uniform float smoothness : hint_range(0.0, 1.0, 0.1) = 0.5;

uniform float mortar_percentile = 0.15;


vec3 get_color(vec3 POINT)
{
	
	POINT.x = POINT.x - center.x;
	POINT.y = POINT.y - center.y;
	POINT.z = POINT.z - center.z;

	if (scale.x != 0.0)
		POINT.x = (POINT.x + .001f) / scale.x;
	else
		POINT.x = 0.0;
	if (scale.y != 0.0)
		POINT.y = (POINT.y + .001f) / scale.y;
	else
		POINT.y = 0.0;
	if (scale.z != 0.0)
		POINT.z = (POINT.z + .001f) / scale.z;
	else
		POINT.z = 0.0;

	POINT.x = abs(mod(POINT.x, 1.0f));
	POINT.y = abs(mod(POINT.y, 1.0f));
	POINT.z = abs(mod(POINT.z, 1.0f));
	
	if ((POINT.y < 1.0 - mortar_percentile) && (POINT.y > 0.5))
	{
		if ((POINT.x > 0.5 * mortar_percentile) &&
			(POINT.x < 1.0 - 0.5 * mortar_percentile))

			if (POINT.z > mortar_percentile)
				return color1;
	}
	else
	if (POINT.y < 0.5 - mortar_percentile)
	{
		if ((POINT.x < 0.5 - 0.5 * mortar_percentile) ||
			(POINT.x > 0.5 + 0.5 * mortar_percentile))
			if ((POINT.z < 0.5 - 0.5 * mortar_percentile) ||
				(POINT.z > 0.5 + 0.5 * mortar_percentile))
				return color1;
	}
	
	return color2;
}


void fragment() {

	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ALBEDO = get_color(pixel_world_position);

	ALPHA = opacity;
	
	ROUGHNESS = 1.0 - smoothness;
}
