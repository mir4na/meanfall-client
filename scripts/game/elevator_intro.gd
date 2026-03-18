extends Node3D

@onready var player_body: Node3D = $ElevatorShaft/ElevatorCar/PlayerBody
@onready var camera: Camera3D = $ElevatorShaft/ElevatorCar/PlayerBody/PlayerHead/Camera3D

var _cinematic_active := true
var _yaw := 0.0
var _pitch := 0.0
const LOOK_SENSITIVITY := 0.003
const PITCH_LIMIT := 50.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true

	var env: WorldEnvironment = get_node_or_null("WorldEnvironment")
	if env and env.environment:
		env.environment.ambient_light_energy = 2.0
		env.environment.ambient_light_color = Color(0.5, 0.55, 0.75)

	var lighting = get_node_or_null("ElevatorShaft/ElevatorCar/Lighting")
	if lighting:
		for light in lighting.get_children():
			if light is OmniLight3D:
				light.light_energy *= 4.0
				light.omni_range *= 2.0

	SceneTransition.fade_in()

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
		player_body.rotation.y = _yaw
		camera.rotation.x = _pitch
