extends Area3D

func _ready() -> void:
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("saber"):
		queue_free()
