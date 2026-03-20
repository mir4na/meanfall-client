extends Node

signal timer_tick(seconds_left: float)
signal timer_expired

const ROUND_DURATION := 30.0

var _time_left: float = 0.0
var _running: bool = false

func start() -> void:
	_time_left = ROUND_DURATION
	_running = true

func stop() -> void:
	_running = false

func reset() -> void:
	_running = false
	_time_left = 0.0

func get_time_left() -> float:
	return _time_left

func _process(delta: float) -> void:
	if not _running:
		return
	_time_left = maxf(0.0, _time_left - delta)
	timer_tick.emit(_time_left)
	if _time_left <= 0.0:
		_running = false
		timer_expired.emit()
