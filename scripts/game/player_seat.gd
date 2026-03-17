extends Node3D

var _player_id: String = ""
var _username: String = ""
var _lives: int = 10

var _name_label: Label3D
var _lives_label: Label3D
var _character_mesh: MeshInstance3D

func setup(player_id: String, username: String, lives: int) -> void:
	_player_id = player_id
	_username = username
	_lives = lives
	_build_character()
	_build_labels()
	_connect_signals()

func _build_character() -> void:
	var body := MeshInstance3D.new()
	var body_cyl := CylinderMesh.new()
	body_cyl.top_radius = 0.25
	body_cyl.bottom_radius = 0.25
	body_cyl.height = 1.0
	body.mesh = body_cyl
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = _get_player_color(_player_id)
	body_mat.roughness = 0.4
	body_mat.metallic = 0.1
	body.surface_override_material(0, body_mat)
	body.position = Vector3(0, 0.5, 0)
	add_child(body)
	_character_mesh = body

	var head := MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.22
	head_sphere.height = 0.44
	head.mesh = head_sphere
	head.surface_override_material(0, body_mat)
	head.position = Vector3(0, 1.2, 0)
	add_child(head)

	var chair_seat := MeshInstance3D.new()
	var chair_box := BoxMesh.new()
	chair_box.size = Vector3(0.6, 0.08, 0.6)
	chair_seat.mesh = chair_box
	var chair_mat := StandardMaterial3D.new()
	chair_mat.albedo_color = Color(0.15, 0.1, 0.08)
	chair_mat.roughness = 0.8
	chair_seat.surface_override_material(0, chair_mat)
	chair_seat.position = Vector3(0, -0.06, 0)
	add_child(chair_seat)

func _build_labels() -> void:
	_name_label = Label3D.new()
	_name_label.text = _username
	_name_label.font_size = 28
	_name_label.modulate = Color.WHITE
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.position = Vector3(0, 1.7, 0)
	add_child(_name_label)

	_lives_label = Label3D.new()
	_lives_label.text = "♥ " + str(_lives)
	_lives_label.font_size = 22
	_lives_label.modulate = Color(1.0, 0.3, 0.3)
	_lives_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lives_label.position = Vector3(0, 1.4, 0)
	add_child(_lives_label)

func _connect_signals() -> void:
	GameState.lives_updated.connect(_on_lives_updated)
	GameState.player_eliminated.connect(_on_player_eliminated)

func _on_lives_updated(player_id: String, lives: int) -> void:
	if player_id != _player_id:
		return
	_lives = lives
	_lives_label.text = "♥ " + str(lives)
	var tween := create_tween()
	tween.tween_property(_character_mesh, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property(_character_mesh, "scale", Vector3.ONE, 0.2)

func _on_player_eliminated(player_id: String) -> void:
	if player_id != _player_id:
		return
	_lives_label.modulate = Color(0.4, 0.4, 0.4)
	_name_label.modulate = Color(0.4, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(_character_mesh, "modulate", Color(0.3, 0.3, 0.3), 0.6)

func _get_player_color(player_id: String) -> Color:
	var colors := [
		Color(0.2, 0.6, 1.0),
		Color(1.0, 0.3, 0.3),
		Color(0.3, 0.9, 0.4),
		Color(1.0, 0.8, 0.1),
		Color(0.8, 0.3, 0.9),
		Color(0.2, 0.9, 0.9),
		Color(1.0, 0.5, 0.1),
		Color(0.9, 0.9, 0.4),
		Color(0.5, 0.3, 0.8),
		Color(0.9, 0.5, 0.7),
	]
	var hash_val := player_id.hash()
	return colors[abs(hash_val) % colors.size()]
