extends Node3D
class_name Elevator

@export var descend_duration: float = 4.5
@export var target_y: float = 0.0

signal descended

func descend() -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position:y", target_y, descend_duration)
	await tw.finished
	descended.emit()
