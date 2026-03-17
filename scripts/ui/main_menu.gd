extends Control

func _ready() -> void:
	_animate_in()
	NakamaManager.session_connected.connect(_on_session_connected)

func _animate_in() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)

func _on_play_pressed() -> void:
	GameState.is_ranked = true
	SceneTransition.fade_to_scene("res://scenes/ui/lobby/lobby.tscn")

func _on_custom_room_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/custom_room/custom_room.tscn")

func _on_profile_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/profile/profile.tscn")

func _on_leaderboard_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/leaderboard/leaderboard.tscn")

func _on_settings_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/settings/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_session_connected(_session) -> void:
	pass
