extends Node

signal room_created(code: String, match_id: String)
signal room_joined(match_id: String)
signal room_error(message: String)

var _current_code: String = ""

func create_room(max_players: int = 6, rounds: int = 5) -> void:
	var result = await NakamaManager.rpc_call("create_custom_room", {
		"maxPlayers": max_players,
		"rounds": rounds
	})
	if result.has("error"):
		room_error.emit(result.get("error", "Failed to create room."))
		return
	_current_code = result.get("roomCode", "")
	var match_id: String = result.get("matchId", "")
	room_created.emit(_current_code, match_id)

func join_room(code: String) -> void:
	var trimmed := code.strip_edges().to_upper()
	if trimmed.is_empty():
		room_error.emit("Please enter a room code.")
		return
	var result = await NakamaManager.rpc_call("join_custom_room", {"roomCode": trimmed})
	if result.has("error"):
		room_error.emit(result.get("error", "Room not found or full."))
		return
	_current_code = trimmed
	var match_id: String = result.get("matchId", "")
	room_joined.emit(match_id)

func get_current_code() -> String:
	return _current_code

func clear() -> void:
	_current_code = ""
