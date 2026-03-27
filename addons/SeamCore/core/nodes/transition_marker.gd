extends Marker3D
class_name SeamTransitionMarker

@export var marker_id: StringName = &""


func _enter_tree() -> void:
	add_to_group("seam_transition_marker")
