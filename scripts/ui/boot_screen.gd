extends Control

func _ready() -> void:
	# Give the engine a frame to render the loading screen
	await get_tree().process_frame
	
	# Try to restore the session from saved token securely
	var success = await NakamaManager.restore_session_async()
	
	if success:
		# If we have a valid session, go straight to the main menu unconditionally
		SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")
	else:
		# Otherwise, we need them to authenticate via the login overlay
		SceneTransition.fade_to_scene("res://scenes/ui/login_overlay.tscn")
