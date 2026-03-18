extends Control

const C_PANEL      := Color(0.10, 0.08, 0.22, 0.95)
const C_PANEL_EDGE := Color(0.35, 0.20, 0.80, 0.50)
const C_ACCENT     := Color(0.45, 0.20, 1.00, 1.0)
const C_ACCENT2    := Color(0.15, 0.55, 1.00, 1.0)
const C_RED        := Color(1.00, 0.25, 0.25, 1.0)
const C_GOLD       := Color(1.00, 0.82, 0.15, 1.0)

@onready var username_lbl := $ProfileCard/Margin/HBox/VBox/Username
@onready var points_lbl   := $ProfileCard/Margin/HBox/VBox/Points

func _ready() -> void:
	_apply_styles()
	_animate_in()
	NakamaManager.session_connected.connect(_on_session_connected)
	_refresh_profile()

func _apply_styles() -> void:
	# Profile Card
	var pr_sb := StyleBoxFlat.new()
	pr_sb.bg_color = C_PANEL
	pr_sb.border_color = C_PANEL_EDGE
	pr_sb.set_border_width_all(1)
	pr_sb.set_corner_radius_all(12)
	pr_sb.shadow_color = Color(0, 0, 0, 0.4)
	pr_sb.shadow_size = 12
	pr_sb.shadow_offset = Vector2(0, 4)
	$ProfileCard.add_theme_stylebox_override("panel", pr_sb)

	# Avatar
	$ProfileCard/Margin/HBox/Avatar.color = C_ACCENT
	
	# Settings Button
	var st_btn := $SettingsBtn
	var st_sb_n := StyleBoxFlat.new()
	st_sb_n.bg_color = C_PANEL
	st_sb_n.border_color = C_PANEL_EDGE
	st_sb_n.set_border_width_all(1)
	st_sb_n.set_corner_radius_all(10)
	var st_sb_h := st_sb_n.duplicate() as StyleBoxFlat
	st_sb_h.bg_color = C_ACCENT.darkened(0.5)
	st_sb_h.border_color = C_ACCENT
	st_btn.add_theme_stylebox_override("normal", st_sb_n)
	st_btn.add_theme_stylebox_override("hover",  st_sb_h)
	st_btn.add_theme_stylebox_override("pressed", st_sb_n)

	# Play Button
	var play_btn := $CenterArea/VBox/PlayBtn
	var pl_sb_n := StyleBoxFlat.new()
	pl_sb_n.bg_color = C_ACCENT.lerp(C_ACCENT2, 0.35)
	pl_sb_n.border_color = C_ACCENT
	pl_sb_n.set_border_width_all(2)
	pl_sb_n.set_corner_radius_all(14)
	pl_sb_n.shadow_color = C_ACCENT.darkened(0.3)
	pl_sb_n.shadow_size  = 16
	pl_sb_n.shadow_offset = Vector2(0, 4)
	var pl_sb_h := pl_sb_n.duplicate() as StyleBoxFlat
	pl_sb_h.bg_color = C_ACCENT.lightened(0.18)
	pl_sb_h.border_color = C_ACCENT.lightened(0.35)
	pl_sb_h.shadow_size = 24
	pl_sb_h.shadow_color = C_ACCENT.lightened(0.1)
	play_btn.add_theme_stylebox_override("normal", pl_sb_n)
	play_btn.add_theme_stylebox_override("hover",  pl_sb_h)
	play_btn.add_theme_stylebox_override("pressed", pl_sb_n)

	# Bottom Dock
	var dock := $BottomDock
	var dk_sb := StyleBoxFlat.new()
	dk_sb.bg_color = Color(0.05, 0.04, 0.12, 0.96)
	dk_sb.border_color = C_PANEL_EDGE
	dk_sb.set_border_width_all(1)
	dock.add_theme_stylebox_override("panel", dk_sb)

	# Dock Buttons
	_style_dock_btn($BottomDock/HBox/CustomBtn, C_ACCENT2)
	_style_dock_btn($BottomDock/HBox/Profile2Btn, Color(0.55, 0.55, 0.72))
	_style_dock_btn($BottomDock/HBox/LeaderboardBtn, C_GOLD)
	_style_dock_btn($BottomDock/HBox/QuitBtn, C_RED)


func _style_dock_btn(btn: Button, col: Color) -> void:
	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color.TRANSPARENT
	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = col.darkened(0.75)
	sb_h.border_color = col
	sb_h.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover",  sb_h)
	btn.add_theme_stylebox_override("pressed", sb_n)

func _animate_in() -> void:
	modulate.a = 0.0
	position.y = 25.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", 0.0, 0.45).set_ease(Tween.EASE_OUT)

func _refresh_profile() -> void:
	if username_lbl:
		username_lbl.text = GameState.local_player_username
	var stats = await NakamaManager.get_player_stats()
	if not stats.has("error") and points_lbl:
		points_lbl.text = str(stats.get("totalPoints", 0)) + " pts • " + stats.get("league", "Bronze")

# ─── NAVIGATION ───


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
	_refresh_profile()
