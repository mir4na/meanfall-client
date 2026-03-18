extends MarginContainer

@onready var username_label: Label = $HBox/VBox/UsernameLabel
@onready var stats_label: Label = $HBox/VBox/StatsLabel

func _ready() -> void:
	# Update initially from GameState if session exists
	if GameState.session:
		_update_display()
		_fetch_latest_stats()
	
	NakamaManager.session_connected.connect(_on_session_connected)

func _on_session_connected(_session) -> void:
	_update_display()
	_fetch_latest_stats()

func _update_display() -> void:
	username_label.text = GameState.local_player_username
	if GameState.account.has("stats"):
		var stats = GameState.account.stats
		stats_label.text = str(stats.get("totalPoints", 0)) + " pts • " + stats.get("league", "Bronze")

func _fetch_latest_stats() -> void:
	var stats = await NakamaManager.get_player_stats()
	if not stats.has("error"):
		# Update GameState and UI
		GameState.account["stats"] = stats
		stats_label.text = str(stats.get("totalPoints", 0)) + " pts • " + stats.get("league", "Bronze")

func _on_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/profile.tscn")
