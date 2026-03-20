extends Node

signal action_taken(player_id: String, value: int)

const THINK_MIN := 1.0
const THINK_MAX := 4.0
const GUESS_NOISE := 8

var player_id: String = ""
var _strategy: String = "average"
var _last_known_average: float = 50.0
var _round_manager: Node = null

func setup(pid: String, strategy: String = "average", rm: Node = null) -> void:
	player_id = pid
	_strategy = strategy
	_round_manager = rm

func decide_and_submit() -> void:
	var think_time := randf_range(THINK_MIN, THINK_MAX)
	await get_tree().create_timer(think_time).timeout
	var guess := _compute_guess()
	action_taken.emit(player_id, guess)
	if _round_manager:
		_round_manager.submit_guess(player_id, guess)

func notify_round_result(target: float) -> void:
	_last_known_average = target / 0.8

func _compute_guess() -> int:
	var base: int
	match _strategy:
		"low":
			base = int(_last_known_average * 0.8 * 0.5)
		"high":
			base = int(_last_known_average * 1.2)
		"random":
			base = randi() % 101
		_:
			base = int(_last_known_average * 0.8)
	var noise := randi() % (GUESS_NOISE * 2 + 1) - GUESS_NOISE
	return clampi(base + noise, 0, 100)
