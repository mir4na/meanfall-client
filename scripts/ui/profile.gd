extends Control

@onready var username_label: Label = $Margin/HBox/StatsPanel/VBox/UsernameLabel
@onready var league_label: Label = $Margin/HBox/StatsPanel/VBox/LeagueLabel
@onready var points_value: Label = $Margin/HBox/StatsPanel/VBox/Grid/PointsValue
@onready var matches_value: Label = $Margin/HBox/StatsPanel/VBox/Grid/MatchesValue
@onready var winrate_value: Label = $Margin/HBox/StatsPanel/VBox/Grid/WinrateValue
@onready var playtime_value: Label = $Margin/HBox/StatsPanel/VBox/Grid/PlaytimeValue
@onready var history_list: VBoxContainer = $Margin/HBox/HistoryPanel/VBox/Scroll/HistoryList

func _ready() -> void:
	var bg: ColorRect = $Background
	var shader := load("res://shaders/bg_aurora.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	bg.material = mat
	_load_profile()

func _load_profile() -> void:
	username_label.text = GameState.local_player_username
	
	var stats = await NakamaManager.get_player_stats()
	if not stats.has("error"):
		points_value.text = str(stats.get("totalPoints", 0))
		league_label.text = stats.get("league", "Bronze") + " League"
		matches_value.text = str(stats.get("totalMatches", 0))
		winrate_value.text = str(int(float(stats.get("winrate", "0.0")) * 100)) + "%"
		
		var total_sec := int(stats.get("totalPlaytimeSec", 0))
		var hours := total_sec / 3600
		var minutes := (total_sec % 3600) / 60
		playtime_value.text = str(hours) + "h " + str(minutes) + "m"
	
	var history = await NakamaManager.get_match_history()
	for child in history_list.get_children():
		child.queue_free()
		
	if history.has("matches") and history.matches.size() > 0:
		for m in history.matches:
			_add_history_item(m)
	else:
		var empty_label = Label.new()
		empty_label.text = "No matches played yet."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		history_list.add_child(empty_label)

func _add_history_item(m: Dictionary) -> void:
	var panel = PanelContainer.new()
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	
	var rank_label = Label.new()
	rank_label.text = "#" + str(m.get("rank", "?"))
	rank_label.add_theme_font_size_override("font_size", 20)
	if m.get("rank") == 1:
		rank_label.add_theme_color_override("font_color", Color.GOLD)
	
	var points_label = Label.new()
	points_label.text = "+" + str(m.get("pointsGained", 0)) + " pts"
	points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var date_label = Label.new()
	var time_dict = Time.get_datetime_dict_from_unix_time(int(float(m.get("timestamp", 0)) / 1000.0))
	date_label.text = str(time_dict.day) + "/" + str(time_dict.month) + "/" + str(time_dict.year)
	date_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	
	hbox.add_child(rank_label)
	hbox.add_child(points_label)
	hbox.add_child(date_label)
	margin.add_child(hbox)
	panel.add_child(margin)
	history_list.add_child(panel)

func _on_back_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn", SceneTransition.Style.SLIDE_UP)

func _on_logout_pressed() -> void:
	#GameState.reset()
	#SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")
	pass
