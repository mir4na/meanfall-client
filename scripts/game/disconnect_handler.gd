extends Node

const RECONNECT_UI_SCENE := "res://scenes/ui/components/reconnect_overlay.tscn"

var _reconnect_overlay: Control

func _ready() -> void:
	NakamaManager.disconnected.connect(_on_disconnected)
	NakamaManager.reconnect_succeeded.connect(_on_reconnect_succeeded)
	NakamaManager.reconnect_failed.connect(_on_reconnect_failed)

func _on_disconnected() -> void:
	_show_reconnect_ui("Disconnected. Reconnecting...")

func _on_reconnect_succeeded() -> void:
	if _reconnect_overlay:
		_reconnect_overlay.queue_free()
		_reconnect_overlay = null

func _on_reconnect_failed() -> void:
	if _reconnect_overlay:
		var label: Label = _reconnect_overlay.get_node_or_null("Label")
		if label:
			label.text = "Reconnect failed. Returning to menu..."
	await get_tree().create_timer(2.0).timeout
	GameState.reset()
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")

func _show_reconnect_ui(message: String) -> void:
	if _reconnect_overlay:
		return
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.custom_minimum_size = Vector2(400, 120)
	var label := Label.new()
	label.name = "Label"
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_child(label)
	get_tree().get_root().add_child(overlay)
	_reconnect_overlay = overlay
