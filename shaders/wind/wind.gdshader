shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D material_texture : source_color,filter_linear_mipmap;
uniform float alpha_cut_off : hint_range(0.0, 1.0) = 0.5;
uniform vec3 color : source_color;

uniform vec2 wind_strength = vec2(0.0);
uniform float wind_frequency = 0.0f;
uniform float min_height : hint_range(0.0, 5.0, 0.1) = 1.0f;
uniform float max_height : hint_range(0.0, 10.0, 0.1) = 5.0f;

//	Noise
vec2 hash( vec2 x )
{
    vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

void vertex() {

	//	Will get the noise based on the vertex world position
	vec3 vertex_world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 tmp = vertex_world_position.xz;
	tmp += TIME * wind_strength;

	vec3 position = VERTEX;

	float f = 0.0;
    f = noise( wind_frequency * tmp );
    f = 0.5 + 0.5 * f;

	position.x += f;
	position.z += f;
	//position.x += wind_strength.x * sin(TIME * wind_frequency) * (1.0 - UV.y);
	//position.z += wind_strength.y * cos(TIME * wind_frequency) * (1.0 - UV.y);

	//	How much will affect based on height
	float factor = 0.0;
	if ((max_height > min_height) && (VERTEX.y >= min_height)) {
		factor = (VERTEX.y - min_height) / (max_height - min_height);
	}
	factor = clamp(factor, 0.0, 1.0);

	VERTEX = mix(VERTEX, position, factor);
}

void fragment() {
	vec4 texture_color = texture(material_texture, UV);
	ALBEDO = color * texture_color.rgb;

	ALPHA *= texture_color.a ;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut_off;

	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
