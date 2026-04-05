extends Node3D
class_name SeamPlayerStart

@export var spawn_id: String = "default"

func _ready():
	await get_tree().process_frame

	var world_state = get_node("/root/SeamCoreWorldState")
	var transition = get_node("/root/SeamLevelTransition")

	# Get PlayerPawn from globals (autoload)
	var globals = get_node_or_null("/root/Globals")
	if globals == null:
		push_error("Globals autoload not found! Expected /root/Globals")
		return

	if not globals.has_variable("PlayerPawn"):
		push_error("Globals does not define PlayerPawn!")
		return

	var player_scene: PackedScene = globals.PlayerPawn
	if player_scene == null:
		push_error("Globals.PlayerPawn is null!")
		return

	var player: Node3D = player_scene.instantiate()
	get_tree().current_scene.add_child(player)

	# Default spawn
	player.global_transform = global_transform

	# Handle transition placement
	if world_state and world_state.pending_transition:
		transition.resolve_transition(player)
