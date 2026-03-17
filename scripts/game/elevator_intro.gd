extends Node3D

const ELEVATOR_TRAVEL_DISTANCE := 12.0
const ELEVATOR_DURATION := 4.0
const PAUSE_AT_BOTTOM := 1.0

@onready var elevator_car: Node3D = $ElevatorShaft/ElevatorCar
@onready var camera: Camera3D = $ElevatorShaft/ElevatorCar/Camera3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_build_elevator_geometry()
	_run_cinematic()

func _build_elevator_geometry() -> void:
	var shaft := $ElevatorShaft
	var walls_mesh := MeshInstance3D.new()
	var walls_box := BoxMesh.new()
	walls_box.size = Vector3(4.0, 20.0, 4.0)
	walls_mesh.mesh = walls_box
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.08, 0.08, 0.12)
	wall_mat.metallic = 0.8
	wall_mat.roughness = 0.3
	walls_mesh.surface_override_material(0, wall_mat)
	walls_mesh.position = Vector3.ZERO
	shaft.add_child(walls_mesh)

	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(3.6, 0.1, 3.6)
	floor_mesh.mesh = floor_box
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.15, 0.15, 0.2)
	floor_mat.metallic = 0.6
	floor_mat.roughness = 0.4
	floor_mesh.surface_override_material(0, floor_mat)
	elevator_car.add_child(floor_mesh)

	var light := OmniLight3D.new()
	light.light_color = Color(0.9, 0.95, 1.0)
	light.light_energy = 2.0
	light.omni_range = 5.0
	light.position = Vector3(0, 1.8, 0)
	elevator_car.add_child(light)

	elevator_car.position = Vector3(0, ELEVATOR_TRAVEL_DISTANCE, 0)

func _run_cinematic() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(elevator_car, "position:y", 0.0, ELEVATOR_DURATION)
	tween.tween_interval(PAUSE_AT_BOTTOM)
	tween.tween_callback(_transition_to_game_room)

func _transition_to_game_room() -> void:
	await SceneTransition.fade_out()
	SceneTransition.fade_to_scene("res://scenes/game/game_room/game_room.tscn")
