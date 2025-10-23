extends Area3D

@export var line_renderer_path: NodePath
@export var shape_node_path: NodePath
@export var blade_thickness: float = 0.06

var _line: Node3D
var _shape: CollisionShape3D
var _box: BoxShape3D

var _orig_layer: int
var _orig_mask: int


func _ready() -> void:
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	add_to_group("saber")
	
	_orig_layer = collision_layer
	_orig_mask  = collision_mask


	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	if line_renderer_path != NodePath():
		_line = get_node(line_renderer_path) as Node3D
		if _line and not _line.visibility_changed.is_connected(_on_line_renderer_visibility_changed):
			_line.visibility_changed.connect(_on_line_renderer_visibility_changed)
		_apply_visibility(_line and _line.visible)

	if shape_node_path != NodePath():
		_shape = get_node(shape_node_path) as CollisionShape3D
		if _shape:
			if _shape.shape == null:
				_box = BoxShape3D.new()
				_shape.shape = _box
			else:
				_box = _shape.shape as BoxShape3D

func _physics_process(_dt: float) -> void:
	if _line == null or !_line.visible or _shape == null or _box == null:
		return

	if not _line.has_variable("points"):
		return
	var pts: Array[Vector3] = _line.get("points")
	if pts.size() < 2:
		return

	var use_global: bool = _line.has_variable("globalCoords") and bool(_line.get("globalCoords"))

	var A_world: Vector3
	var B_world: Vector3
	if use_global:
		A_world = pts[0]
		B_world = pts[1]
	else:
		A_world = _line.to_global(pts[0])
		B_world = _line.to_global(pts[1])

	var A_local := to_local(A_world)
	var B_local := to_local(B_world)
	var dir := B_local - A_local
	var len := dir.length()
	if len < 0.01:
		return

	_box.size = Vector3(blade_thickness, blade_thickness, len)

	var mid := (A_local + B_local) * 0.5
	var basis := Basis().looking_at(dir.normalized(), Vector3.UP)
	_shape.transform = Transform3D(basis, mid)

#func _on_area_entered(a: Area3D) -> void:
	#print(">>> Saber area_entered:", a.name)
	#if a.is_in_group("block"):
	#	var target := a.get_parent() if a.get_parent() else a
		#print(">>> Saber hit, freeing root:", target.name)
	#	target.queue_free()


func _on_body_entered(b: Node) -> void:
	if b.is_in_group("block"):
		var target := b.get_parent() if b.get_parent() else b
		target.queue_free()

func _on_line_renderer_visibility_changed() -> void:
	_on_line_visibility_changed()

func _on_line_visibility_changed() -> void:
	_apply_visibility(_line and _line.visible)

func _apply_visibility(on: bool) -> void:
	# Toggle Area participation
	set_deferred("monitoring", on)
	set_deferred("monitorable", on)

	
	if _shape:
		_shape.set_deferred("disabled", not on)

	
	if on:
		set_deferred("collision_layer", _orig_layer)
		set_deferred("collision_mask",  _orig_mask)
		set_physics_process(true)
		
		call_deferred("_refresh_shape_now")
	else:
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask",  0)
		set_physics_process(false)



func _on_area_entered(a: Area3D) -> void:
	if a.is_in_group("block_red"):  
		var root := a.get_parent() if a.get_parent() else a
		if root.has_method("destroy_by_saber"):
			root.call("destroy_by_saber")
			
func _refresh_shape_now() -> void:
	if _line != null and _line.visible and _shape != null and _box != null:
		_physics_process(0.0)
