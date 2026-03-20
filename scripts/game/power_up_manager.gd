extends Node

const POWERUP_POOL := ["shield", "double_guess", "reveal_average", "sabotage"]

var _assigned: Dictionary = {}

func assign_powerups(player_ids: Array, every_n_rounds: int, current_round: int) -> Dictionary:
	_assigned.clear()
	if current_round % every_n_rounds != 0:
		return _assigned
	var pool := POWERUP_POOL.duplicate()
	pool.shuffle()
	for i in min(player_ids.size(), pool.size()):
		_assigned[player_ids[i]] = pool[i]
	return _assigned

func get_powerup(player_id: String) -> String:
	return _assigned.get(player_id, "none")

func apply_effect(player_id: String, powerup: String, context: Dictionary) -> Dictionary:
	var modified := context.duplicate(true)
	match powerup:
		"shield":
			modified["shielded"] = true
		"double_guess":
			modified["doubleGuess"] = true
		"reveal_average":
			modified["revealAverage"] = true
		"sabotage":
			var targets: Array = context.get("otherPlayers", [])
			if not targets.is_empty():
				var target_id: String = targets[randi() % targets.size()]
				modified["sabotageTarget"] = target_id
	_assigned.erase(player_id)
	return modified

func has_powerup(player_id: String) -> bool:
	return _assigned.has(player_id) and _assigned[player_id] != "none"

func reset() -> void:
	_assigned.clear()
