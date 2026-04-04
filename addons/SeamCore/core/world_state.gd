# world_state.gd
extends Node
class_name SeamWorldState

var level_states: Dictionary = {}

# Serialized entities that should be injected into the next level.
# [{"scene": String, "data": Dictionary, "transform": Transform3D, "target_marker": StringName}]
var carried_entities: Array[Dictionary] = []

# Temporary deletion tombstones collected while current level is running.
# { level_path: { unique_id: true } }
var _pending_deleted: Dictionary = {}

var pending_entry_marker: StringName = &""


func clear_all() -> void:
	level_states.clear()
	carried_entities.clear()
	_pending_deleted.clear()
	pending_entry_marker = &""


func save_level_state(level_path: String, state: Dictionary) -> void:
	level_states[level_path] = state


func get_level_state(level_path: String) -> Dictionary:
	return level_states.get(level_path, {})


func has_level_state(level_path: String) -> bool:
	return level_states.has(level_path)


func mark_entity_deleted(level_path: String, unique_id: String) -> void:
	if level_path.is_empty() or unique_id.is_empty():
		return

	if not _pending_deleted.has(level_path):
		_pending_deleted[level_path] = {}

	_pending_deleted[level_path][unique_id] = true


func consume_deleted_ids(level_path: String) -> PackedStringArray:
	if not _pending_deleted.has(level_path):
		return PackedStringArray()

	var ids: PackedStringArray = PackedStringArray(_pending_deleted[level_path].keys())
	_pending_deleted.erase(level_path)
	return ids


func queue_carried_entity(entry: Dictionary) -> void:
	carried_entities.append(entry)


func consume_carried_entities() -> Array[Dictionary]:
	var entries: Array[Dictionary] = carried_entities.duplicate(true)
	carried_entities.clear()
	return entries
