extends Node3D

const SEAT_RADIUS := 3.5
const PLAYER_SEAT_SCENE := "res://scenes/game/player_seat/player_seat.tscn"
const HUD_SCENE := "res://scenes/ui/hud/hud.tscn"

var _player_seats: Dictionary = {}
var _hud: Control

func _ready() -> void:
	_build_room()
	_setup_lighting()
	_setup_camera()
	_add_hud()
	_connect_signals()
	_reveal_camera()

func _build_room() -> void:
	var floor_mesh := MeshInstance3D.new()
	var floor_plane := PlaneMesh.new()
	floor_plane.size = Vector2(20.0, 20.0)
	floor_mesh.mesh = floor_plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.06, 0.06, 0.1)
	floor_mat.roughness = 0.7
	floor_mat.metallic = 0.1
	floor_mesh.surface_override_material(0, floor_mat)
	add_child(floor_mesh)

	var table_mesh := MeshInstance3D.new()
	var table_cyl := CylinderMesh.new()
	table_cyl.top_radius = 2.2
	table_cyl.bottom_radius = 2.2
	table_cyl.height = 0.15
	table_mesh.mesh = table_cyl
	var table_mat := StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.12, 0.08, 0.05)
	table_mat.roughness = 0.5
	table_mat.metallic = 0.2
	table_mesh.surface_override_material(0, table_mat)
	table_mesh.position = Vector3(0, 0.78, 0)
	add_child(table_mesh)

	var table_base := MeshInstance3D.new()
	var base_cyl := CylinderMesh.new()
	base_cyl.top_radius = 0.2
	base_cyl.bottom_radius = 0.4
	base_cyl.height = 0.8
	table_base.mesh = base_cyl
	table_base.surface_override_material(0, table_mat)
	table_base.position = Vector3(0, 0.4, 0)
	add_child(table_base)

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.1, 0.08, 0.15)
	wall_mat.roughness = 0.8
	for i in 4:
		var wall := MeshInstance3D.new()
		var wall_box := BoxMesh.new()
		wall_box.size = Vector3(20.0, 6.0, 0.3)
		wall.mesh = wall_box
		wall.surface_override_material(0, wall_mat)
		match i:
			0:
				wall.position = Vector3(0, 3.0, -10.0)
			1:
				wall.position = Vector3(0, 3.0, 10.0)
			2:
				wall.position = Vector3(-10.0, 3.0, 0)
				wall.rotation_degrees.y = 90.0
			3:
				wall.position = Vector3(10.0, 3.0, 0)
				wall.rotation_degrees.y = 90.0
		add_child(wall)

func _setup_lighting() -> void:
	var ambient := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.06)
	env.ambient_light_color = Color(0.15, 0.12, 0.2)
	env.ambient_light_energy = 0.4
	env.glow_enabled = true
	env.glow_intensity = 0.4
	ambient.environment = env
	add_child(ambient)

	var ceiling_light := SpotLight3D.new()
	ceiling_light.light_color = Color(0.95, 0.9, 0.8)
	ceiling_light.light_energy = 8.0
	ceiling_light.spot_range = 8.0
	ceiling_light.spot_angle = 35.0
	ceiling_light.position = Vector3(0, 5.5, 0)
	ceiling_light.rotation_degrees.x = -90.0
	add_child(ceiling_light)

func _setup_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "MainCamera"
	cam.fov = 65.0
	cam.position = Vector3(0, 5.0, 7.0)
	cam.rotation_degrees.x = -28.0
	add_child(cam)
	cam.make_current()

func _reveal_camera() -> void:
	var cam: Camera3D = get_node("MainCamera")
	cam.position = Vector3(0, 9.0, 10.0)
	cam.rotation_degrees.x = -45.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(cam, "position", Vector3(0, 5.0, 7.0), 2.0)
	tween.parallel().tween_property(cam, "rotation_degrees:x", -28.0, 2.0)
	tween.tween_callback(SceneTransition.fade_in)

func _add_hud() -> void:
	var hud_scene := load(HUD_SCENE)
	_hud = hud_scene.instantiate()
	add_child(_hud)

func _connect_signals() -> void:
	NakamaManager.message_received.connect(_on_message_received)
	GameState.player_eliminated.connect(_on_player_eliminated)

func _on_message_received(op_code: int, data: Dictionary) -> void:
	if op_code == 6:
		_spawn_seat_for_player(data.get("userId", ""), data.get("username", "?"), data.get("lives", 10))
	if op_code == 9:
		for pdata in data.get("players", []):
			_spawn_seat_for_player(pdata.get("userId", ""), pdata.get("username", "?"), pdata.get("lives", 10))

func _spawn_seat_for_player(player_id: String, username: String, lives: int) -> void:
	if _player_seats.has(player_id):
		return
	var seat_scene := load(PLAYER_SEAT_SCENE)
	var seat: Node3D = seat_scene.instantiate()
	seat.setup(player_id, username, lives)
	var seat_index := _player_seats.size()
	var total_seats := maxi(GameState.max_players, 2)
	var angle := (TAU / total_seats) * seat_index
	seat.position = Vector3(sin(angle) * SEAT_RADIUS, 0.0, cos(angle) * SEAT_RADIUS)
	seat.rotation.y = -angle
	add_child(seat)
	_player_seats[player_id] = seat

func _on_player_eliminated(player_id: String) -> void:
	if _player_seats.has(player_id):
		var seat: Node3D = _player_seats[player_id]
		var tween := create_tween()
		tween.tween_property(seat, "modulate", Color(0.3, 0.3, 0.3), 0.5)
