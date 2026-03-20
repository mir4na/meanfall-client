extends Node

signal round_started(round_number: int)
signal round_ended(results: Dictionary)
signal lives_changed(player_id: String, lives: int)
signal game_over(winner_id: String)

const MAX_LIVES := 10
const LIFE_LOSS_THRESHOLD := 0.05

var round_number: int = 0
var _player_lives: Dictionary = {}
var _player_guesses: Dictionary = {}
var _is_round_active: bool = false

func start_match(player_ids: Array) -> void:
	round_number = 0
	_player_lives.clear()
	for pid in player_ids:
		_player_lives[pid] = MAX_LIVES
	_start_next_round()

func _start_next_round() -> void:
	round_number += 1
	_player_guesses.clear()
	_is_round_active = true
	round_started.emit(round_number)

func submit_guess(player_id: String, value: int) -> void:
	if not _is_round_active:
		return
	_player_guesses[player_id] = clampi(value, 0, 100)

func resolve_round(is_two_player: bool = false) -> Dictionary:
	_is_round_active = false
	var target: float
	if is_two_player:
		target = float(randi() % 101)
	else:
		if _player_guesses.is_empty():
			return {}
		var total := 0.0
		for v in _player_guesses.values():
			total += float(v)
		target = (total / float(_player_guesses.size())) * 0.8

	var results: Dictionary = {}
	var winner_id := ""
	var best_diff := INF

	for pid in _player_guesses:
		var guess := float(_player_guesses[pid])
		var diff := absf(guess - target)
		var lost_life := diff > (target * LIFE_LOSS_THRESHOLD + 1.0)
		if lost_life and _player_lives.has(pid):
			_player_lives[pid] = maxi(0, _player_lives[pid] - 1)
			lives_changed.emit(pid, _player_lives[pid])
		results[pid] = {
			"guessValue": int(guess),
			"diff": diff,
			"lives": _player_lives.get(pid, 0),
			"lostLife": lost_life,
			"isAlive": _player_lives.get(pid, 0) > 0,
		}
		if diff < best_diff:
			best_diff = diff
			winner_id = pid

	if winner_id != "":
		results[winner_id]["isWinner"] = true

	round_ended.emit(results)
	_check_game_over()
	return results

func _check_game_over() -> void:
	var alive := []
	for pid in _player_lives:
		if _player_lives[pid] > 0:
			alive.append(pid)
			
	if alive.size() <= 1:
		var winner := alive[0] if alive.size() == 1 else ""
		game_over.emit(winner)
		return
	_start_next_round()

func get_lives(player_id: String) -> int:
	return _player_lives.get(player_id, 0)

func is_alive(player_id: String) -> bool:
	return _player_lives.get(player_id, 0) > 0

func reset() -> void:
	round_number = 0
	_player_lives.clear()
	_player_guesses.clear()
	_is_round_active = false
