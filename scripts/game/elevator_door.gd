extends Node3D
class_name ElevatorDoors

@export var open_duration: float = 1.3
@export var open_distance: float = 1.3

@onready var gate_left: Node3D = $GateLeft
@onready var gate_right: Node3D = $GateRight

signal doors_opened

func open_doors() -> void:
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(gate_left, "position:x", gate_left.position.x - open_distance, open_duration)
	tw.tween_property(gate_right, "position:x", gate_right.position.x + open_distance, open_duration)
	await tw.finished
	doors_opened.emit()
