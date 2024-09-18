

group_uniforms noise;
uniform float sharpness : hint_range(0.0, 50.0, 0.01) = 10.0;
uniform float seed : hint_range(-100.0, 100.0, 0.01) = 0.0;
uniform float scale : hint_range(0.01, 20.0, 0.01) = 1.0;


vec3 hash(vec3 p)
{
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5,183.3,246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
    p = fract(sin(p) * 43758.5453123);
    return p;
}

float shard_noise(in vec3 p, in float _sharpness) {
    vec3 ip = floor(p);
    vec3 fp = fract(p);

    float v = 0., t = 0.;
    for (int z = -1; z <= 1; z++) {
        for (int y = -1; y <= 1; y++) {
            for (int x = -1; x <= 1; x++) {
                vec3 o = vec3(float(x), float(y), float(z));
                vec3 io = ip + o;
                vec3 h = hash(io);
                vec3 r = fp - (o + h);

                float w = exp2(-TAU*dot(r, r));
                // tanh deconstruction and optimization by @Xor
                float s = _sharpness * dot(r, hash(io + vec3(11, 31, 47)) - 0.5);
                v += w * s*inversesqrt(1.0+s*s);
                t += w;
            }
        }
    }
    return ((v / t) * .5) + .5;
}


vec4 get_noise( vec3 uv )
{
    //vec3 uv = vec3(_uv.x + TIME*timescale*hScrollSpeedFactor, _uv.y + TIME*timescale*vScrollSpeedFactor, TIME*timescale * .5 * entropyFactor);

    vec4 C = vec4(vec3(
            (shard_noise(128.0*uv,sharpness) * .03125) +
            (shard_noise(32.0*uv,sharpness) * .0625) +
            (shard_noise(16.0*uv,sharpness) * .125) +
            (shard_noise(8.0*uv,sharpness) * .25) +
            (shard_noise(4.0*uv,sharpness) * .5)
        ),1.);

	//C = clamp(C, 0.0, 1.0);

    return C;
}
