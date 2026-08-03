# Depth-Only SSAO for Godot 4.7

A self-contained screen-space ambient occlusion pass built for low-resolution,
flat-shaded retro pipelines. It replaces Godot's built-in `Environment > SSAO`
with something that quantises cleanly and survives a downstream palette snap.

Reconstructs **both** view-space position and face normals from the depth
buffer, so it needs no G-buffer normals and produces hard, faceted occlusion
that matches flat-shaded low-poly geometry instead of fighting it.

---

## Files

| File | Purpose |
| --- | --- |
| `ssao.gdshader` | The shader. Runs as a full-screen post-process quad, or lifts into an existing pass. |


---

## Requirements

- Godot 4.x (written against 4.7)
- **Forward+** or **Mobile** renderer — the pass needs `hint_depth_texture`
- A depth-writing opaque pass; fully transparent scenes produce no occlusion

The shader deliberately avoids `hint_normal_roughness_texture`, which is
Forward+ only and whose smooth interpolated normals would soften exactly the
faceting this pipeline wants to keep.

---

## How it works

### 1. Position and normal reconstruction

`view_pos()` unprojects a depth sample through `INV_PROJECTION_MATRIX`:

```glsl
vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
return v.xyz / v.w;
```

Because the inverse projection already encodes whichever depth convention the
build uses, this stays correct under both normal and reverse-Z.

`depth_normal()` builds the face normal from four neighbour taps, picking the
**nearer** tap on each axis before taking the cross product. That keeps
occlusion from bleeding across silhouettes, and on faceted geometry it recovers
the exact polygon normal.

### 2. The obscurance estimator

Scalable Ambient Obscurance (McGuire et al., 2012). For each tap on a
golden-angle spiral disk, sized to the screen-space footprint of `radius` at
the current depth:

```
occ += max(r² - v·v, 0)³ · max((v·n - bias) / (v·v), 0)
```

normalised by `5 / (r⁶ · sample_count)`. Compact, stable, and good quality at
8–12 samples. The spiral is rotated per-pixel by interleaved gradient noise.

### 3. Banding and ordered dither

This is the deliberate divergence from a stock SSAO. Instead of a bilateral
blur to hide sampling noise, `ao` is quantised to `bands` steps against a Bayer
4×4 threshold matrix.

Two reasons:

- The noise becomes a **fixed screen-space pattern** rather than per-frame
  grain, so it does not crawl and does not get amplified into flicker by a
  palette-snap pass downstream.
- Dithering a gradient across a handful of steps *is* the period-correct way to
  render a soft shadow in a 16-colour palette.

Set `bands = 0` to get a smooth gradient instead.

---


## Uniform reference

### Occlusion

| Uniform | Default | Notes |
| --- | --- | --- |
| `radius` | `0.75` | Sampling radius in view-space units. The main knob. |
| `bias` | `0.02` | Rejects near-coplanar samples. Raise to kill self-occlusion. |
| `strength` | `1.0` | Linear multiplier on accumulated obscurance. |
| `sample_count` | `12` | Taps per pixel. 8–12 is plenty at 480×270. |
| `fade_start` | `40.0` | Depth at which occlusion begins fading out. |
| `fade_end` | `90.0` | Depth past which AO is fully off; also the sky cutoff. |

### Style

| Uniform | Default | Notes |
| --- | --- | --- |
| `bands` | `4` | Quantisation steps. `0` disables banding entirely. |
| `dither_bands` | `true` | Bayer 4×4 ordered dither across band transitions. |
| `occluded_color` | black | Colour a fully occluded pixel is mixed toward. |
| `debug_ao` | `false` | Output raw AO as greyscale. |

---

## Tuning guide

- **Start with `debug_ao` on.** Tune everything against the greyscale output
  before looking at the composited result.
- **`radius` scales with your scene.** For vehicle-scale contact shadows, start
  around 0.5–1.0 view units. Too large and the effect turns into a vignette
  around every object; too small and it disappears at the render resolution.
- **Raise `bias` if flat ground self-occludes.** Depth precision degrades with
  distance, so the artifact shows up far from the camera first.
- **Keep `fade_start`/`fade_end` inside your draw distance.** If `fade_end`
  exceeds it, distant terrain picks up a grey wash instead of reading as sky.
- **`occluded_color` need not be black.** Mixing toward a dark palette entry
  gives the snap pass something closer to hit, which reduces colour banding
  artifacts in the final image.

---

## Integrating into an existing post-process chain

`compute_ao()` and its two helpers (`view_pos`, `depth_normal`) depend only on
`depth_tex`, `SCREEN_UV`, `FRAGCOORD`, `VIEWPORT_SIZE`, `PROJECTION_MATRIX` and
`INV_PROJECTION_MATRIX` — all available in any spatial fragment shader. They can
be pasted into another pass unchanged.

**This is usually the right move.** `render_priority` on `ShaderMaterial` is
only guaranteed to affect transparent sorting, so stacking several opaque
post-process quads and relying on their draw order is unreliable. If you already
have an edge-line or dither pass that samples depth:

1. Paste the three functions into that shader.
2. Call `compute_ao()` there.
3. Multiply the result into your colour **before** any palette snapping.

That removes the ordering problem entirely and saves a screen-texture copy.

---

## Performance

At 480×270 with 12 samples this is roughly 1.6 M depth taps per frame, plus 4
per pixel for normal reconstruction — negligible on anything modern. Cost scales
linearly with `sample_count` and with render resolution, not with scene
complexity.

The dynamic loop bound (`sample_count` is a uniform) is fine on Vulkan. If you
target a backend that dislikes it, replace it with a `const int` and recompile.

---

## Known limitations

- **Screen-space only.** Occluders outside the frustum, or hidden behind nearer
  geometry, contribute nothing. Objects entering frame will pop their occlusion.
- **Opaque geometry only.** Anything not writing depth is invisible to the pass.
- **Edge clamping.** Taps are clamped to the viewport, which slightly
  under-darkens pixels near the screen border.
- **No temporal accumulation.** Intentional: the fixed Bayer pattern is what
  keeps the result stable, and TAA would smear the faceting.

---

## Reference

McGuire, Mara & Luebke, *Scalable Ambient Obscurance*, HPG 2012.
