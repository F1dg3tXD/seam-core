extends Node
class_name SeamLevelTransition

@export var saveable_group: StringName = &"seam_saveable"
@export var transfer_group: StringName = &"seam_transferable"
@export var transition_marker_group: StringName = &"seam_transition_marker"


func save_current_level() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var world_state: SeamWorldState = get_node_or_null("/root/SeamWorldState")
	if world_state == null:
		return

	var level_path: String = current_scene.scene_file_path
	if level_path.is_empty():
		return

	var entities: Dictionary = {}
	var saveables: Array[Node] = get_tree().get_nodes_in_group(saveable_group)
	for candidate in saveables:
		if not is_instance_valid(candidate):
			continue
		if not _is_saveable_node(candidate):
			continue

		var saveable: Node = candidate
		if not bool(saveable.get("save_enabled")) or String(saveable.get("unique_id")).is_empty():
			continue

		entities[String(saveable.get("unique_id"))] = {
			"scene": saveable.call("get_save_scene_path"),
			"parent_path": current_scene.get_path_to(saveable.get_parent()),
			"spawned": bool(saveable.get_meta("seam_spawned", false)),
			"data": saveable.call("save_state"),
		}

	var deleted_ids: PackedStringArray = world_state.consume_deleted_ids(level_path)
	for deleted_id in deleted_ids:
		entities[deleted_id] = {
			"scene": "",
			"parent_path": NodePath("."),
			"spawned": false,
			"data": {"deleted": true},
		}

	world_state.save_level_state(level_path, {
		"entities": entities,
	})


func load_current_level() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var world_state: SeamWorldState = get_node_or_null("/root/SeamWorldState")
	if world_state == null:
		return

	var level_path: String = current_scene.scene_file_path
	if not world_state.has_level_state(level_path):
		return

	var level_state: Dictionary = world_state.get_level_state(level_path)
	var entities: Dictionary = level_state.get("entities", {})

	var saveables: Array[Node] = get_tree().get_nodes_in_group(saveable_group)
	var seen_ids: Dictionary = {}
	for candidate in saveables:
		if not is_instance_valid(candidate):
			continue
		if not _is_saveable_node(candidate):
			continue

		var saveable: Node = candidate
		var unique_id: String = String(saveable.get("unique_id"))
		seen_ids[unique_id] = true
		if entities.has(unique_id):
			saveable.call("load_state", entities[unique_id].get("data", {}))

	for unique_id in entities.keys():
		if seen_ids.has(unique_id):
			continue

		var entry: Dictionary = entities[unique_id]
		var entry_data: Dictionary = entry.get("data", {})
		if entry_data.get("deleted", false):
			continue

		var scene_path: String = entry.get("scene", "")
		if scene_path.is_empty():
			continue

		var packed: PackedScene = load(scene_path)
		if packed == null:
			continue

		var instance: Node = packed.instantiate()
		if not _is_saveable_node(instance):
			instance.queue_free()
			continue

		var parent_path: NodePath = entry.get("parent_path", NodePath("."))
		var parent_node: Node = current_scene.get_node_or_null(parent_path)
		if parent_node == null:
			parent_node = current_scene
		parent_node.add_child(instance)

		var saveable_instance: Node = instance
		saveable_instance.set("unique_id", unique_id)
		saveable_instance.set_meta("seam_spawned", true)
		saveable_instance.call("load_state", entry_data)


func collect_transferables(filter_nodes: Array[Node] = []) -> void:
	if filter_nodes.is_empty():
		for candidate in get_tree().get_nodes_in_group(transfer_group):
			_queue_transfer(candidate)
		return

	for candidate in filter_nodes:
		_queue_transfer(candidate)


func inject_carried_entities() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var world_state: SeamWorldState = get_node_or_null("/root/SeamWorldState")
	if world_state == null:
		return

	var markers_by_name: Dictionary = {}
	for marker in get_tree().get_nodes_in_group(transition_marker_group):
		if marker is SeamTransitionMarker:
			markers_by_name[marker.marker_id] = marker

	var carried: Array[Dictionary] = world_state.consume_carried_entities()
	for entry in carried:
		var packed: PackedScene = load(entry.get("scene", ""))
		if packed == null:
			continue

		var node: Node = packed.instantiate()
		if not _is_saveable_node(node):
			node.queue_free()
			continue

		current_scene.add_child(node)
		var saveable: Node3D = node
		saveable.set_meta("seam_spawned", true)
		saveable.call("load_state", entry.get("data", {}))

		if entry.has("transform"):
			saveable.global_transform = entry["transform"]

		var target_marker: StringName = entry.get("target_marker", &"")
		if not target_marker.is_empty() and markers_by_name.has(target_marker):
			var marker: SeamTransitionMarker = markers_by_name[target_marker]
			saveable.global_transform = marker.global_transform


func queue_manual_transfer(node: Node3D, target_marker: StringName = &"") -> void:
	_queue_transfer(node, target_marker)


func transition_to_scene(next_scene_path: String, transfer_nodes: Array[Node] = [], entry_marker: StringName = &"") -> void:
	var world_state: SeamWorldState = get_node_or_null("/root/SeamWorldState")
	if world_state == null:
		return
	save_current_level()
	collect_transferables(transfer_nodes)
	world_state.pending_entry_marker = entry_marker
	get_tree().change_scene_to_file(next_scene_path)


func _queue_transfer(candidate: Node, target_marker: StringName = &"") -> void:
	var world_state: SeamWorldState = get_node_or_null("/root/SeamWorldState")
	if world_state == null:
		return
	if not is_instance_valid(candidate):
		return
	if not _is_saveable_node(candidate):
		return

	var saveable: Node3D = candidate
	var scene_path: String = saveable.call("get_save_scene_path")
	if scene_path.is_empty():
		return

	world_state.queue_carried_entity({
		"scene": scene_path,
		"data": saveable.call("save_state"),
		"transform": saveable.global_transform,
		"target_marker": target_marker,
	})

	saveable.queue_free()


func _is_saveable_node(candidate: Node) -> bool:
	return candidate.has_method("save_state") \
		and candidate.has_method("load_state") \
		and candidate.has_method("get_save_scene_path") \
		and candidate.get("unique_id") != null \
		and candidate.get("save_enabled") != null
