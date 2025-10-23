extends Area3D

@export var camera_path: NodePath = NodePath("../XROrigin3D/XRCamera3D")
@export var distance_behind_player: float = 4.0   # meters along incoming direction
@export var extent_x: float = 4.0   # half-width  (total width = 2*extent_x)
@export var extent_y: float = 2.0   # half-height (total height = 2*extent_y)
@export var extent_z: float = 0.5   # half-thickness

func _ready() -> void:
	# Layer: put backboard on its own (e.g., 4)
	for i in range(1, 33): set_collision_layer_value(i, false)
	set_collision_layer_value(4, true)

	# MASK (DEBUG): listen to ALL layers so we see hits while testing
	for i in range(1, 33): set_collision_mask_value(i, true)

	monitoring = true
	monitorable = true
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# Ensure a BoxShape3D exists and size it via extents
	var cs := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs == null:
		push_error("Backboard: add a CollisionShape3D child.")
		return
	if cs.shape == null:
		cs.shape = BoxShape3D.new()
	var box := cs.shape as BoxShape3D
	box.extents = Vector3(extent_x, extent_y, extent_z)

	# Auto-place “behind” the player along the incoming direction
	var cam := get_node_or_null(camera_path) as Node3D
	if cam:
		var fixed_forward := -cam.global_transform.basis.z
		fixed_forward.y = 0.0
		if fixed_forward.length() <= 0.001:
			fixed_forward = Vector3.FORWARD
		else:
			fixed_forward = fixed_forward.normalized()
		var incoming_dir := -fixed_forward

		global_position = cam.global_position + incoming_dir * distance_behind_player
		global_transform.basis = Basis().looking_at(incoming_dir, Vector3.UP)

	if scale != Vector3.ONE:
		push_warning("Backboard: set node scale to (1,1,1); use BoxShape3D extents for size.")
		scale = Vector3.ONE

	print("🔎 Backboard DEBUG placed at:", global_position, " extents:", (cs.shape as BoxShape3D).extents, " layer:", collision_layer, " mask: ALL")

func _on_area_entered(a: Area3D) -> void:
	print("Backboard area_entered ->", a.name, " groups:", a.get_groups(), " layer:", a.collision_layer, " mask:", a.collision_mask)
	var root := a.get_parent() if a.get_parent() else a
	if root.has_method("destroy_silent"):
		root.call("destroy_silent")
	else:
		root.queue_free()
