extends CharacterBody3D
class_name SeamNpcSaveable

@export var unique_id: String = ""
@export var save_enabled: bool = true
@export var health: int = 100
@export var is_dead: bool = false


func _enter_tree() -> void:
	add_to_group("seam_saveable")


func _ready() -> void:
	if unique_id.is_empty():
		unique_id = "%s::%s" % [scene_file_path, str(get_path())]


func get_save_scene_path() -> String:
	return scene_file_path


func save_state() -> Dictionary:
	return {
		"transform": global_transform,
		"health": health,
		"is_dead": is_dead,
	}


func load_state(data: Dictionary) -> void:
	health = data.get("health", health)
	is_dead = data.get("is_dead", is_dead)
	if data.has("transform"):
		global_transform = data["transform"]

	if is_dead:
		queue_free()
