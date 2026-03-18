extends Node

const NAKAMA_HOST := "localhost"
const NAKAMA_PORT := 7350
const NAKAMA_SCHEME := "http"
const NAKAMA_SERVER_KEY := "defaultkey"
const RECONNECT_DELAY := 3.0
const MAX_RECONNECT_ATTEMPTS := 5

const SESSION_FILE := "user://nakama_session.save"

signal login_succeeded(session)
signal guest_created(session)
signal session_connected(session)
signal session_failed(message: String)
signal match_joined(match_id: String)
signal message_received(op_code: int, data: Dictionary)
signal disconnected
signal reconnect_succeeded
signal reconnect_failed
signal logout_succeeded

var _client
var _socket
var _session
var _reconnect_attempts: int = 0
var _reconnect_timer: Timer

func _ready() -> void:
	_client = Nakama.create_client(NAKAMA_SERVER_KEY, NAKAMA_HOST, NAKAMA_PORT, NAKAMA_SCHEME)
	_reconnect_timer = Timer.new()
	_reconnect_timer.one_shot = true
	_reconnect_timer.timeout.connect(_attempt_reconnect)
	add_child(_reconnect_timer)
	
	_try_restore_session()

func _try_restore_session() -> void:
	if not FileAccess.file_exists(SESSION_FILE):
		return
	
	var file = FileAccess.open(SESSION_FILE, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var token: String = ""
	var refresh_token: String = ""
	
	if content.begins_with("{"):
		var data = JSON.parse_string(content)
		if data is Dictionary:
			token = data.get("token", "")
			refresh_token = data.get("refresh_token", "")
	else:
		# Fallback for old simple string token
		token = content
	
	if token.is_empty():
		return
		
	var session = NakamaSession.new(token, false, refresh_token)
	if session.is_expired():
		var result = await _client.session_refresh_async(session)
		if result.is_exception():
			return
		session = result
		
	_on_authenticated(session)

func _save_session(session: NakamaSession) -> void:
	var data = {
		"token": session.token,
		"refresh_token": session.refresh_token
	}
	var file = FileAccess.open(SESSION_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _clear_session() -> void:
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(SESSION_FILE)
	_session = null
	GameState.session = null
	GameState.local_player_id = ""

func logout() -> void:
	_clear_session()
	if _socket:
		_socket.close()
		_socket = null
	logout_succeeded.emit()

func authenticate_device(device_id: String) -> void:
	var result = await _client.authenticate_device_async(device_id)
	if result.is_exception():
		session_failed.emit(result.get_exception().message)
		return
		
	if result.created:
		_session = result
		guest_created.emit(result)
	else:
		_on_authenticated(result)

func update_account(username: String) -> bool:
	var result = await _client.update_account_async(_session, username)
	if result.is_exception():
		session_failed.emit(result.get_exception().message)
		return false
	_on_authenticated(_session)
	return true

func get_account() -> Dictionary:
	var result = await _client.get_account_async(_session)
	if result.is_exception():
		return {}
	return result.serialize()

func authenticate_email(email: String, password: String, username: String = "") -> void:
	var create := username != ""
	var result = await _client.authenticate_email_async(email, password, username, create)
	if result.is_exception():
		session_failed.emit(result.get_exception().message)
		return
	_on_authenticated(result)

func link_email(email: String, password: String) -> bool:
	var result = await _client.link_email_async(_session, email, password)
	if result.is_exception():
		session_failed.emit(result.get_exception().message)
		return false
	return true

func _on_authenticated(session: NakamaSession) -> void:
	_session = session
	_save_session(_session)
	GameState.session = _session
	GameState.local_player_id = _session.user_id
	
	# Fetch full account info
	GameState.account = await get_account()
	if GameState.account.has("user"):
		GameState.local_player_username = GameState.account["user"].get("username", session.username)
	else:
		GameState.local_player_username = session.username
	
	session_connected.emit(_session)

func connect_socket() -> void:
	_socket = Nakama.create_socket_from(_client)
	_socket.connected.connect(_on_socket_connected)
	_socket.closed.connect(_on_socket_closed)
	_socket.received_error.connect(_on_socket_error)
	_socket.received_match_state.connect(_on_match_state)
	await _socket.connect_async(_session)

func join_match(match_id: String) -> void:
	if _socket == null:
		await connect_socket()
	var result = await _socket.join_match_async(match_id)
	if result.is_exception():
		session_failed.emit(result.get_exception().message)
		return
	GameState.current_match_id = match_id
	match_joined.emit(match_id)

func leave_match() -> void:
	if _socket != null and GameState.current_match_id != "":
		await _socket.leave_match_async(GameState.current_match_id)
		GameState.current_match_id = ""

func send_message(op_code: int, data: Dictionary) -> void:
	if _socket == null or GameState.current_match_id == "":
		return
	var payload: String = JSON.stringify(data)
	_socket.send_match_state_async(GameState.current_match_id, op_code, payload)

func rpc_call(rpc_id: String, payload: Dictionary) -> Dictionary:
	var payload_str: String = JSON.stringify(payload)
	var result = await _client.rpc_async(_session, rpc_id, payload_str)
	if result.is_exception():
		return {"error": result.get_exception().message}
	var parsed = JSON.parse_string(result.payload)
	return parsed if parsed is Dictionary else {}

func get_player_stats() -> Dictionary:
	return await rpc_call("get_player_stats", {})

func get_match_history() -> Dictionary:
	return await rpc_call("get_match_history", {})

func _on_socket_connected() -> void:
	_reconnect_attempts = 0

func _on_socket_closed() -> void:
	disconnected.emit()
	_schedule_reconnect()

func _on_socket_error(error: String) -> void:
	disconnected.emit()
	_schedule_reconnect()

func _on_match_state(state) -> void:
	var parsed = JSON.parse_string(state.data)
	var data: Dictionary = parsed if parsed is Dictionary else {}
	message_received.emit(state.op_code, data)

func _schedule_reconnect() -> void:
	if _reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
		reconnect_failed.emit()
		return
	_reconnect_attempts += 1
	_reconnect_timer.start(RECONNECT_DELAY * _reconnect_attempts)

func _attempt_reconnect() -> void:
	if _session == null:
		reconnect_failed.emit()
		return
	var result = await _client.session_refresh_async(_session)
	if result.is_exception():
		_schedule_reconnect()
		return
	_session = result
	await connect_socket()
	if GameState.current_match_id != "":
		await join_match(GameState.current_match_id)
	reconnect_succeeded.emit()
