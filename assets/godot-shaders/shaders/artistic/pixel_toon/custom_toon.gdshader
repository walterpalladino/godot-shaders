shader_type spatial;

render_mode unshaded, depth_draw_opaque, cull_back ;


group_uniforms Material;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float albedo_dark : hint_range(0.0, 1.0, 0.01) = 0.5;


group_uniforms Lightning;

//	Light direction: coming from camera or from a point in space
uniform bool use_custom_direction = false;
uniform vec3 custom_direction = vec3(0.0, 0.0, 1.0);

uniform float dark_cut_off : hint_range(0.0, 1.0) = 0.5;

group_uniforms Specular;

uniform float specular_size : hint_range(0.0, 100.0) = 50.0;
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.8;
uniform vec3 specular_color : source_color = vec3(1.0);


void vertex() {
}

void fragment() {

	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);


	vec3 world_view = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;

	if (use_custom_direction) {
		world_view = normalize(custom_direction);
	}

	//	Get the angle between the surface and the light
	//	to calculate how much the light affects it
	float diffuse_factor = dot(normalize(world_view), normalize(NORMAL));
	diffuse_factor = clamp(diffuse_factor, 0.0, 1.0);

	vec3 diffuse_color = albedo.rgb * albedo_tex.rgb;

	if (diffuse_factor < dark_cut_off) {
		diffuse_color = diffuse_color * albedo_dark;
	}

	// Custom Toon Specular
    vec3 light_dir = world_view;
    vec3 view_dir = normalize(CAMERA_POSITION_WORLD - VERTEX);
    vec3 half_vector = normalize(light_dir + view_dir);

    float NdotH = dot(NORMAL, half_vector);
    float specular_power = pow(max(0.0, NdotH), specular_size); // Adjust size with specular_size

    // Apply stepping for toon effect
    float stepped_specular = step(0.5, specular_power); // Hard cut-off at 0.5 power

    vec3 custom_specular = stepped_specular * specular_color.rgb * specular_intensity;

	//
	ALBEDO = diffuse_color + custom_specular;
}
