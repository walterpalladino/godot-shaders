// impostor_y.gdshader — Godot 4.7
// Y-axis (cylindrical) billboard impostor. All orientations packed into a
// single atlas texture, laid out left-to-right, top-to-bottom.
//
// Frame convention (must match the baker):
//   frame 0 = camera at +Z of the node, looking toward -Z (the "front" view),
//   subsequent frames rotate counterclockwise (toward +X) in equal steps.
//
// Attach to a MeshInstance3D with a QuadMesh (default orientation, facing +Z).
// The node's own Y rotation is respected: rotating the node shows other sides.

shader_type spatial;
//render_mode unshaded, cull_back; // remove `unshaded` if you want scene lighting to affect the quad
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley;

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;


uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;


uniform int frames : hint_range(1, 128) = 16;   // total views baked into the atlas
uniform int columns : hint_range(1, 32) = 4;    // frames per row in the atlas
uniform float angle_offset_deg : hint_range(-180.0, 180.0) = 0.0; // fine alignment tweak
uniform bool blend_frames = false;              // crossfade between adjacent views (softer, slightly blurrier)
uniform float alpha_clip : hint_range(0.0, 1.0) = 0.5;

varying flat int frame_a;
varying flat int frame_b;
varying float frame_mix;

void vertex() {
	// --- Cylindrical billboard: rotate the quad around Y to face the camera ---
	// Same math as BILLBOARD_FIXED_Y, using the main camera so shadows/reflections stay coherent.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);

	// Preserve the node's scale (the billboard matrix above discards it).
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));

	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

	// --- Frame selection: yaw of the camera around the node, in node-local terms ---
	vec3 to_cam = MAIN_CAM_INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz;
	float cam_yaw = atan(to_cam.x, to_cam.z);

	// Node's own yaw, extracted from its basis X axis, so rotating the node
	// in the scene rotates the impostor's apparent orientation.
	float model_yaw = atan(-MODEL_MATRIX[0].z, MODEL_MATRIX[0].x);

	float rel = cam_yaw - model_yaw + radians(angle_offset_deg);
	float exact = fract(rel / TAU) * float(frames);

	frame_a = int(floor(exact)) % frames;
	frame_b = (frame_a + 1) % frames;
	frame_mix = fract(exact);
}

vec2 frame_uv(int f, vec2 uv) {
	int rows = (frames + columns - 1) / columns;
	int col = f % columns;
	int row = f / columns;
	return (uv + vec2(float(col), float(row))) / vec2(float(columns), float(rows));
}

void fragment() {
	vec4 col;
	if (blend_frames) {
		vec4 a = texture(atlas, frame_uv(frame_a, UV));
		vec4 b = texture(atlas, frame_uv(frame_b, UV));
		col = mix(a, b, frame_mix);
	} else {
		// Nearest view: no crossfade, crisp but pops between frames.
		int f = (frame_mix < 0.5) ? frame_a : frame_b;
		col = texture(atlas, frame_uv(f, UV));
	}

	ALBEDO = col.rgb;
	
	SPECULAR = specular;
	ROUGHNESS = roughness;

	ALPHA = col.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_clip;
}
