extends Node3D
class_name Elevator

@export var descend_duration: float = 4.5
@export var target_y: float = 0.0

signal descended

var _is_descending := false
@onready var _start_x := position.x
@onready var _start_z := position.z

func _ready() -> void:
	# Spawn stationary lights in the shaft so the player can perceive speed as they drop past them
	for i in range(1, 5):
		var marker_light := OmniLight3D.new()
		marker_light.position = Vector3(0, i * 3.0, 1.4)
		marker_light.light_color = Color(1.0, 0.2, 0.1)
		marker_light.light_energy = 4.0
		marker_light.omni_range = 4.0
		# Attach to shaft (parent space) so they don't move with the elevator
		get_parent().call_deferred("add_child", marker_light)

func descend() -> void:
	_is_descending = true
	var tw := create_tween()
	
	# Smooth acceleration downwards, dipping slightly below target to simulate heavy weight
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position:y", target_y - 0.2, descend_duration * 0.8)
	
	# Heavy mechanical bounce back
	tw.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", target_y, descend_duration * 0.2)
	
	await tw.finished
	_is_descending = false
	position.x = _start_x
	position.z = _start_z
	descended.emit()

func _process(delta: float) -> void:
	if _is_descending:
		# Procedural mechanical vibration to simulate rickety descent
		position.x = _start_x + randf_range(-0.015, 0.015)
		position.z = _start_z + randf_range(-0.015, 0.015)
