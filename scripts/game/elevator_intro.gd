extends Node3D

const ELEVATOR_TRAVEL_DISTANCE := 12.0
const ELEVATOR_DURATION := 4.0
const PAUSE_AT_BOTTOM := 1.0

@onready var elevator_car: Node3D = $ElevatorShaft/ElevatorCar
@onready var camera: Camera3D = $ElevatorShaft/ElevatorCar/Camera3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	elevator_car.position.y = ELEVATOR_TRAVEL_DISTANCE
	_run_cinematic()

func _run_cinematic() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(elevator_car, "position:y", 0.0, ELEVATOR_DURATION)
	tween.tween_interval(PAUSE_AT_BOTTOM)
	tween.finished.connect(_transition_to_game_room)

func _transition_to_game_room() -> void:
	await SceneTransition.fade_out()
	get_tree().change_scene_to_file("res://scenes/game/game_room/game_room.tscn")
