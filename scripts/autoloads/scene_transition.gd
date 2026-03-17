extends CanvasLayer

const FADE_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const FADE_DURATION := 0.4

var _overlay: ColorRect
var _anim: AnimationPlayer
var _is_transitioning := false

func _ready() -> void:
	layer = 128
	_overlay = ColorRect.new()
	_overlay.color = FADE_COLOR
	_overlay.color.a = 0.0
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func fade_to_scene(path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	await _fade_out()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await _fade_in()
	_is_transitioning = false

func fade_out() -> void:
	await _fade_out()

func fade_in() -> void:
	await _fade_in()

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await tween.finished

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)
	await tween.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
