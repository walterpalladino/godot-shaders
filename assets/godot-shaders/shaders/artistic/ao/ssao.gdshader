// ============================================================================
//  ssao_ega.gdshader — self-contained screen-space ambient occlusion
//  Godot 4.7 · Forward+ / Mobile · full-screen post-process quad
//
//  Depth-buffer only: view-space position AND face normals are reconstructed
//  from depth, so no G-buffer normals are needed and the occlusion comes out
//  hard-edged and faceted, which suits a flat-shaded low-poly pipeline.
//
//  Obscurance estimator: McGuire et al., "Scalable Ambient Obscurance" (2012).
//
//  compute_ao() below only touches depth_tex, SCREEN_UV, FRAGCOORD,
//  VIEWPORT_SIZE, PROJECTION_MATRIX and INV_PROJECTION_MATRIX — all available
//  in any spatial fragment shader — so you can lift it straight into your
//  existing edge-line / dither pass instead of running it as its own quad.
// ============================================================================

shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled, cull_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D depth_tex  : hint_depth_texture,  filter_nearest;

group_uniforms occlusion;
uniform float radius       : hint_range(0.05, 8.0, 0.01) = 0.75; // view-space units
uniform float bias         : hint_range(0.0, 0.25, 0.001) = 0.02;
uniform float strength     : hint_range(0.0, 4.0, 0.05) = 1.0;
uniform int   sample_count : hint_range(4, 32) = 12;
uniform float fade_start   : hint_range(1.0, 500.0, 1.0) = 40.0;
uniform float fade_end     : hint_range(1.0, 500.0, 1.0) = 90.0;
group_uniforms;

group_uniforms style;
uniform int  bands : hint_range(0, 16) = 4;   // 0 = smooth gradient
uniform bool dither_bands = true;
uniform vec3 occluded_color : source_color = vec3(0.0, 0.0, 0.0);
uniform bool debug_ao = false;
group_uniforms;

const float GOLDEN_ANGLE = 2.39996323;

const float BAYER4[16] = {
	 0.0,  8.0,  2.0, 10.0,
	12.0,  4.0, 14.0,  6.0,
	 3.0, 11.0,  1.0,  9.0,
	15.0,  7.0, 13.0,  5.0
};


// Depth buffer -> view space. Works under both normal and reverse-Z because
// INV_PROJECTION_MATRIX already encodes whichever convention is in use.
vec3 view_pos(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).x;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return v.xyz / v.w;
}

// Face normal from depth. For each axis, take whichever neighbour tap is
// closer in depth, so silhouettes stay sharp instead of smearing across
// discontinuities.
vec3 depth_normal(vec2 uv, vec3 P, vec2 texel, mat4 inv_proj) {
	vec3 pl = view_pos(uv - vec2(texel.x, 0.0), inv_proj);
	vec3 pr = view_pos(uv + vec2(texel.x, 0.0), inv_proj);
	vec3 pu = view_pos(uv - vec2(0.0, texel.y), inv_proj); // SCREEN_UV.y grows downward
	vec3 pd = view_pos(uv + vec2(0.0, texel.y), inv_proj);

	vec3 dx = (abs(pr.z - P.z) < abs(P.z - pl.z)) ? (pr - P) : (P - pl);
	vec3 dy = (abs(pu.z - P.z) < abs(P.z - pd.z)) ? (pu - P) : (P - pd);

	vec3 n = normalize(cross(dx, dy));
	return (dot(n, P) > 0.0) ? -n : n; // keep it facing the camera
}

// Interleaved gradient noise — per-pixel rotation of the sample spiral.
float ign(vec2 pix) {
	return fract(52.9829189 * fract(dot(pix, vec2(0.06711056, 0.00583715))));
}


float compute_ao(vec2 uv, vec2 pix, vec2 texel, mat4 proj, mat4 inv_proj) {
	vec3 P = view_pos(uv, inv_proj);
	float z = -P.z; // Godot view space looks down -Z

	if (z >= fade_end) {
		return 1.0; // sky / far geometry, leave it alone
	}

	vec3 N = depth_normal(uv, P, texel, inv_proj);

	// Screen-space footprint of a sphere of `radius` at this depth.
	vec2 uv_radius = abs(vec2(proj[0][0], proj[1][1])) * (0.5 * radius / z);

	float rot = ign(pix) * TAU;
	float r2 = radius * radius;
	float occ = 0.0;

	for (int i = 0; i < sample_count; i++) {
		float t = (float(i) + 0.5) / float(sample_count);
		float a = rot + float(i) * GOLDEN_ANGLE;
		vec2 offset = vec2(cos(a), sin(a)) * sqrt(t) * uv_radius; // uniform disk
		vec2 tap = clamp(uv + offset, vec2(0.0), vec2(1.0));

		vec3 v = view_pos(tap, inv_proj) - P;
		float vv = dot(v, v);
		float vn = dot(v, N);

		float f = max(r2 - vv, 0.0);
		occ += f * f * f * max((vn - bias) / (vv + 0.0001), 0.0);
	}

	occ *= (5.0 * strength) / (pow(radius, 6.0) * float(sample_count));

	float ao = clamp(1.0 - occ, 0.0, 1.0);
	return mix(ao, 1.0, smoothstep(fade_start, fade_end, z)); // distance fade
}


void vertex() {
	// QuadMesh of size (2, 2) -> exact full-screen triangle pair in clip space.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 texel = 1.0 / VIEWPORT_SIZE;
	float ao = compute_ao(SCREEN_UV, FRAGCOORD.xy, texel,
			PROJECTION_MATRIX, INV_PROJECTION_MATRIX);

	// Quantise to a handful of steps and ordered-dither the transitions.
	// This replaces the usual bilateral blur: the noise becomes a stable
	// 4x4 pattern instead of per-frame grain, which survives a palette snap.
	if (bands > 0) {
		float lv = float(bands);
		float threshold = 0.5;
		if (dither_bands) {
			int bx = int(FRAGCOORD.x) % 4;
			int by = int(FRAGCOORD.y) % 4;
			threshold = (BAYER4[by * 4 + bx] + 0.5) / 16.0;
		}
		ao = clamp(floor(ao * lv + threshold) / lv, 0.0, 1.0);
	}

	vec3 base = texture(screen_tex, SCREEN_UV).rgb;
	ALBEDO = debug_ao ? vec3(ao) : mix(occluded_color, base, ao);
}
