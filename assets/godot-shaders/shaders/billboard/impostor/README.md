# Y-Axis Impostor Shader for Godot 4.7

A cylindrical (Y-axis only) billboard impostor system. All pre-rendered
orientations of a 3D model are packed into a **single atlas texture**, and the
shader selects the correct view at runtime based on the camera's horizontal
angle around the node.

Typical use cases: trees, vegetation, props, distant buildings, crowds — any
scene where hundreds of instances of the same model would be too expensive to
render as full geometry.

## Files

| File | Purpose |
|------|---------|
| `impostor_y.gdshader` | Runtime spatial shader. Billboards a quad around the Y axis and picks the atlas frame from the camera yaw. |
| `impostor_baker.gd` | Offline baking tool. Renders N views of a source scene into a single PNG atlas that matches the shader's frame convention. |

## How It Works

1. **Baking (once, offline).** The baker instances your model inside a
   `SubViewport` with a transparent background, orbits an orthographic camera
   around it in `frame_count` equal steps, captures each view, and blits every
   capture into one big `Image` saved as a PNG.

2. **Runtime.** A `QuadMesh` is rotated every frame so it always faces the
   camera, but **only around the Y axis** — it never tips backward when viewed
   from above (classic Doom-sprite behavior). The vertex shader computes the
   camera's yaw relative to the node, maps it to a frame index, and the
   fragment shader remaps `UV` into that frame's cell of the atlas.

### Frame Convention (critical)

Both files share the same convention. If you bake with a different tool, you
must reproduce it:

- **Frame 0** = camera positioned at the node's **+Z**, looking toward **−Z**
  (the "front" view).
- Subsequent frames rotate **counterclockwise** (from +Z toward +X) in equal
  angular steps of `TAU / frame_count`.
- The atlas fills **left-to-right, top-to-bottom** (frame index → column =
  `i % columns`, row = `i / columns`).

If your atlas comes from elsewhere and appears rotated or mirrored, use the
shader's `angle_offset_deg` uniform to realign it without rebaking.

## Step 1 — Bake the Atlas

1. Create a new empty scene with a `Node3D` root.
2. Attach `impostor_baker.gd` to the root.
3. Configure the exported properties in the Inspector:

| Property | Meaning | Notes |
|----------|---------|-------|
| `source_scene_path` | Scene to bake (`.tscn`, `.glb`, `.gltf`) | Root must be a `Node3D`. |
| `output_path` | Where the PNG atlas is written | e.g. `res://impostors/tree_atlas.png`. Used as the pre-filled suggestion when the save dialog is enabled. |
| `ask_output_path` | Show a save dialog on run | **On by default.** A `FileDialog` opens when the scene starts; pick where to save the atlas. Cancelling aborts the bake. Turn off for unattended/repeat bakes using `output_path` directly. |
| `frame_count` | Number of views around the Y axis | 8 = visible popping, 16 = good default, 32 = very smooth. |
| `columns` | Frames per atlas row | 16 frames / 4 columns = 4×4 grid; 8 / 8 = single horizontal strip. |
| `frame_size` | Pixel size of each cell (square) | 256 is a good starting point; 512 for hero props. |
| `auto_frame` | Measure the model's AABB and frame it automatically | **On by default.** Computes `ortho_size`, orbit center, camera height, and aim point so the model fully fits in every frame. The console prints the computed `ortho_size` — use it as your quad size. |
| `frame_margin` | Extra padding around the model (fraction) | 0.05 = 5% breathing room. |
| `camera_distance` | Orbit radius (manual mode only) | Just needs to be outside the model; irrelevant to scale with an ortho camera. |
| `camera_height` | Camera Y position (manual mode only) | Raise it if the model pivot is at its base so the model is centered vertically. |
| `ortho_size` | Orthographic vertical size (manual mode only) | Defines the world-space height captured per frame. Your quad must match it (see Step 2). |
| `look_at_height` | Vertical aim point (manual mode only) | Usually half the model's height if the pivot is at the base. |

With `auto_frame` on, the baker merges the AABBs of every `VisualInstance3D`
in the source scene, orbits around the model's true center (even if it is not
at the origin), and sizes the view to
`max(height, XZ-footprint diagonal) × (1 + margin)` — the diagonal is used
because that is the widest the model can appear as the camera circles it.

4. Run the scene (**F6**). It prints progress per frame, saves the PNG, and
   quits automatically.
5. Select the generated PNG in the FileSystem dock. Recommended import
   settings: keep **Mipmaps** on for distant objects (see Troubleshooting for
   the bleeding caveat), no compression artifacts issues expected with
   default VRAM compression, but **Lossless** looks best for cutout foliage.

## Step 2 — Set Up the Impostor Node

1. Add a `MeshInstance3D` to your scene.
2. Assign a **`QuadMesh`** (default orientation, facing +Z, centered pivot).
3. Set the quad **size** so its height equals the baker's `ortho_size` (and
   width accordingly — cells are square, so a square quad of
   `ortho_size × ortho_size` gives a 1:1 scale match).
4. Create a **`ShaderMaterial`**, load `impostor_y.gdshader`.
5. Set the shader parameters:

| Uniform | Meaning | Default |
|---------|---------|---------|
| `atlas` | The baked PNG | — |
| `frames` | Must equal the baker's `frame_count` | 16 |
| `columns` | Must equal the baker's `columns` | 4 |
| `angle_offset_deg` | Fine rotation alignment (degrees) | 0 |
| `blend_frames` | Crossfade between adjacent views | off |
| `alpha_clip` | Alpha scissor threshold for cutout edges | 0.5 |

6. If the model pivot was at its base, offset the quad up by half its height
   (or bake with `camera_height` centered and keep the quad centered — just be
   consistent).

Rotating the node around Y in the scene rotates the impostor's apparent
orientation, exactly like rotating the real model would.

## Shader Details

- **Billboarding** uses the same matrix construction as Godot's built-in
  `BILLBOARD_FIXED_Y`, but built manually so the node's **scale is preserved**
  and the frame selection can share the math.
- **`MAIN_CAM_INV_VIEW_MATRIX`** is used instead of the per-pass camera, so
  the impostor does not re-billboard toward the shadow camera or reflection
  probes — shadows and reflections stay consistent with what the player sees.
- **Frame selection runs in the vertex stage** and is passed to the fragment
  stage as `flat` varyings, so the per-pixel cost is one texture sample (two
  with `blend_frames` on).
- **`render_mode unshaded`** is the default because impostor atlases normally
  have lighting baked in from the source render. Remove `unshaded` from the
  `render_mode` line if you want scene lighting to tint the quad.
- **Alpha scissor** (`ALPHA_SCISSOR_THRESHOLD`) keeps the material in the
  **opaque pipeline**: correct depth sorting, no transparency sorting cost,
  ideal for scattering hundreds of instances via `MultiMeshInstance3D`.

### `blend_frames`

When off (default), the shader snaps to the nearest view — crisp, but the
transition between frames "pops" as the camera orbits. When on, it samples
the two nearest views and crossfades — smoother motion at the cost of one
extra texture sample and slightly ghosted silhouettes during transitions.
With 16+ frames the popping is usually mild enough to leave blending off.

## Performance Notes

- Pair with **`MultiMeshInstance3D`** for mass scattering: one draw call for
  thousands of impostors. The shader reads the transform from `MODEL_MATRIX`,
  which for multimesh resolves per instance, so per-instance rotation works.
- Use as the **far LOD** of a real model: `GeometryInstance3D` visibility
  ranges (`visibility_range_begin/end` with fade) let you swap mesh → impostor
  automatically with a dissolve.
- Atlas memory: a 4×4 grid at 256 px cells is a single 1024×1024 texture —
  cheap. Prefer more frames over larger cells if popping bothers you.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Impostor shows the wrong side / offset by one view | Atlas baked with a different angle convention | Adjust `angle_offset_deg` (e.g. ±90, 180, or ± one frame step). |
| Colored/ghost fringes at cell edges when far away | Mipmap bleeding between atlas cells | Bake with padding, or change the sampler to `filter_linear` (no mipmaps), or disable mipmaps on import. |
| White/dark halo around cutout edges | Alpha not premultiplied against background | Bake with `transparent_bg = true` (default in the baker); raise `alpha_clip` slightly. |
| Model appears too small/large on the quad | `ortho_size` and quad size mismatch | Make quad height = baker `ortho_size`. |
| Model cut off at top/bottom of frames | Camera aim/framing | Increase `ortho_size`, adjust `camera_height` and `look_at_height`. |
| Impostor is black | `unshaded` removed but quad normal faces away, or atlas not assigned | Reassign atlas; keep `unshaded`, or verify lighting. |
| Frames flip abruptly in shadows/reflections | Using per-pass camera | Already handled — the shader uses `MAIN_CAM_INV_VIEW_MATRIX`; don't replace it with `INV_VIEW_MATRIX`. |

## Limitations

- **Horizontal views only.** Looking at the impostor from steep above/below
  angles reveals the flat quad (the silhouette stays correct horizontally but
  foreshortens vertically). If your camera pitches heavily, consider a full
  octahedral impostor instead — this system is intentionally the simpler,
  cheaper Y-only variant.
- No depth output: the impostor is flat, so intersections with other geometry
  slice as a plane.
- Lighting is baked at capture time; time-of-day changes won't affect it
  unless you remove `unshaded` and accept approximate lighting on a flat
  normal.
