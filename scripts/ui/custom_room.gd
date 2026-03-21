extends Control

@onready var create_panel: Control = $Center/Panel/VBox/CreatePanel
@onready var join_panel: Control = $Center/Panel/VBox/JoinPanel
@onready var max_players_slider: HSlider = $Center/Panel/VBox/CreatePanel/MaxPlayersSlider
@onready var max_lives_slider: HSlider = $Center/Panel/VBox/CreatePanel/MaxLivesSlider
@onready var bot_count_slider: HSlider = $Center/Panel/VBox/CreatePanel/BotCountSlider
@onready var max_players_label: Label = $Center/Panel/VBox/CreatePanel/MaxPlayersLabel
@onready var max_lives_label: Label = $Center/Panel/VBox/CreatePanel/MaxLivesLabel
@onready var bot_count_label: Label = $Center/Panel/VBox/CreatePanel/BotCountLabel
@onready var room_code_input: LineEdit = $Center/Panel/VBox/JoinPanel/RoomCodeInput
@onready var status_label: Label = $Center/Panel/VBox/StatusLabel
@onready var create_button: Button = $Center/Panel/VBox/CreatePanel/CreateButton
@onready var join_button: Button = $Center/Panel/VBox/JoinPanel/JoinButton
@onready var room_code_display: Label = $Center/Panel/VBox/CreatePanel/RoomCodeDisplay

var _waiting_for_players := false

func _ready() -> void:
	NakamaManager.match_joined.connect(_on_match_joined)
	NakamaManager.session_failed.connect(_on_error)
	GameState.state_changed.connect(_on_game_state_changed)
	_update_labels()

func _on_create_tab_pressed() -> void:
	create_panel.visible = true
	join_panel.visible = false

func _on_join_tab_pressed() -> void:
	create_panel.visible = false
	join_panel.visible = true

func _on_max_players_changed(value: float) -> void:
	max_players_label.text = "Players: " + str(int(value))
	bot_count_slider.max_value = int(value) - 1

func _on_max_lives_changed(value: float) -> void:
	max_lives_label.text = "Lives: " + str(int(value))

func _on_bot_count_changed(value: float) -> void:
	bot_count_label.text = "Bots: " + str(int(value))

func _update_labels() -> void:
	_on_max_players_changed(max_players_slider.value)
	_on_max_lives_changed(max_lives_slider.value)
	_on_bot_count_changed(bot_count_slider.value)

func _on_create_pressed() -> void:
	create_button.disabled = true
	status_label.text = "Creating room..."
	var result = await NakamaManager.rpc_call("create_custom_room", {
		"max_players": int(max_players_slider.value),
		"max_lives": int(max_lives_slider.value),
		"bot_count": int(bot_count_slider.value),
	})
	if result.has("error"):
		_on_error(result["error"])
		create_button.disabled = false
		return
	var room_code: String = result.get("roomCode", "")
	room_code_display.text = "Room Code: " + room_code
	GameState.room_code = room_code
	await NakamaManager.join_match(result.get("matchId", ""))

func _on_join_pressed() -> void:
	var code := room_code_input.text.strip_edges().to_upper()
	if code.length() != 6:
		status_label.text = "Enter a valid 6-character room code"
		return
	join_button.disabled = true
	status_label.text = "Joining room..."
	var result = await NakamaManager.rpc_call("join_custom_room", {"room_code": code})
	if result.has("error"):
		_on_error(result["error"])
		join_button.disabled = false
		return
	GameState.room_code = code
	await NakamaManager.join_match(result.get("matchId", ""))

func _on_match_joined(_match_id: String) -> void:
	_waiting_for_players = true
	_update_status_label()
	if GameState.round_number > 0:
		_waiting_for_players = false
		SceneTransition.fade_to_scene("res://scenes/game/elevator_intro/elevator_intro.tscn", SceneTransition.Style.RADIAL, true)

func _on_game_state_changed() -> void:
	if not _waiting_for_players:
		return
	_update_status_label()
	if GameState.round_number > 0:
		_waiting_for_players = false
		SceneTransition.fade_to_scene("res://scenes/game/elevator_intro/elevator_intro.tscn", SceneTransition.Style.RADIAL, true)

func _update_status_label() -> void:
	var count = GameState.get_alive_players().size()
	status_label.text = "Waiting for players... (" + str(count) + "/3)"

func _on_back_pressed() -> void:
	_waiting_for_players = false
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")

func _on_error(message: String) -> void:
	_waiting_for_players = false
	status_label.text = "Error: " + message
