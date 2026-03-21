extends Node

signal state_changed
signal lives_updated(player_id: String, lives: int)
signal player_eliminated(player_id: String)
signal round_changed(round_number: int)

enum GamePhase { NONE, WAITING, COUNTDOWN, GUESSING, REVEALING, NEXT_ROUND, GAME_OVER }

var session: NakamaSession
var account: Dictionary = {}
var current_match_id: String = ""
var local_player_id: String = ""
var local_player_username: String = ""
var current_phase: GamePhase = GamePhase.NONE
var round_number: int = 0
var players: Dictionary = {}
var max_lives: int = 10
var max_players: int = 10
var is_ranked: bool = false
var room_code: String = ""
var local_power_up: String = "none"
var guess_start_time: float = 0.0

func _ready() -> void:
	NakamaManager.message_received.connect(_on_message_received)

func reset() -> void:
	current_match_id = ""
	current_phase = GamePhase.NONE
	round_number = 0
	players.clear()
	local_power_up = "none"
	guess_start_time = 0.0
	state_changed.emit()

func set_phase(phase_string: String) -> void:
	var phase_map := {
		"waiting": GamePhase.WAITING,
		"countdown": GamePhase.COUNTDOWN,
		"guessing": GamePhase.GUESSING,
		"revealing": GamePhase.REVEALING,
		"next_round": GamePhase.NEXT_ROUND,
		"game_over": GamePhase.GAME_OVER,
	}
	current_phase = phase_map.get(phase_string, GamePhase.NONE)

func update_player(player_id: String, data: Dictionary) -> void:
	if not players.has(player_id):
		players[player_id] = {}
	var player := players[player_id] as Dictionary
	for key in data:
		player[key] = data[key]
	if data.has("lives"):
		lives_updated.emit(player_id, data["lives"])
	if data.get("isAlive", true) == false:
		player_eliminated.emit(player_id)

func get_alive_players() -> Array:
	var result := []
	for pid in players:
		if players[pid].get("isAlive", true):
			result.append(players[pid])
	return result

func get_player(player_id: String) -> Dictionary:
	return players.get(player_id, {})

func start_guess_timer() -> void:
	guess_start_time = Time.get_ticks_msec()

func get_guess_elapsed_ms() -> float:
	return Time.get_ticks_msec() - guess_start_time

func _on_message_received(op: int, data: Dictionary) -> void:
	if op == 1:
		round_number = data.get("roundNumber", 1)
		start_guess_timer()
		local_power_up = data.get("activeEvent", "none")
		round_changed.emit(round_number)
		state_changed.emit()
	elif op == 3:
		var prs: Dictionary = data.get("playerResults", {})
		for pid in prs:
			update_player(pid, prs[pid])
		state_changed.emit()
	elif op == 6:
		update_player(data.get("userId", ""), data)
	elif op == 9:
		var plist: Array = data.get("players", [])
		for pdata in plist:
			update_player(pdata.get("userId", ""), pdata)
		round_number = data.get("roundNumber", 1)
		local_power_up = data.get("activeEvent", "none")
		state_changed.emit()
