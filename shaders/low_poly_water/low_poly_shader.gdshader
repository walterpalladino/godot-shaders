shader_type spatial;


uniform float metallic : hint_range(0.0,1.0) = 0; 
uniform float roughness : hint_range(0.0,1.0) = 0.02; 

uniform sampler2D wave;
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025; 
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;

//	Deep
uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law = 2.0;	//	Attenuation of light
uniform float depth_offset = -0.75;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


//	Varying variables
varying float height;
varying vec3 world_position;
varying vec3 v_view_pos;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_position.xz /  noise_scale + TIME * time_scale).r;
	VERTEX.y += height * height_scale;

	// get the view pos for the low poly normals
	v_view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;
}

void fragment() {
	
	//	Depth calculations
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp((depth+VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);	
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color, depth_blend_power);

	ALBEDO = color;
	
	METALLIC = metallic;
	ROUGHNESS = roughness;

	vec3 xTangent = dFdx( v_view_pos );
    vec3 yTangent = dFdy( v_view_pos );
    NORMAL = normalize( cross( xTangent, yTangent ) );
	
}
