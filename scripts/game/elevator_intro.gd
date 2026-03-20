extends Node3D

@onready var elevator: Node3D = $ElevatorShaft/ElevatorCar
@onready var elevator_doors: Node3D = $ElevatorShaft/ElevatorCar/ElevatorDoors
@onready var cinematic_overlay: ColorRect = $CinematicCanvas/CinematicOverlay

@onready var camera: Camera3D = $ElevatorShaft/ElevatorCar/PlayerSpawn/Camera3D

var _cinematic_active := true
var _yaw := 0.0
var _pitch := 0.0
const LOOK_SENSITIVITY := 0.003
const PITCH_LIMIT := 50.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	SceneTransition.fade_in()
	
	_run_sequence()

func _run_sequence() -> void:
	if cinematic_overlay and cinematic_overlay.material:
		var tw_bars_in := create_tween()
		tw_bars_in.tween_method(func(v: float): cinematic_overlay.material.set_shader_parameter("bar_height", v), 0.0, 0.1, 0.5)
	
	if elevator:
		await elevator.descend()
	
	await get_tree().create_timer(0.3).timeout
	
	if elevator_doors:
		await elevator_doors.open_doors()
	
	await get_tree().create_timer(0.4).timeout
	if cinematic_overlay and cinematic_overlay.material:
		var tw_bars_out := create_tween()
		tw_bars_out.tween_method(func(v: float): cinematic_overlay.material.set_shader_parameter("bar_height", v), 0.1, 0.0, 0.4)
		await tw_bars_out.finished
	
	_on_cinematic_finished()

func _on_cinematic_finished() -> void:
	_cinematic_active = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SceneTransition.fade_to_scene("res://scenes/game/game_room/game_room.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not _cinematic_active:
		return
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * LOOK_SENSITIVITY
		_pitch -= event.relative.y * LOOK_SENSITIVITY
		_pitch = clampf(_pitch, deg_to_rad(-PITCH_LIMIT), deg_to_rad(PITCH_LIMIT))
		camera.rotation.y = _yaw
		camera.rotation.x = _pitch
