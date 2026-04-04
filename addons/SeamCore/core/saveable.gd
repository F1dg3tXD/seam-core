extends Node3D
class_name SeamSaveable

@export var unique_id: String = ""
@export var save_enabled: bool = true


func _enter_tree() -> void:
	add_to_group("seam_saveable")


func _ready() -> void:
	if unique_id.is_empty():
		unique_id = _build_fallback_id()


func _build_fallback_id() -> String:
	var scene_path: String = scene_file_path if not scene_file_path.is_empty() else get_tree().current_scene.scene_file_path
	return "%s::%s" % [scene_path, str(get_path())]


func mark_deleted() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		queue_free()
		return

	var world_state: SeamWorldState = get_node_or_null("/root/SeamCoreWorldState")
	if world_state != null:
		world_state.mark_entity_deleted(current_scene.scene_file_path, unique_id)
	queue_free()


func get_save_scene_path() -> String:
	if scene_file_path.is_empty():
		return ""
	return scene_file_path


func save_state() -> Dictionary:
	return {
		"transform": global_transform,
	}


func load_state(data: Dictionary) -> void:
	if data.get("deleted", false):
		queue_free()
		return

	if data.has("transform"):
		global_transform = data["transform"]
