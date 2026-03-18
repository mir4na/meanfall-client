extends Node3D

const SEAT_RADIUS := 3.5
const PLAYER_SEAT_SCENE := "res://scenes/game/player_seat/player_seat.tscn"
const HUD_SCENE := "res://scenes/ui/hud/hud.tscn"

var _player_seats: Dictionary = {}
var _hud: Control

@onready var seats_container: Node3D = $Seats
@onready var camera: Camera3D = $CameraRoot/Camera3D

func _ready() -> void:
	_add_hud()
	_connect_signals()
	_reveal_camera()

func _reveal_camera() -> void:
	camera.position = Vector3(0, 9.0, 10.0)
	camera.rotation_degrees.x = -45.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "position", Vector3(0, 1.5, 5.0), 2.0)
	tween.parallel().tween_property(camera, "rotation_degrees:x", -20.0, 2.0)
	tween.tween_callback(SceneTransition.fade_in)

func _add_hud() -> void:
	var hud_scene := load(HUD_SCENE)
	_hud = hud_scene.instantiate()
	add_child(_hud)

func _connect_signals() -> void:
	NakamaManager.message_received.connect(_on_message_received)
	GameState.player_eliminated.connect(_on_player_eliminated)

func _on_message_received(op_code: int, data: Dictionary) -> void:
	if op_code == 6:
		_spawn_seat_for_player(data.get("userId", ""), data.get("username", "?"), data.get("lives", 10))
	if op_code == 9:
		for pdata in data.get("players", []):
			_spawn_seat_for_player(pdata.get("userId", ""), pdata.get("username", "?"), pdata.get("lives", 10))

func _spawn_seat_for_player(player_id: String, username: String, lives: int) -> void:
	if _player_seats.has(player_id):
		return
	var seat_scene := load(PLAYER_SEAT_SCENE)
	var seat: Node3D = seat_scene.instantiate()
	seat.setup(player_id, username, lives)
	var seat_index := _player_seats.size()
	var total_seats := maxi(GameState.max_players, 2)
	var angle := (TAU / total_seats) * seat_index
	seat.position = Vector3(sin(angle) * SEAT_RADIUS, 0.0, cos(angle) * SEAT_RADIUS)
	seat.rotation.y = -angle
	seats_container.add_child(seat)
	_player_seats[player_id] = seat

func _on_player_eliminated(player_id: String) -> void:
	if _player_seats.has(player_id):
		var seat: Node3D = _player_seats[player_id]
		var tween := create_tween()
		tween.tween_property(seat, "modulate", Color(0.3, 0.3, 0.3), 0.5)
