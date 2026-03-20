extends Node

signal match_state_received(op_code: int, data: Dictionary)
signal match_presence_changed(joins: Array, leaves: Array)

const OP_SUBMIT_GUESS   := 2
const OP_ROUND_START    := 1
const OP_ROUND_RESULT   := 3
const OP_GAME_OVER      := 4
const OP_CHAT           := 5
const OP_PLAYER_JOINED  := 6
const OP_PLAYER_LEFT    := 7
const OP_POWERUP        := 8
const OP_RECONNECT      := 9

var _current_match_id: String = ""

func _ready() -> void:
	NakamaManager.message_received.connect(_on_raw_message)

func join(match_id: String) -> void:
	_current_match_id = match_id
	await NakamaManager.join_match(match_id)

func leave() -> void:
	await NakamaManager.leave_match()
	_current_match_id = ""

func submit_guess(value: int) -> void:
	NakamaManager.send_message(OP_SUBMIT_GUESS, {"value": clampi(value, 0, 100)})

func activate_powerup(powerup_type: String) -> void:
	NakamaManager.send_message(OP_POWERUP, {"powerUpType": powerup_type})

func send_chat(text: String) -> void:
	NakamaManager.send_message(OP_CHAT, {
		"text": text.strip_edges(),
		"username": GameState.local_player_username
	})

func get_match_id() -> String:
	return _current_match_id

func _on_raw_message(op_code: int, data: Dictionary) -> void:
	match_state_received.emit(op_code, data)
