extends Control

@onready var list_container: VBoxContainer = $Panel/VBox/ScrollContainer/ListContainer
@onready var back_button: Button = $Panel/VBox/BackButton
@onready var loading_label: Label = $Panel/VBox/LoadingLabel
@onready var title_label: Label = $Panel/VBox/TitleLabel

func _ready() -> void:
	_load_leaderboard()

func _load_leaderboard() -> void:
	loading_label.visible = true
	var result = await NakamaManager.rpc_call("get_leaderboard", {"limit": 50})
	loading_label.visible = false
	if result.has("error"):
		loading_label.text = "Failed to load leaderboard"
		loading_label.visible = true
		return
	_populate(result.get("records", []))

func _populate(records: Array) -> void:
	for child in list_container.get_children():
		child.queue_free()
	for i in records.size():
		var record: Dictionary = records[i]
		var row := HBoxContainer.new()
		var rank_label := Label.new()
		rank_label.text = "#" + str(record.get("rank", i + 1))
		rank_label.custom_minimum_size.x = 60.0
		var name_label := Label.new()
		name_label.text = str(record.get("username", "Unknown"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var elo_label := Label.new()
		elo_label.text = str(record.get("points", 0))
		elo_label.custom_minimum_size.x = 80.0
		var league_label := Label.new()
		league_label.text = str(record.get("league", ""))
		league_label.custom_minimum_size.x = 100.0
		row.add_child(rank_label)
		row.add_child(name_label)
		row.add_child(elo_label)
		row.add_child(league_label)
		list_container.add_child(row)

func _on_back_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")
