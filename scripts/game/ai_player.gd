extends Node

const MIN_SUBMIT_DELAY := 5.0
const MAX_SUBMIT_DELAY := 25.0
const NAIVE_BIAS_CENTER := 60.0
const NAIVE_BIAS_SPREAD := 20.0

var _player_id: String
var _is_active := false
var _submit_timer: Timer

func setup(player_id: String) -> void:
	_player_id = player_id
	_submit_timer = Timer.new()
	_submit_timer.one_shot = true
	_submit_timer.timeout.connect(_on_submit_timeout)
	add_child(_submit_timer)

func activate_for_round() -> void:
	_is_active = true
	var delay := randf_range(MIN_SUBMIT_DELAY, MAX_SUBMIT_DELAY)
	_submit_timer.start(delay)

func deactivate() -> void:
	_is_active = false
	_submit_timer.stop()

func _on_submit_timeout() -> void:
	if not _is_active:
		return
	_is_active = false
	var guess := _generate_guess()
	NakamaManager.send_message(2, {"value": guess})

func _generate_guess() -> int:
	var value: float
	if randf() < 0.7:
		value = randfn(NAIVE_BIAS_CENTER, NAIVE_BIAS_SPREAD)
	else:
		value = randf() * 100.0
	return clampi(int(value), 0, 100)
