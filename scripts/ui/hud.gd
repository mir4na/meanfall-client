extends Control

const OP_ROUND_START := 1
const OP_ROUND_RESULT := 3
const OP_GAME_OVER := 4
const OP_CHAT_MESSAGE := 5
const OP_PLAYER_JOINED := 6
const OP_PLAYER_LEFT := 7
const OP_POWERUP_ACTIVATE := 8
const OP_RECONNECT_STATE := 9

const TIMER_WARN_THRESHOLD := 5.0

@onready var round_label: Label = $TopBar/RoundLabel
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var players_container: HBoxContainer = $PlayersBar/PlayersContainer
@onready var guess_panel: Control = $GuessPanel
@onready var guess_input: LineEdit = $GuessPanel/GuessInput
@onready var submit_button: Button = $GuessPanel/SubmitButton
@onready var powerup_button: Button = $GuessPanel/PowerupButton
@onready var powerup_label: Label = $GuessPanel/PowerupLabel
@onready var result_panel: Control = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultLabel
@onready var chat_panel: Control = $ChatPanel
@onready var chat_toggle: Button = $ChatToggleButton
@onready var player_life_cells: Dictionary = {}

var _timer_remaining: float = 30.0
var _is_guessing := false
var _has_guessed := false
var _active_power_up := "none"

func _ready() -> void:
	submit_button.pressed.connect(_on_submit_pressed)
	powerup_button.pressed.connect(_on_powerup_pressed)
	chat_toggle.pressed.connect(_on_chat_toggle)
	NakamaManager.message_received.connect(_on_message_received)
	GameState.lives_updated.connect(_on_lives_updated)
	result_panel.visible = false
	guess_panel.visible = false
	chat_panel.visible = false

func _process(delta: float) -> void:
	if not _is_guessing:
		return
	_timer_remaining = maxf(0.0, _timer_remaining - delta)
	timer_label.text = str(ceili(_timer_remaining))
	if _timer_remaining <= TIMER_WARN_THRESHOLD:
		timer_label.modulate = Color(1.0, 0.2, 0.2)
	else:
		timer_label.modulate = Color.WHITE
	if _timer_remaining <= 0.0:
		_is_guessing = false
		_auto_submit()

func _on_message_received(op_code: int, data: Dictionary) -> void:
	match op_code:
		OP_ROUND_START:
			_handle_round_start(data)
		OP_ROUND_RESULT:
			_handle_round_result(data)
		OP_GAME_OVER:
			_handle_game_over(data)
		OP_PLAYER_JOINED:
			_handle_player_joined(data)
		OP_PLAYER_LEFT:
			_handle_player_left(data)
		OP_POWERUP_ACTIVATE:
			_handle_powerup_activate(data)
		OP_RECONNECT_STATE:
			_handle_reconnect_state(data)

func _handle_round_start(data: Dictionary) -> void:
	var round_num: int = data.get("roundNumber", 1)
	GameState.round_number = round_num
	GameState.start_guess_timer()
	round_label.text = "Round " + str(round_num)
	result_panel.visible = false
	guess_panel.visible = true
	guess_input.text = ""
	guess_input.editable = true
	submit_button.disabled = false
	_has_guessed = false
	_timer_remaining = 30.0
	_is_guessing = true
	var power_ups: Dictionary = data.get("powerUps", {})
	_active_power_up = power_ups.get(GameState.local_player_id, "none")
	GameState.local_power_up = _active_power_up
	_update_powerup_ui()
	_rebuild_player_cells()

func _handle_round_result(data: Dictionary) -> void:
	_is_guessing = false
	guess_panel.visible = false
	result_panel.visible = true
	var player_results: Dictionary = data.get("playerResults", {})
	var target: float = data.get("target", 0.0)
	var is_2p: bool = data.get("is2PlayerMode", false)
	var result_text := ""
	if is_2p:
		result_text = "2-Player Mode! Random target: " + str(int(target)) + "\n"
	else:
		result_text = "Average: " + str(snapped(target, 0.01)) + "\n"
	for player_id in player_results:
		var pr: Dictionary = player_results[player_id]
		GameState.update_player(player_id, pr)
		var name_str: String = pr.get("username", "?")
		var guess_str: String = str(pr.get("guessValue", 0))
		var lives_str: String = str(pr.get("lives", 0))
		var winner_tag: String = " ★" if pr.get("isWinner", false) else ""
		result_text += name_str + ": " + guess_str + winner_tag + " (lives: " + lives_str + ")\n"
	result_label.text = result_text

func _handle_game_over(data: Dictionary) -> void:
	_is_guessing = false
	guess_panel.visible = false
	var winner_name: String = data.get("winnerUsername", "")
	var panel_text := "GAME OVER\n"
	if winner_name != "":
		panel_text += winner_name + " wins!"
	else:
		panel_text += "No winner."
	result_label.text = panel_text
	result_panel.visible = true
	await get_tree().create_timer(5.0).timeout
	await NakamaManager.leave_match()
	GameState.reset()
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")

func _handle_player_joined(data: Dictionary) -> void:
	var player_id: String = data.get("userId", "")
	GameState.update_player(player_id, data)
	_rebuild_player_cells()

func _handle_player_left(data: Dictionary) -> void:
	pass

func _handle_powerup_activate(data: Dictionary) -> void:
	pass

func _handle_reconnect_state(data: Dictionary) -> void:
	var player_list: Array = data.get("players", [])
	for pdata in player_list:
		var pid: String = pdata.get("userId", "")
		GameState.update_player(pid, pdata)
	GameState.round_number = data.get("roundNumber", 1)
	round_label.text = "Round " + str(GameState.round_number)
	_rebuild_player_cells()

func _rebuild_player_cells() -> void:
	for child in players_container.get_children():
		child.queue_free()
	player_life_cells.clear()
	for player_id in GameState.players:
		var pdata: Dictionary = GameState.players[player_id]
		var cell := _create_player_cell(player_id, pdata)
		players_container.add_child(cell)
		player_life_cells[player_id] = cell

func _create_player_cell(player_id: String, pdata: Dictionary) -> Control:
	var vbox := VBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = str(pdata.get("username", "?"))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lives_lbl := Label.new()
	lives_lbl.text = "♥ " + str(pdata.get("lives", 10))
	lives_lbl.name = "LivesLabel"
	lives_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not pdata.get("isAlive", true):
		lives_lbl.modulate = Color(0.4, 0.4, 0.4)
	vbox.add_child(name_lbl)
	vbox.add_child(lives_lbl)
	vbox.name = player_id
	return vbox

func _on_lives_updated(player_id: String, lives: int) -> void:
	if not player_life_cells.has(player_id):
		return
	var cell: VBoxContainer = player_life_cells[player_id]
	var lbl: Label = cell.get_node_or_null("LivesLabel")
	if lbl:
		lbl.text = "♥ " + str(lives)
		var tween := create_tween()
		tween.tween_property(lbl, "modulate", Color(1.0, 0.2, 0.2), 0.15)
		tween.tween_property(lbl, "modulate", Color.WHITE, 0.3)
		if lives <= 0:
			lbl.modulate = Color(0.4, 0.4, 0.4)

func _update_powerup_ui() -> void:
	if _active_power_up == "none":
		powerup_button.visible = false
		powerup_label.text = ""
	else:
		powerup_button.visible = true
		var pu := PowerUp.from_string(_active_power_up)
		powerup_label.text = pu.display_name
		powerup_button.modulate = pu.color

func _on_submit_pressed() -> void:
	if _has_guessed:
		return
	var raw_text := guess_input.text.strip_edges()
	if not raw_text.is_valid_int():
		return
	var value := clampi(int(raw_text), 0, 100)
	_submit_guess(value)

func _auto_submit() -> void:
	if _has_guessed:
		return
	_submit_guess(randi() % 101)

func _submit_guess(value: int) -> void:
	_has_guessed = true
	_is_guessing = false
	guess_input.editable = false
	submit_button.disabled = true
	NakamaManager.send_message(2, {"value": value})

func _on_powerup_pressed() -> void:
	if _active_power_up == "none":
		return
	NakamaManager.send_message(8, {"powerUpType": _active_power_up})
	powerup_button.disabled = true

func _on_chat_toggle() -> void:
	chat_panel.visible = not chat_panel.visible
