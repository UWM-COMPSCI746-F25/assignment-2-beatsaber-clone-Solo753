extends Node3D

signal box_destroyed(box: Node3D)

@export var speed: float = 3.0
@export_enum("red", "blue") var box_color: String = "red"
@export var hitbox_path: NodePath = NodePath("hitbox")

var _move_dir: Vector3 = Vector3.ZERO
var _initialized: bool = false

func _ready() -> void:
	var hb := get_node_or_null(hitbox_path) as Area3D
	if hb:
		
		hb.add_to_group("block")
		hb.remove_from_group("block_red")
		hb.remove_from_group("block_blue")
		if box_color == "blue":
			hb.add_to_group("block_blue")
		else:
			hb.add_to_group("block_red")

	
		for i in range(1, 33):
			hb.set_collision_layer_value(i, false)
			hb.set_collision_mask_value(i, false)

		hb.set_collision_layer_value(2, true) 
		hb.set_collision_mask_value(1, true)  

		hb.monitorable = true
		hb.monitoring = true

		print("BOX HITBOX DEBUG:", hb.name, 
			"groups:", hb.get_groups(), 
			"layer:", hb.collision_layer, 
			"mask:", hb.collision_mask, 
			"monitoring:", hb.monitoring, 
			"monitorable:", hb.monitorable)



func set_motion_frame(fixed_forward: Vector3) -> void:
	_move_dir = -fixed_forward.normalized()
	_initialized = true

func _physics_process(dt: float) -> void:
	if not _initialized: 
		return
	global_translate(_move_dir * speed * dt)

func destroy_by_saber() -> void:
	emit_signal("box_destroyed", self)
	queue_free()

func destroy_silent() -> void:
	queue_free()
