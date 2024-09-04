shader_type spatial;

uniform vec3 albedo : source_color ;
uniform vec3 albedo2 : source_color ;

uniform float roughness : hint_range(0.0,1.0) = 0.02; 

uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;

//	Varying variables
varying vec3 world_position;

void vertex () {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {


	METALLIC = 0.0;
	ROUGHNESS = roughness;
	
	//	Blend
	vec3 normal_blend = mix(texture(texture_normal, world_position.xz).rgb, texture(texture_normal2, world_position.xz).rgb, 0.5);
	NORMAL_MAP = normal_blend;

	ALBEDO = albedo;
	float color_blend = dot(NORMAL, VIEW);
	vec3 surface_color = mix(albedo, albedo2, 1.0 - color_blend);
	surface_color = clamp(surface_color,vec3(0.0),vec3(1.0));
	ALBEDO = surface_color;

}
