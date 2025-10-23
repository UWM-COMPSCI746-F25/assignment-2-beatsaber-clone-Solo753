extends Node3D

@export var origin_path: NodePath
@export var camera_path: NodePath
@export var target_path: NodePath
@export var desired_distance: float = 1.5
@export var slice_sfx: AudioStream

var xr_interface: XRInterface

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		if not xr_interface.pose_recentered.is_connected(_on_pose_recentered):
			xr_interface.pose_recentered.connect(_on_pose_recentered)
		_ensure_listener_on_camera()
	else:
		print("OpenXR not initialized, please check if your headset is connected")

func _on_pose_recentered() -> void:
	recenter_to_target()

func recenter_to_target() -> void:
	var origin := get_node_or_null(origin_path) as XROrigin3D
	var cam := get_node_or_null(camera_path) as XRCamera3D
	var target := get_node_or_null(target_path) as Node3D
	if origin == null or cam == null or target == null:
		push_warning("XR recenter: missing origin/camera/target; check exported paths.")
		return

	var target_pos: Vector3 = target.global_position
	var tgt_forward := -target.global_transform.basis.z
	tgt_forward.y = 0.0
	if tgt_forward.length() < 0.001:
		tgt_forward = Vector3.FORWARD
	else:
		tgt_forward = tgt_forward.normalized()

	var desired_head_pos := target_pos - tgt_forward * desired_distance
	desired_head_pos.y = cam.global_position.y

	var look_dir := (target_pos - desired_head_pos).normalized()
	var desired_head_basis := Basis().looking_at(look_dir, Vector3.UP)
	var desired_head_xform := Transform3D(desired_head_basis, desired_head_pos)

	var new_origin_global := desired_head_xform * cam.transform.affine_inverse()
	origin.global_transform = new_origin_global

func _on_box_destroyed(box: Node3D) -> void:
	if slice_sfx == null:
		print("⚠️ slice_sfx not assigned on main; no sound will play.")
		return

	var p := AudioStreamPlayer3D.new()
	p.stream = slice_sfx
	p.global_transform = box.global_transform
	p.volume_db = 0.0
	p.pitch_scale = randf_range(0.95, 1.05)
	p.unit_size = 1.0
	
	p.attenuation_filter_cutoff_hz = 0
	get_tree().current_scene.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _ensure_listener_on_camera() -> void:
	var cam := get_node_or_null(camera_path) as Node3D
	if cam == null:
		return
	var listener := cam.get_node_or_null("AudioListener3D") as AudioListener3D
	if listener == null:
		listener = AudioListener3D.new()
		cam.add_child(listener)
	listener.current = true
