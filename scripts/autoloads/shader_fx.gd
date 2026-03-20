extends Node

signal flash_done

func flash_life_loss(parent: Node) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 120
	parent.add_child(canvas)

	var shader := load("res://shaders/damage_flash.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("flash_alpha", 0.0)

	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	canvas.add_child(rect)

	var tw := parent.create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("flash_alpha", v), 0.65, 0.0, 0.45)
	await tw.finished
	canvas.queue_free()
	flash_done.emit()

func apply_vignette(parent: Node, strength: float = 0.5) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	parent.add_child(canvas)

	var shader := load("res://shaders/vignette.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("strength", strength)

	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color.WHITE
	rect.material = mat
	canvas.add_child(rect)

func apply_bg_noise(target: ColorRect, scale: float = 1.0) -> void:
	var shader := load("res://shaders/bg_noise.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("time_scale", scale)
	target.material = mat

func apply_glow(target: CanvasItem, color: Color = Color(0.45, 0.2, 1.0, 1.0), strength: float = 1.2) -> void:
	var shader := load("res://shaders/ui_glow.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("glow_color", color)
	mat.set_shader_parameter("glow_strength", strength)
	target.material = mat

func apply_hologram(target: CanvasItem, glitch: float = 0.0) -> void:
	var shader := load("res://shaders/hologram.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("glitch_strength", glitch)
	target.material = mat
