extends Node

var PlayerPawn: PackedScene

func _ready():
	PlayerPawn = preload("res://addons/PlayerCharacter/player_character_scene.tscn")
