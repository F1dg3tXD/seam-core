# info_player_start.gd
extends Node3D
class_name SeamPlayerStart

@export var spawn_id: String = "default"

func _ready():
	await get_tree().process_frame

	var world_state := get_node("/root/SeamCoreWorldState")
	var transition: SeamLevelTransition = get_node("/root/SeamLevelTransition")

	var player_scene: PackedScene = load(ProjectSettings.get_setting("seamcore/player_scene"))
	if player_scene == null:
		push_error("Player scene not set in project settings!")
		return

	var player: Node3D = player_scene.instantiate()
	get_tree().current_scene.add_child(player)

	# Default spawn
	player.global_transform = global_transform

	# If transitioning, override position
	if world_state.pending_transition:
		transition.resolve_transition(player)
