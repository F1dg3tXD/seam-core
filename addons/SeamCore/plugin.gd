@icon("res://addons/SeamCore/icons/icon512.png")
@tool
extends EditorPlugin

const AUTOLOAD_NAME := "SeamCoreWorldState"
const LEGACY_AUTOLOAD_NAME := "SeamWorldState"
const AUTOLOAD_PATH := "res://addons/SeamCore/core/world_state.gd"

func _enable_plugin() -> void:
	_ensure_autoload()


func _disable_plugin() -> void:
	_remove_autoload()


func _enter_tree() -> void:
	_ensure_autoload()


func _exit_tree() -> void:
	_remove_autoload()


func _ensure_autoload() -> void:
	if ProjectSettings.has_setting("autoload/%s" % LEGACY_AUTOLOAD_NAME):
		remove_autoload_singleton(LEGACY_AUTOLOAD_NAME)

	if ProjectSettings.has_setting("autoload/%s" % AUTOLOAD_NAME):
		return

	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _remove_autoload() -> void:
	if ProjectSettings.has_setting("autoload/%s" % AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)

	if ProjectSettings.has_setting("autoload/%s" % LEGACY_AUTOLOAD_NAME):
		remove_autoload_singleton(LEGACY_AUTOLOAD_NAME)
