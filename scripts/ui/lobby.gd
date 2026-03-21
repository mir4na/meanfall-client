extends Control

const SEARCHING_DOT_INTERVAL := 0.5

var _dot_count := 0
var _dot_timer := 0.0
var _searching := false
var _waiting_for_players := false

@onready var status_label: Label = $Center/Panel/VBox/StatusLabel
@onready var cancel_button: Button = $Center/Panel/VBox/CancelButton

func _ready() -> void:
	NakamaManager.match_joined.connect(_on_match_joined)
	NakamaManager.session_failed.connect(_on_error)
	GameState.state_changed.connect(_on_game_state_changed)
	_start_matchmaking()

func _process(delta: float) -> void:
	if not _searching:
		return
	_dot_timer += delta
	if _dot_timer >= SEARCHING_DOT_INTERVAL:
		_dot_timer = 0.0
		_dot_count = (_dot_count + 1) % 4
		status_label.text = "Searching for opponents" + ".".repeat(_dot_count)

func _start_matchmaking() -> void:
	_searching = true
	status_label.text = "Searching for opponents"
	var result = await NakamaManager.rpc_call("find_or_create_ranked_match", {})
	if result.has("error"):
		_on_error(result["error"])
		return
	await NakamaManager.join_match(result.get("matchId", ""))

func _on_match_joined(_match_id: String) -> void:
	_searching = false
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

func _on_cancel_pressed() -> void:
	_searching = false
	_waiting_for_players = false
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")

func _on_error(message: String) -> void:
	_searching = false
	_waiting_for_players = false
	status_label.text = "Connection failed: " + message
