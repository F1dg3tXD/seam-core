extends Node3D

@export var target_scene: String
@export var landmark_name: String

@onready var area: Area3D = $Area3D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "PlayerCharacter":
		var transition: SeamLevelTransition = get_node("/root/SeamLevelTransition")
		transition.transition_to_scene(target_scene, landmark_name, body, [body])
