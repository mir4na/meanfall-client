extends Node3D

var _player_id: String = ""
var _username: String = ""
var _lives: int = 10

const PLAYER_CHARACTER_SCENE := preload("res://scenes/game/player_character/player_character.tscn")

var _character: Node3D
var _name_label: Label3D
var _lives_label: Label3D

func setup(player_id: String, username: String, lives: int) -> void:
	_player_id = player_id
	_username = username
	_lives = lives
	
	_character = PLAYER_CHARACTER_SCENE.instantiate()
	add_child(_character)
	
	_name_label = _character.get_node("UsernameLabel")
	_name_label.text = username
	_name_label.modulate = _get_player_color(player_id)
	
	_lives_label = Label3D.new()
	_lives_label.text = "♥ " + str(lives)
	_lives_label.font_size = 48
	_lives_label.modulate = Color(1.0, 0.3, 0.3)
	_lives_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lives_label.position = Vector3(0, 2.6, 0)
	add_child(_lives_label)
	
	var parts = ["Torso", "Torso/ArmL", "Torso/ArmR", "LegL", "LegR"]
	var player_color = _get_player_color(player_id)
	
	for part_name in parts:
		var mesh_inst: MeshInstance3D = _character.get_node(part_name)
		var mat: StandardMaterial3D = mesh_inst.mesh.surface_get_material(0).duplicate()
		mat.albedo_color = player_color
		mesh_inst.set_surface_override_material(0, mat)
	
	_connect_signals()

func _connect_signals() -> void:
	GameState.lives_updated.connect(_on_lives_updated)
	GameState.player_eliminated.connect(_on_player_eliminated)

func _on_lives_updated(player_id: String, lives: int) -> void:
	if player_id != _player_id:
		return
	_lives = lives
	_lives_label.text = "♥ " + str(lives)
	var tween := create_tween()
	tween.tween_property(_character, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property(_character, "scale", Vector3.ONE, 0.2)

func _on_player_eliminated(player_id: String) -> void:
	if player_id != _player_id:
		return
	_lives_label.modulate = Color(0.4, 0.4, 0.4)
	_name_label.modulate = Color(0.4, 0.4, 0.4)
	var parts = ["Torso", "Torso/ArmL", "Torso/ArmR", "LegL", "LegR"]
	var tween := create_tween().set_parallel(true)
	for part_name in parts:
		var mesh_inst: MeshInstance3D = _character.get_node(part_name)
		var mat: StandardMaterial3D = mesh_inst.get_surface_override_material(0)
		if mat:
			tween.tween_property(mat, "albedo_color", Color(0.2, 0.2, 0.2), 0.6)

func _get_player_color(player_id: String) -> Color:
	var rng := RandomNumberGenerator.new()
	rng.seed = player_id.hash()
	var h = rng.randf()
	var s = rng.randf_range(0.6, 0.9)
	var v = rng.randf_range(0.7, 1.0)
	return Color.from_hsv(h, s, v)
