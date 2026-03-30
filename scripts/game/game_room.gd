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
	_spawn_existing_seats()

func _remove_camera_tween() -> void:
	pass

func _add_hud() -> void:
	var hud_scene := load(HUD_SCENE)
	_hud = hud_scene.instantiate()
	add_child(_hud)

func _connect_signals() -> void:
	NakamaManager.message_received.connect(_on_message_received)
	GameState.player_eliminated.connect(_on_player_eliminated)

func _spawn_existing_seats() -> void:
	for pid in GameState.players:
		var p: Dictionary = GameState.players[pid]
		_spawn_seat_for_player(pid, p.get("username", "?"), p.get("lives", 10))

func _on_message_received(op_code: int, data: Dictionary) -> void:
	if op_code == 6:
		_spawn_seat_for_player(data.get("userId", ""), data.get("username", "?"), data.get("lives", 10))
	if op_code == 7:
		_remove_seat_for_player(data.get("userId", ""))
	if op_code == 9:
		for player_id in _player_seats.keys():
			if not GameState.players.has(player_id):
				_remove_seat_for_player(player_id)
		for pdata in data.get("players", []):
			_spawn_seat_for_player(pdata.get("userId", ""), pdata.get("username", "?"), pdata.get("lives", 10))

func _spawn_seat_for_player(player_id: String, username: String, lives: int) -> void:
	if _player_seats.has(player_id):
		return
	var seat_scene := load(PLAYER_SEAT_SCENE)
	var seat: Node3D = seat_scene.instantiate()
	seat.setup(player_id, username, lives)
	var seat_index := _player_seats.size()
	var total_seats := 10
	var angle := (TAU / total_seats) * seat_index
	seat.position = Vector3(sin(angle) * SEAT_RADIUS, 0.0, cos(angle) * SEAT_RADIUS)
	seat.rotation.y = -angle
	seats_container.add_child(seat)
	_player_seats[player_id] = seat
	if player_id == GameState.local_player_id:
		var char_node: Node3D = seat.get_node_or_null("PlayerCharacter")
		if char_node:
			var head: Node3D = char_node.get_node("Head")
			var cam_parent = camera.get_parent()
			if cam_parent:
				cam_parent.remove_child(camera)
			head.add_child(camera)
			camera.position = Vector3(0, 0.05, 0.25)
			camera.rotation_degrees = Vector3(0, 180, 0)
			if head.has_node("Skull"): head.get_node("Skull").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			if head.has_node("Visor"): head.get_node("Visor").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY

func _on_player_eliminated(player_id: String) -> void:
	if _player_seats.has(player_id):
		var seat: Node3D = _player_seats[player_id]
		var tween := create_tween()
		tween.tween_property(seat, "modulate", Color(0.3, 0.3, 0.3), 0.5)

func _remove_seat_for_player(player_id: String) -> void:
	if not _player_seats.has(player_id):
		return
	var seat: Node3D = _player_seats[player_id]
	_player_seats.erase(player_id)
	seat.queue_free()
