extends Control

const C_BG_TOP     := Color(0.04, 0.03, 0.10, 1.0)
const C_BG_BOT     := Color(0.08, 0.05, 0.20, 1.0)
const C_PANEL      := Color(0.10, 0.08, 0.22, 0.92)
const C_PANEL_EDGE := Color(0.35, 0.20, 0.80, 0.50)
const C_ACCENT     := Color(0.45, 0.20, 1.00, 1.0)
const C_ACCENT2    := Color(0.15, 0.55, 1.00, 1.0)
const C_WHITE      := Color(1.0,  1.0,  1.0,  1.0)
const C_MUTED      := Color(0.55, 0.55, 0.72, 1.0)
const C_RED        := Color(1.00, 0.25, 0.25, 1.0)
const C_GOLD       := Color(1.00, 0.82, 0.15, 1.0)

var _username_label: Label
var _points_label: Label

func _ready() -> void:
	_build_ui()
	_animate_in()
	NakamaManager.session_connected.connect(_on_session_connected)
	if GameState.session == null:
		_show_login_overlay()
	else:
		_refresh_profile()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG_TOP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var bg_bot := ColorRect.new()
	bg_bot.set_anchor_and_offset(SIDE_LEFT, 0.0, 0)
	bg_bot.set_anchor_and_offset(SIDE_TOP, 0.5, 0)
	bg_bot.set_anchor_and_offset(SIDE_RIGHT, 1.0, 0)
	bg_bot.set_anchor_and_offset(SIDE_BOTTOM, 1.0, 0)
	bg_bot.color = C_BG_BOT
	bg_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_bot)

	for d: Array in [
		[0.12, 0.38, 280.0, Color(0.50, 0.10, 0.90, 0.16)],
		[0.88, 0.55, 220.0, Color(0.10, 0.45, 0.95, 0.14)],
		[0.50, 0.08, 160.0, Color(0.40, 0.10, 0.80, 0.11)],
	]:
		var orb := ColorRect.new()
		orb.color = d[3]
		var r := d[2] as float
		orb.set_anchor_and_offset(SIDE_LEFT,   d[0] as float, -r)
		orb.set_anchor_and_offset(SIDE_TOP,    d[1] as float, -r)
		orb.set_anchor_and_offset(SIDE_RIGHT,  d[0] as float,  r)
		orb.set_anchor_and_offset(SIDE_BOTTOM, d[1] as float,  r)
		orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(orb)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	root.add_child(_build_topbar())

	var center := _build_center()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)

	root.add_child(_build_bottom_dock())

func _build_topbar() -> Control:
	var bar := MarginContainer.new()
	bar.add_theme_constant_override("margin_left",   20)
	bar.add_theme_constant_override("margin_right",  20)
	bar.add_theme_constant_override("margin_top",    16)
	bar.add_theme_constant_override("margin_bottom", 10)
	bar.custom_minimum_size.y = 76

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	bar.add_child(hb)

	var card := _mk_panel(C_PANEL, C_PANEL_EDGE, 12)
	card.custom_minimum_size = Vector2(270, 52)

	var mg := _mk_mg(12, 8)
	card.add_child(mg)

	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 12)
	mg.add_child(ch)

	var av := ColorRect.new()
	av.color = C_ACCENT
	av.custom_minimum_size = Vector2(40, 40)
	var avl := _mk_label("P", 18, C_WHITE)
	avl.set_anchors_preset(Control.PRESET_FULL_RECT)
	avl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(avl)
	ch.add_child(av)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_username_label = _mk_label("...", 14, C_WHITE)
	_points_label   = _mk_label("0 pts • Bronze", 11, C_MUTED)
	vb.add_child(_username_label)
	vb.add_child(_points_label)
	ch.add_child(vb)

	var cb := Button.new()
	cb.flat = true
	cb.set_anchors_preset(Control.PRESET_FULL_RECT)
	cb.pressed.connect(_on_profile_pressed)
	card.add_child(cb)
	hb.add_child(card)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)

	var sb := _mk_icon_btn("⚙")
	sb.pressed.connect(_on_settings_pressed)
	hb.add_child(sb)

	return bar

func _build_center() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var logo_vb := VBoxContainer.new()
	logo_vb.add_theme_constant_override("separation", 8)
	logo_vb.set_anchor_and_offset(SIDE_LEFT,   0.0,  0)
	logo_vb.set_anchor_and_offset(SIDE_TOP,    0.0,  0)
	logo_vb.set_anchor_and_offset(SIDE_RIGHT,  1.0,  0)
	logo_vb.set_anchor_and_offset(SIDE_BOTTOM, 0.6,  0)
	logo_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(logo_vb)

	var title := _mk_label("MEANFALL", 78, C_WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", C_ACCENT)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	logo_vb.add_child(title)

	var line := ColorRect.new()
	line.color = C_ACCENT
	line.custom_minimum_size = Vector2(80, 2)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo_vb.add_child(line)

	var sub := _mk_label("Guess the average. Stay alive.", 16, C_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_vb.add_child(sub)

	var play := _mk_play_btn()
	play.set_anchor_and_offset(SIDE_LEFT,   0.5, -210)
	play.set_anchor_and_offset(SIDE_TOP,    1.0,  -90)
	play.set_anchor_and_offset(SIDE_RIGHT,  0.5,  210)
	play.set_anchor_and_offset(SIDE_BOTTOM, 1.0,  -10)
	c.add_child(play)

	return c

func _mk_play_btn() -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(420, 76)

	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = C_ACCENT.lerp(C_ACCENT2, 0.3)
	sb_n.border_color = C_ACCENT
	sb_n.set_border_width_all(2)
	sb_n.set_corner_radius_all(14)
	sb_n.shadow_color  = C_ACCENT.darkened(0.35)
	sb_n.shadow_size   = 14
	sb_n.shadow_offset = Vector2(0, 4)

	var sb_h := sb_n.duplicate() as StyleBoxFlat
	sb_h.bg_color = C_ACCENT.lightened(0.18)
	sb_h.border_color = C_ACCENT.lightened(0.3)
	sb_h.shadow_size  = 22

	b.add_theme_stylebox_override("normal",  sb_n)
	b.add_theme_stylebox_override("hover",   sb_h)
	b.add_theme_stylebox_override("pressed", sb_n)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var l1 := _mk_label("⚡  QUICK MATCH", 26, C_WHITE)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l2 := _mk_label("Ranked  •  Up to 10 players", 12, Color(1, 1, 1, 0.6))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(l1)
	vb.add_child(l2)
	b.add_child(vb)
	b.pressed.connect(_on_play_pressed)
	return b

func _build_bottom_dock() -> Control:
	var dock_panel := _mk_panel(Color(0.05, 0.04, 0.13, 0.97), C_PANEL_EDGE, 0)
	dock_panel.custom_minimum_size.y = 90

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 0)
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	dock_panel.add_child(hb)

	var items: Array = [
		["⚑", "CUSTOM ROOM", C_ACCENT2, _on_custom_room_pressed],
		["◉", "PROFILE",     C_MUTED,   _on_profile_pressed],
		["▲", "LEADERBOARD", C_GOLD,    _on_leaderboard_pressed],
		["✕", "QUIT",        C_RED,     _on_quit_pressed],
	]

	for i in items.size():
		var item: Array = items[i]
		hb.add_child(_mk_dock_btn(item[0], item[1], item[2], item[3]))
		if i < items.size() - 1:
			var div := ColorRect.new()
			div.color = C_PANEL_EDGE
			div.custom_minimum_size = Vector2(1, 44)
			div.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(div)

	return dock_panel

func _mk_dock_btn(icon: String, label: String, col: Color, callback: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 88)

	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color.TRANSPARENT

	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = col.darkened(0.72)
	sb_h.border_color = col
	sb_h.set_border_width_all(1)

	b.add_theme_stylebox_override("normal",  sb_n)
	b.add_theme_stylebox_override("hover",   sb_h)
	b.add_theme_stylebox_override("pressed", sb_n)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var il := _mk_label(icon, 24, col)
	il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	il.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tl := _mk_label(label, 11, C_MUTED)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	vb.add_child(il)
	vb.add_child(tl)
	b.add_child(vb)
	b.pressed.connect(callback)
	return b

func _mk_panel(bg: Color, border: Color, radius: int) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.shadow_color  = Color(0, 0, 0, 0.4)
	sb.shadow_size   = 8
	sb.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", sb)
	return p

func _mk_mg(h: int, v: int) -> MarginContainer:
	var mg := MarginContainer.new()
	mg.add_theme_constant_override("margin_left",   h)
	mg.add_theme_constant_override("margin_right",  h)
	mg.add_theme_constant_override("margin_top",    v)
	mg.add_theme_constant_override("margin_bottom", v)
	return mg

func _mk_label(txt: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _mk_icon_btn(icon: String) -> Button:
	var b := Button.new()
	b.text = icon
	b.custom_minimum_size = Vector2(46, 46)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", C_MUTED)
	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = C_PANEL
	sb_n.border_color = C_PANEL_EDGE
	sb_n.set_border_width_all(1)
	sb_n.set_corner_radius_all(10)
	var sb_h := sb_n.duplicate() as StyleBoxFlat
	sb_h.bg_color = C_ACCENT.darkened(0.5)
	sb_h.border_color = C_ACCENT
	b.add_theme_stylebox_override("normal", sb_n)
	b.add_theme_stylebox_override("hover",  sb_h)
	b.add_theme_stylebox_override("pressed", sb_n)
	return b

func _animate_in() -> void:
	modulate.a = 0.0
	position.y = 20.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", 0.0, 0.4).set_ease(Tween.EASE_OUT)

func _refresh_profile() -> void:
	if _username_label:
		_username_label.text = GameState.local_player_username
	var stats = await NakamaManager.get_player_stats()
	if not stats.has("error") and _points_label:
		_points_label.text = str(stats.get("totalPoints", 0)) + " pts  •  " + stats.get("league", "Bronze")

func _show_login_overlay() -> void:
	var overlay = load("res://scenes/ui/login_overlay.tscn").instantiate()
	add_child(overlay)

func _on_play_pressed() -> void:
	GameState.is_ranked = true
	SceneTransition.fade_to_scene("res://scenes/ui/lobby/lobby.tscn")

func _on_custom_room_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/custom_room/custom_room.tscn")

func _on_profile_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/profile/profile.tscn")

func _on_leaderboard_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/leaderboard/leaderboard.tscn")

func _on_settings_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/settings/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_session_connected(_session) -> void:
	_refresh_profile()
