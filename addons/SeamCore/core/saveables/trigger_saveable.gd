extends Node3D
class_name SeamTriggerSaveable

@export var unique_id: String = ""
@export var save_enabled: bool = true
@export var activated: bool = false


func _enter_tree() -> void:
	add_to_group("seam_saveable")


func _ready() -> void:
	if unique_id.is_empty():
		unique_id = "%s::%s" % [scene_file_path, str(get_path())]


func get_save_scene_path() -> String:
	return scene_file_path


func save_state() -> Dictionary:
	return {
		"activated": activated,
	}


func load_state(data: Dictionary) -> void:
	activated = data.get("activated", activated)
	if activated:
		apply_activated_state()


func apply_activated_state() -> void:
	# Override in your trigger implementation.
	pass
