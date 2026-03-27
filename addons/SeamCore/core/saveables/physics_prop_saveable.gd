extends RigidBody3D
class_name SeamPhysicsProp

@export var unique_id: String = ""
@export var save_enabled: bool = true


func _enter_tree() -> void:
	add_to_group("seam_saveable")
	add_to_group("seam_transferable")


func _ready() -> void:
	if unique_id.is_empty():
		unique_id = "%s::%s" % [scene_file_path, str(get_path())]


func get_save_scene_path() -> String:
	return scene_file_path


func save_state() -> Dictionary:
	return {
		"transform": global_transform,
		"linear_velocity": linear_velocity,
		"angular_velocity": angular_velocity,
		"sleeping": sleeping,
	}


func load_state(data: Dictionary) -> void:
	if data.get("deleted", false):
		queue_free()
		return

	if data.has("transform"):
		global_transform = data["transform"]
	linear_velocity = data.get("linear_velocity", Vector3.ZERO)
	angular_velocity = data.get("angular_velocity", Vector3.ZERO)
	sleeping = data.get("sleeping", false)
