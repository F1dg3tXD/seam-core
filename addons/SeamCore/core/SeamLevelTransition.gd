extends Node
class_name SeamLevelTransition

@export var saveable_group: StringName = &"seam_saveable"
@export var transfer_group: StringName = &"seam_transferable"
@export var landmark_group: StringName = &"seam_landmark"

# =========================
# SAVE / LOAD (UNCHANGED CORE)
# =========================

func save_current_level() -> void:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return

	var world_state: SeamWorldState = get_node("/root/SeamCoreWorldState")
	var level_path: String = current_scene.scene_file_path

	var entities := {}

	for node in get_tree().get_nodes_in_group(saveable_group):
		if not _is_saveable_node(node):
			continue

		if not node.save_enabled or String(node.unique_id).is_empty():
			continue

		entities[node.unique_id] = {
			"scene": node.get_save_scene_path(),
			"parent_path": current_scene.get_path_to(node.get_parent()),
			"data": node.save_state(),
		}

	world_state.save_level_state(level_path, { "entities": entities })


func load_current_level() -> void:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return

	var world_state: SeamWorldState = get_node("/root/SeamCoreWorldState")
	var level_path: String = current_scene.scene_file_path

	if not world_state.has_level_state(level_path):
		return

	var state = world_state.get_level_state(level_path)
	var entities: Dictionary = state.get("entities", {})

	for node in get_tree().get_nodes_in_group(saveable_group):
		if not _is_saveable_node(node):
			continue

		if entities.has(node.unique_id):
			node.load_state(entities[node.unique_id]["data"])

# =========================
# TRANSITION SYSTEM (NEW)
# =========================

func transition_to_scene(next_scene: String, landmark_name: String, player: Node3D, transfer_nodes: Array = []) -> void:
	var world_state: SeamWorldState = get_node("/root/SeamCoreWorldState")

	var source_landmark = _find_landmark(landmark_name)
	if source_landmark == null:
		push_error("Missing source landmark: " + landmark_name)
		return

	# Save level state
	save_current_level()

	# Store transition context
	world_state.pending_transition = {
		"landmark": landmark_name,
		"offset": player.global_transform.origin - source_landmark.global_transform.origin,
		"player_scene": player.scene_file_path,
	}

	# Transfer entities with offset
	for node in transfer_nodes:
		_queue_transfer_with_offset(node, source_landmark)

	get_tree().change_scene_to_file(next_scene)


# =========================
# LOAD AFTER TRANSITION
# =========================

func resolve_transition(player: Node3D) -> void:
	var world_state: SeamWorldState = get_node("/root/SeamCoreWorldState")

	if not world_state.pending_transition:
		return

	var landmark_name = world_state.pending_transition["landmark"]
	var offset: Vector3 = world_state.pending_transition["offset"]

	var target_landmark = _find_landmark(landmark_name)
	if target_landmark == null:
		push_error("Missing target landmark: " + landmark_name)
		return

	# Place player
	player.global_transform.origin = target_landmark.global_transform.origin + offset

	# Spawn carried entities
	for entry in world_state.consume_carried_entities():
		var packed: PackedScene = load(entry["scene"])
		if packed == null:
			continue

		var obj: Node3D = packed.instantiate()
		get_tree().current_scene.add_child(obj)

		obj.load_state(entry["data"])

		var new_pos = target_landmark.global_transform.origin + entry["offset"]
		obj.global_transform.origin = new_pos

	world_state.pending_transition = {}


# =========================
# TRANSFER HELPERS
# =========================

func _queue_transfer_with_offset(node: Node3D, source_landmark: Node3D) -> void:
	var world_state: SeamWorldState = get_node("/root/SeamCoreWorldState")

	if not _is_saveable_node(node):
		return

	var offset = node.global_transform.origin - source_landmark.global_transform.origin

	world_state.queue_carried_entity({
		"scene": node.get_save_scene_path(),
		"data": node.save_state(),
		"offset": offset
	})

	node.queue_free()


# =========================
# HELPERS
# =========================

func _find_landmark(name: String) -> Node3D:
	for node in get_tree().get_nodes_in_group(landmark_group):
		if node.name == name:
			return node
	return null


func _is_saveable_node(node: Node) -> bool:
	return node.has_method("save_state") \
		and node.has_method("load_state") \
		and node.has_method("get_save_scene_path")
