extends Control

@onready var username_label: Label = $Center/Panel/VBox/UsernameLabel
@onready var league_label: Label = $Center/Panel/VBox/LeagueLabel
@onready var elo_label: Label = $Center/Panel/VBox/EloLabel

func _ready() -> void:
	_load_profile()

func _load_profile() -> void:
	username_label.text = GameState.local_player_username
	var result = await NakamaManager.rpc_call("get_player_rank", {})
	if not result.has("error"):
		elo_label.text = "ELO: " + str(result.get("elo", 1000))
		league_label.text = "League: " + str(result.get("league", "Bronze"))

func _on_back_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")

func _on_logout_pressed() -> void:
	GameState.reset()
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")
