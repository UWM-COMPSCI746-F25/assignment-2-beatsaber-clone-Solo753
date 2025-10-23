extends Node3D

@export var camera_path: NodePath
@export var controller_path: NodePath

@export var red_box_scene: PackedScene
@export var blue_box_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var blue_chance: float = 0.5

@export var use_bpm: bool = false
@export var bpm: float = 120.0
@export var spawn_interval: float = 0.8
@export var max_overlap: int = 3

@export var start_distance: float = 12.0
@export var lateral_jitter: float = 0.6
@export var chest_to_head_low: float = -0.40
@export var chest_to_head_high: float = 0.00

@export var pass_speed_to_box: bool = false
@export var box_speed: float = 3.0

var _camera: Node3D
var _controller: XRController3D
var _timer: Timer
var _alive := 0
var _fixed_forward: Vector3
var _fixed_right: Vector3
const WORLD_UP := Vector3.UP
var _started := false

func _ready() -> void:
	randomize()
	add_to_group("box_spawner")

	_camera = get_node_or_null(camera_path) as Node3D
	_controller = get_node_or_null(controller_path) as XRController3D

	print(">>> Spawner READY")
	print("    camera_path:", camera_path, "  camera:", _camera)
	print("    controller_path:", controller_path, "  controller:", _controller)
	print("    red_box_scene set? ", red_box_scene != null)
	print("    blue_box_scene set? ", blue_box_scene != null)

	if _camera == null:
		push_error("Spawner: camera_path not set or node not found."); return
	if red_box_scene == null or blue_box_scene == null:
		push_error("Spawner: assign red_box_scene and blue_box_scene in Inspector."); return

	_fixed_forward = -_camera.global_transform.basis.z
	_fixed_forward.y = 0.0
	if _fixed_forward.length() < 0.001:
		_fixed_forward = Vector3.FORWARD
	else:
		_fixed_forward = _fixed_forward.normalized()
	_fixed_right = _fixed_forward.cross(WORLD_UP).normalized()
	print("    fixed_forward:", _fixed_forward, " fixed_right:", _fixed_right)

	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = (60.0 / bpm) if use_bpm else spawn_interval
	add_child(_timer)
	_timer.timeout.connect(_on_tick)
	print("    timer wait_time:", _timer.wait_time)

	if _controller:
		_controller.button_pressed.connect(_on_button_pressed)
		print(">>> Waiting for B button to start…")
	else:
		print("⚠️ No controller_path set; auto-start in 2s for testing.")
		# Safe fallback: start automatically after 2 seconds so you can verify spawning even without B
		_call_deferred_start()

func _call_deferred_start() -> void:
	await get_tree().create_timer(2.0).timeout
	start_spawning()

func _on_button_pressed(name: String) -> void:
	print(">>> button_pressed:", name)
	if name == "by_button" and not _started:
		print(">>> B pressed, starting spawner!")
		start_spawning()

func start_spawning() -> void:
	if _started:
		print(">>> start_spawning called but already started"); return
	_started = true
	_timer.start()
	print(">>> Spawner STARTED")

func _on_tick() -> void:
	print(">>> tick  alive:", _alive, "/", max_overlap)
	if _alive >= max_overlap:
		return
	_spawn_one()

func _choose_scene() -> PackedScene:
	return blue_box_scene if randf() < blue_chance else red_box_scene

func _spawn_one() -> void:
	var scene := _choose_scene()
	if scene == null:
		push_error("Internal: chosen scene is null"); return

	var box := scene.instantiate()
	if box == null:
		push_error("Failed to instantiate box scene"); return

	print(">>> Spawning:", box)
	add_child(box)

	if box.has_method("set_motion_frame"):
		box.call("set_motion_frame", _fixed_forward)

	if pass_speed_to_box and box.has_variable("speed"):
		box.set("speed", box_speed)

	if box.has_signal("box_destroyed"):
		var main := get_tree().current_scene
		if main and main.has_method("_on_box_destroyed"):
			box.connect("box_destroyed", Callable(main, "_on_box_destroyed"))

	var cam_pos := _camera.global_position
	var pos := cam_pos + _fixed_forward * start_distance
	pos += _fixed_right * randf_range(-lateral_jitter, lateral_jitter)
	pos.y = cam_pos.y + randf_range(chest_to_head_low, chest_to_head_high)
	box.global_position = pos
	print("    box position:", pos)

	_alive += 1
	box.tree_exited.connect(_on_box_removed)
	print("    alive now:", _alive)

func _on_box_removed() -> void:
	_alive = max(0, _alive - 1)
	print(">>> box removed; alive:", _alive)
