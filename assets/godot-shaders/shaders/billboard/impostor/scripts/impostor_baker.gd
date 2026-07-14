# impostor_baker.gd — Godot 4.7
# Bakes a single-image impostor atlas matching impostor_y.gdshader.
#
# Usage:
#   1. Create an empty scene with a Node3D root and attach this script.
#   2. Set the exported properties (source scene, frame count, output path...).
#   3. Run the scene (F6). It renders every view, writes the PNG, and quits.
#
# Frame convention (matches the shader):
#   frame 0 = camera at +Z looking toward -Z, then counterclockwise (toward +X).
#   Atlas fills left-to-right, top-to-bottom.
#
# Auto-framing (default): the baker measures the model's merged AABB and
# derives ortho_size, camera height, aim point, and orbit center so the model
# always fits fully inside every frame, from every angle. The console prints
# the computed ortho_size — set your QuadMesh size to that value for a 1:1
# world-scale match.

extends Node3D

@export_file("*.tscn", "*.glb", "*.gltf") var source_scene_path: String = "res://model.tscn"
## Fallback / default output path. When ask_output_path is enabled, a save
## dialog opens on run and this value is used as the pre-filled suggestion.
@export var output_path: String = "res://impostor_atlas.png"
## Show a file save dialog when the scene runs instead of using output_path
## directly. Cancelling the dialog aborts the bake.
@export var ask_output_path: bool = true
@export_range(4, 128) var frame_count: int = 16
@export_range(1, 32) var columns: int = 4
@export_range(64, 2048) var frame_size: int = 256

@export_group("Framing")
## When enabled, all manual framing values below are ignored and computed
## from the model's bounding box instead.
@export var auto_frame: bool = true
## Extra padding around the model, as a fraction of its size (0.05 = 5%).
@export_range(0.0, 0.5) var frame_margin: float = 0.05

@export_group("Manual Framing (used when auto_frame is off)")
@export var camera_distance: float = 10.0
@export var camera_height: float = 0.0
@export var ortho_size: float = 4.0
@export var look_at_height: float = 0.0


var _dialog_result: String = ""
var _dialog_done: bool = false


func _ready() -> void:
	if ask_output_path:
		var selected: String = await _prompt_output_path()
		if selected.is_empty():
			print("Bake cancelled: no output file selected.")
			get_tree().quit()
			return
		output_path = selected
	await _bake()
	get_tree().quit()


## Opens a save dialog and returns the chosen path, or an empty String if the
## user cancelled. The .png extension is appended if missing.
func _prompt_output_path() -> String:
	var dialog: FileDialog = FileDialog.new()
	dialog.title = "Save Impostor Atlas"
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.filters = PackedStringArray(["*.png ; PNG Image"])
	dialog.current_path = output_path
	dialog.file_selected.connect(_on_dialog_file_selected)
	dialog.canceled.connect(_on_dialog_canceled)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)

	while not _dialog_done:
		await get_tree().process_frame
	dialog.queue_free()

	var result: String = _dialog_result
	if not result.is_empty() and result.get_extension().to_lower() != "png":
		result += ".png"
	return result


func _on_dialog_file_selected(path: String) -> void:
	_dialog_result = path
	_dialog_done = true


func _on_dialog_canceled() -> void:
	_dialog_result = ""
	_dialog_done = true


func _bake() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(frame_size, frame_size)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)

	var model: Node3D = load(source_scene_path).instantiate() as Node3D
	viewport.add_child(model)

	var orbit_center: Vector3 = Vector3(0.0, look_at_height, 0.0)
	var distance: float = camera_distance
	var height: float = camera_height
	var view_size: float = ortho_size

	if auto_frame:
		var aabb: AABB = _compute_model_aabb(model)
		if aabb.size == Vector3.ZERO:
			push_error("auto_frame: no VisualInstance3D found in the source scene.")
			return
		var center: Vector3 = aabb.get_center()
		# Worst-case width as the camera orbits = diagonal of the XZ footprint.
		var horizontal_extent: float = Vector2(aabb.size.x, aabb.size.z).length()
		view_size = maxf(aabb.size.y, horizontal_extent) * (1.0 + frame_margin)
		orbit_center = center
		height = center.y
		distance = maxf(horizontal_extent, aabb.size.y) * 2.0 + 1.0
		print("auto_frame: AABB position=%s size=%s" % [aabb.position, aabb.size])
		print("auto_frame: ortho_size=%.3f  orbit_center=%s  distance=%.3f" % [
				view_size, orbit_center, distance])
		print(">>> Set your QuadMesh size to %.3f x %.3f to match world scale." % [
				view_size, view_size])

	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = view_size
	camera.near = 0.05
	camera.far = distance * 4.0
	viewport.add_child(camera)

	var rows: int = int(ceil(float(frame_count) / float(columns)))
	var atlas: Image = Image.create(
			frame_size * columns, frame_size * rows, false, Image.FORMAT_RGBA8)

	for i: int in range(frame_count):
		var angle: float = TAU * float(i) / float(frame_count)
		camera.position = Vector3(
				orbit_center.x + sin(angle) * distance,
				height,
				orbit_center.z + cos(angle) * distance)
		camera.look_at(orbit_center, Vector3.UP)

		# Let the viewport render the new camera transform.
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw

		var frame_image: Image = viewport.get_texture().get_image()
		var col: int = i % columns
		var row: int = i / columns
		atlas.blit_rect(
				frame_image,
				Rect2i(0, 0, frame_size, frame_size),
				Vector2i(col * frame_size, row * frame_size))
		print("Baked frame %d / %d" % [i + 1, frame_count])

	var err: Error = atlas.save_png(output_path)
	if err != OK:
		push_error("Failed to save atlas: %s" % error_string(err))
	else:
		print("Atlas saved to %s (%d x %d, %d frames, %d columns)" % [
				output_path, atlas.get_width(), atlas.get_height(), frame_count, columns])


## Merges the AABBs of every VisualInstance3D in the model, in the model's
## global space (which equals viewport space here, since the model sits at
## the origin of the SubViewport).
func _compute_model_aabb(root: Node3D) -> AABB:
	var result: AABB = AABB()
	var found: bool = false
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is VisualInstance3D:
			var vi: VisualInstance3D = node as VisualInstance3D
			var global_aabb: AABB = vi.global_transform * vi.get_aabb()
			if found:
				result = result.merge(global_aabb)
			else:
				result = global_aabb
				found = true
		for child: Node in node.get_children():
			stack.push_back(child)
	return result
