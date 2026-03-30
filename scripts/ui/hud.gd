extends Control

const OP_ROUND_START := 1
const OP_ROUND_RESULT := 3
const OP_GAME_OVER := 4
const OP_CHAT_MESSAGE := 5
const OP_PLAYER_JOINED := 6
const OP_PLAYER_LEFT := 7
const OP_RECONNECT_STATE := 9

const TIMER_WARN_THRESHOLD := 5.0

@onready var local_name_label: Label = $TopLeftInfo/LocalPlayerName
@onready var local_lives_label: Label = $TopLeftInfo/LocalPlayerLives
@onready var timer_label: Label = $TopCenterInfo/TimerLabel
@onready var event_label: Label = $TopCenterInfo/EventLabel
@onready var guess_panel: Control = $GuessPanel
@onready var guess_input: LineEdit = $GuessPanel/GuessVBox/GuessInput
@onready var submit_button: Button = $GuessPanel/GuessVBox/SubmitButton
@onready var right_panel: PanelContainer = $RightPanel
@onready var players_container: VBoxContainer = $RightPanel/ScrollContainer/PlayersContainer
@onready var result_panel: Control = $ResultPanel
@onready var result_label: RichTextLabel = $ResultPanel/ResultLabel
@onready var chat_panel: Control = $BottomLeftActions/ChatPanel
@onready var chat_toggle: Button = $BottomLeftActions/ChatToggleButton

@onready var player_life_cells: Dictionary = {}

const C_PANEL      := Color(0.10, 0.08, 0.22, 0.95)
const C_PANEL_EDGE := Color(0.35, 0.20, 0.80, 0.50)
const C_ACCENT     := Color(0.45, 0.20, 1.00, 1.0)
const C_WHITE      := Color(1.0,  1.0,  1.0,  1.0)

var _timer_remaining: float = 30.0
var _is_guessing := false
var _has_guessed := false

func _ready() -> void:
	NakamaManager.message_received.connect(_on_message_received)
	GameState.lives_updated.connect(_on_lives_updated)
	result_panel.visible = false
	guess_panel.visible = false
	chat_panel.visible = false
	_apply_styles()
	_sync_initial_state()

func _sync_initial_state() -> void:
	local_name_label.text = GameState.local_player_username
	var local_p = GameState.get_player(GameState.local_player_id)
	if local_p.has("lives"):
		local_lives_label.text = "Lives: " + str(local_p["lives"])
	_rebuild_player_cells()
	_update_event_ui()
	
	if GameState.round_number > 0 and local_p.get("isAlive", true):
		var guess_val = local_p.get("guessValue", -1)
		var has_guessed = false
		if typeof(guess_val) == TYPE_ARRAY or guess_val != -1:
			has_guessed = true
		if not has_guessed:
			guess_panel.visible = true
			guess_input.editable = true
			submit_button.disabled = false
			_has_guessed = false
			_is_guessing = true
			if GameState.local_power_up == "double_guess":
				guess_input.placeholder_text = "e.g. 30 70"
			else:
				guess_input.placeholder_text = "Tebakan Anda"
			var elapsed_sec = GameState.get_guess_elapsed_ms() / 1000.0
			_timer_remaining = maxf(0.0, 35.0 - elapsed_sec)

func _apply_styles() -> void:
	var panels = [guess_panel, result_panel, chat_panel, right_panel]
	for p in panels:
		var sb := StyleBoxFlat.new()
		sb.bg_color = C_PANEL
		sb.border_color = C_PANEL_EDGE
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(12)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 16
		sb.content_margin_bottom = 16
		if p is PanelContainer:
			p.add_theme_stylebox_override("panel", sb)

	var inputs = [guess_input, chat_panel.get_node_or_null("VBox/InputRow/InputField")]
	for inp in inputs:
		if not inp: continue
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.4)
		sb.border_color = C_PANEL_EDGE
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		var sb_f := sb.duplicate() as StyleBoxFlat
		sb_f.border_color = C_ACCENT
		inp.add_theme_stylebox_override("normal", sb)
		inp.add_theme_stylebox_override("focus", sb_f)
		inp.add_theme_color_override("font_color", C_WHITE)

	var btns = [submit_button, chat_toggle, chat_panel.get_node_or_null("VBox/InputRow/SendButton")]
	for btn in btns:
		if not btn: continue
		var sb_n := StyleBoxFlat.new()
		sb_n.bg_color = C_ACCENT.darkened(0.2)
		sb_n.border_color = C_ACCENT
		sb_n.set_border_width_all(1)
		sb_n.set_corner_radius_all(8)
		var sb_h := sb_n.duplicate() as StyleBoxFlat
		sb_h.bg_color = C_ACCENT.lightened(0.2)
		btn.add_theme_stylebox_override("normal", sb_n)
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_stylebox_override("pressed", sb_n)
		btn.add_theme_color_override("font_color", C_WHITE)

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
			_rebuild_player_cells()
		OP_PLAYER_LEFT:
			_rebuild_player_cells()
		OP_RECONNECT_STATE:
			_sync_initial_state()

func _handle_round_start(data: Dictionary) -> void:
	result_panel.visible = false
	guess_panel.visible = true
	guess_input.text = ""
	guess_input.editable = true
	submit_button.disabled = false
	_has_guessed = false
	_timer_remaining = 30.0
	_is_guessing = true
	_update_event_ui()
	if GameState.local_power_up == "double_guess":
		guess_input.placeholder_text = "e.g. 30 70"
	else:
		guess_input.placeholder_text = "Your Guess"

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
		var name_str: String = pr.get("username", "?")
		var guess_val = pr.get("guessValue", 0)
		var guess_str := ""
		if typeof(guess_val) == TYPE_ARRAY:
			if guess_val.size() == 2:
				guess_str = str(guess_val[0]) + " & " + str(guess_val[1])
			elif guess_val.size() == 1:
				guess_str = str(guess_val[0])
		else:
			guess_str = str(guess_val)
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
	var hbox := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = str(pdata.get("username", "?"))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lives_lbl := Label.new()
	lives_lbl.text = "♥ " + str(pdata.get("lives", 10))
	lives_lbl.name = "LivesLabel"
	lives_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if not pdata.get("isAlive", true):
		lives_lbl.modulate = Color(0.4, 0.4, 0.4)
	hbox.add_child(name_lbl)
	hbox.add_child(lives_lbl)
	hbox.name = player_id
	return hbox

func _on_lives_updated(player_id: String, lives: int) -> void:
	if player_id == GameState.local_player_id:
		local_lives_label.text = "Lives: " + str(lives)
	if not player_life_cells.has(player_id):
		return
	var cell: HBoxContainer = player_life_cells[player_id]
	var lbl: Label = cell.get_node_or_null("LivesLabel")
	if lbl:
		lbl.text = "♥ " + str(lives)
		var tween := create_tween()
		tween.tween_property(lbl, "modulate", Color(1.0, 0.2, 0.2), 0.15)
		tween.tween_property(lbl, "modulate", Color.WHITE, 0.3)
		if lives <= 0:
			lbl.modulate = Color(0.4, 0.4, 0.4)

func _update_event_ui() -> void:
	if GameState.round_number == 0:
		event_label.text = "Waiting for players..."
		event_label.modulate = Color(0.7, 0.7, 0.7)
		guess_input.visible = false
		submit_button.visible = false
		return

	var ev = GameState.local_power_up
	var text := "Round " + str(GameState.round_number)
	var c := Color.WHITE
	if ev != "none" and ev != "":
		text += " | "
		match ev:
			"double_damage":
				text += "Double Damage"
				c = Color(1.0, 0.2, 0.2)
			"life_steal":
				text += "Life Steal"
				c = Color(0.2, 0.8, 0.2)
			"chaos_roll":
				text += "Chaos Roll"
				c = Color(0.8, 0.2, 0.8)
			"reverse_outcome":
				text += "Reverse Outcome"
				c = Color(0.8, 0.8, 0.2)
			"double_guess":
				text += "Double Guess"
				c = Color(0.2, 0.6, 1.0)
	event_label.text = text
	event_label.modulate = c
	if ev == "chaos_roll":
		guess_input.visible = false
		submit_button.visible = false
	else:
		guess_input.visible = true
		submit_button.visible = true

func _on_submit_pressed() -> void:
	if _has_guessed:
		return
	var local_p = GameState.get_player(GameState.local_player_id)
	if not local_p.get("isAlive", true):
		return
	var raw_text := guess_input.text.strip_edges()
	if GameState.local_power_up == "double_guess":
		var parts := raw_text.split(" ", false)
		if parts.size() < 2:
			return
		if not parts[0].is_valid_int() or not parts[1].is_valid_int():
			return
		var v1 := clampi(parts[0].to_int(), 0, 100)
		var v2 := clampi(parts[1].to_int(), 0, 100)
		_submit_payload([v1, v2])
	else:
		if not raw_text.is_valid_int():
			return
		var value := clampi(raw_text.to_int(), 0, 100)
		_submit_payload(value)

func _auto_submit() -> void:
	if _has_guessed:
		return
	if GameState.local_power_up == "double_guess":
		_submit_payload([randi() % 101, randi() % 101])
	elif GameState.local_power_up != "chaos_roll":
		_submit_payload(randi() % 101)

func _submit_payload(val: Variant) -> void:
	_has_guessed = true
	_is_guessing = false
	guess_input.editable = false
	submit_button.disabled = true
	NakamaManager.send_message(2, {"value": val})

func _on_chat_toggle() -> void:
	chat_panel.visible = not chat_panel.visible
