extends Control

const C_PANEL      := Color(0.10, 0.08, 0.22, 0.95)
const C_PANEL_EDGE := Color(0.35, 0.20, 0.80, 0.50)
const C_ACCENT     := Color(0.45, 0.20, 1.00, 1.0)
const C_ACCENT2    := Color(0.15, 0.55, 1.00, 1.0)
const C_RED        := Color(1.00, 0.25, 0.25, 1.0)
const C_GOLD       := Color(1.00, 0.82, 0.15, 1.0)

@onready var username_lbl := $ProfileCard/Margin/HBox/VBox/Username
@onready var points_lbl   := $ProfileCard/Margin/HBox/VBox/Points
@onready var bg_top: ColorRect = $Background/Top
@onready var title_label: Label = $CenterArea/VBox/LogoArea/Title

func _ready() -> void:
	_apply_styles()
	_apply_shaders()
	_animate_in()
	NakamaManager.session_connected.connect(_on_session_connected)
	_refresh_profile()
	_check_and_rejoin()

func _check_and_rejoin() -> void:
	if GameState.session == null:
		return
	var result = await NakamaManager.rpc_call("check_active_match", {})
	if result.has("error") or not result.has("matchId"):
		return
	var match_id: String = result["matchId"]
	if match_id.is_empty():
		return
	GameState.reset()
	await NakamaManager.join_match(match_id)
	if GameState.round_number > 0:
		SceneTransition.fade_to_scene("res://scenes/game/game_room/game_room.tscn", SceneTransition.Style.RADIAL, true)
	else:
		SceneTransition.fade_to_scene("res://scenes/game/elevator_intro/elevator_intro.tscn", SceneTransition.Style.RADIAL, true)

func _apply_shaders() -> void:
	ShaderFX.apply_bg_noise(bg_top, 0.8)
	var orb_shader := load("res://shaders/orb_glow.gdshader") as Shader
	var orbs := [
		[$Background/Orbs/Orb1, Color(0.5, 0.1, 0.9, 0.22)],
		[$Background/Orbs/Orb2, Color(0.1, 0.45, 0.95, 0.18)],
		[$Background/Orbs/Orb3, Color(0.4, 0.1, 0.8, 0.16)],
	]
	for entry in orbs:
		var orb: ColorRect = entry[0]
		var mat := ShaderMaterial.new()
		mat.shader = orb_shader
		mat.set_shader_parameter("orb_color", entry[1])
		mat.set_shader_parameter("softness", 0.6)
		orb.material = mat

func _apply_styles() -> void:
	var pr_sb := StyleBoxFlat.new()
	pr_sb.bg_color = C_PANEL
	pr_sb.border_color = C_PANEL_EDGE
	pr_sb.set_border_width_all(1)
	pr_sb.set_corner_radius_all(12)
	pr_sb.shadow_color = Color(0, 0, 0, 0.4)
	pr_sb.shadow_size = 12
	pr_sb.shadow_offset = Vector2(0, 4)
	$ProfileCard.add_theme_stylebox_override("panel", pr_sb)

	$ProfileCard/Margin/HBox/Avatar.color = C_ACCENT
	
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

	var play_btn := $CenterArea/VBox/PlayBtn
	var pl_n := StyleBoxFlat.new()
	pl_n.bg_color = Color(0.22, 0.10, 0.58, 1.0)
	pl_n.border_color = Color(0.55, 0.35, 1.0, 1.0)
	pl_n.set_border_width_all(2)
	pl_n.set_corner_radius_all(16)
	pl_n.shadow_color = Color(0.35, 0.10, 0.9, 0.5)
	pl_n.shadow_size = 20
	pl_n.shadow_offset = Vector2(0, 6)
	pl_n.content_margin_left = 24
	pl_n.content_margin_right = 24
	pl_n.content_margin_top = 8
	pl_n.content_margin_bottom = 8
	var pl_h := pl_n.duplicate() as StyleBoxFlat
	pl_h.bg_color = Color(0.30, 0.15, 0.72, 1.0)
	pl_h.border_color = Color(0.70, 0.55, 1.0, 1.0)
	pl_h.shadow_size = 30
	pl_h.shadow_color = Color(0.45, 0.20, 1.0, 0.55)
	var pl_p := pl_n.duplicate() as StyleBoxFlat
	pl_p.bg_color = Color(0.15, 0.06, 0.42, 1.0)
	pl_p.shadow_size = 8
	play_btn.add_theme_stylebox_override("normal", pl_n)
	play_btn.add_theme_stylebox_override("hover", pl_h)
	play_btn.add_theme_stylebox_override("pressed", pl_p)
	play_btn.add_theme_color_override("font_color", Color.WHITE)
	play_btn.add_theme_font_size_override("font_size", 26)

	var dock := $BottomDock
	var dk_sb := StyleBoxFlat.new()
	dk_sb.bg_color = Color(0.05, 0.04, 0.12, 0.96)
	dk_sb.border_color = C_PANEL_EDGE
	dk_sb.set_border_width_all(1)
	dock.add_theme_stylebox_override("panel", dk_sb)

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

func _on_play_pressed() -> void:
	GameState.is_ranked = true
	SceneTransition.fade_to_scene("res://scenes/ui/lobby/lobby.tscn", SceneTransition.Style.RADIAL)

func _on_custom_room_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/custom_room/custom_room.tscn", SceneTransition.Style.DISSOLVE)

func _on_profile_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/profile/profile.tscn", SceneTransition.Style.SLIDE_DOWN)

func _on_leaderboard_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/leaderboard/leaderboard.tscn", SceneTransition.Style.DISSOLVE)

func _on_settings_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/settings/settings.tscn", SceneTransition.Style.SLIDE_DOWN)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_session_connected(_session) -> void:
	_refresh_profile()
