extends CanvasLayer

enum Style { DISSOLVE, RADIAL, SLIDE_DOWN, SLIDE_UP }

const DURATION := 0.45

var _overlay: ColorRect
var _mat: ShaderMaterial
var _style: Style = Style.DISSOLVE
var _is_transitioning := false

const _SHADERS := {
	Style.DISSOLVE:   "res://shaders/scene_dissolve.gdshader",
	Style.RADIAL:     "res://shaders/transition_radial.gdshader",
	Style.SLIDE_DOWN: "res://shaders/transition_slide.gdshader",
	Style.SLIDE_UP:   "res://shaders/transition_slide.gdshader",
}

func _ready() -> void:
	layer = 128
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_load_shader(Style.DISSOLVE)

func _load_shader(style: Style) -> void:
	_style = style
	var shader := load(_SHADERS[style]) as Shader
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("progress", 0.0)
	if style == Style.SLIDE_DOWN:
		_mat.set_shader_parameter("from_top", 1.0)
	elif style == Style.SLIDE_UP:
		_mat.set_shader_parameter("from_top", 0.0)
	_overlay.material = _mat

func fade_to_scene(path: String, style: Style = Style.DISSOLVE, skip_wipe_in: bool = false) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_load_shader(style)
	await _wipe_out()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	if skip_wipe_in:
		_mat.set_shader_parameter("progress", 0.0)
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		await _wipe_in()
	_is_transitioning = false

func fade_out(style: Style = Style.DISSOLVE) -> void:
	_load_shader(style)
	await _wipe_out()

func fade_in() -> void:
	await _wipe_in()

func _wipe_out() -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_method(func(v): _mat.set_shader_parameter("progress", v), 0.0, 1.0, DURATION)
	await tw.finished

func _wipe_in() -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v): _mat.set_shader_parameter("progress", v), 1.0, 0.0, DURATION)
	await tw.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
