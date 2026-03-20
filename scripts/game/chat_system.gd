extends Node

signal chat_message_received(sender_id: String, sender_name: String, message: String)

const MAX_HISTORY := 100
const OP_CHAT := 5

var _history: Array = []

func _ready() -> void:
	NakamaManager.message_received.connect(_on_message_received)

func send(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	NakamaManager.send_message(OP_CHAT, {
		"text": trimmed,
		"username": GameState.local_player_username
	})

func _on_message_received(op_code: int, data: Dictionary) -> void:
	if op_code != OP_CHAT:
		return
	var sender_id: String = data.get("userId", "")
	var sender_name: String = data.get("username", "?")
	var text: String = data.get("text", "")
	if text.is_empty():
		return
	var entry := {"senderId": sender_id, "senderName": sender_name, "text": text}
	_history.append(entry)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	chat_message_received.emit(sender_id, sender_name, text)

func get_history() -> Array:
	return _history.duplicate()

func clear() -> void:
	_history.clear()
