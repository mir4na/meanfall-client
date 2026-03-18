extends Control

const C_PANEL      := Color(0.10, 0.08, 0.22, 0.95)
const C_PANEL_EDGE := Color(0.35, 0.20, 0.80, 0.50)
const C_ACCENT     := Color(0.45, 0.20, 1.00, 1.0)
const C_ACCENT2    := Color(0.15, 0.55, 1.00, 1.0)
const C_WHITE      := Color(1.0,  1.0,  1.0,  1.0)
const C_MUTED      := Color(0.55, 0.55, 0.72, 1.0)

@onready var main_panel: Control = %MainPanel
@onready var email_panel: Control = %EmailPanel
@onready var otp_panel: Control = %OtpPanel
@onready var register_panel: Control = %RegisterPanel

@onready var email_input: LineEdit = %EmailInput
@onready var otp_input: LineEdit = %OtpInput
@onready var password_input: LineEdit = %PasswordInput
@onready var username_input: LineEdit = %UsernameInput
@onready var error_label: Label = %ErrorLabel

var _current_email: String = ""
var _is_guest_mode: bool = false

func _ready() -> void:
	_apply_styles()
	_show_panel(main_panel)
	NakamaManager.session_connected.connect(_on_session_connected)
	NakamaManager.guest_created.connect(_on_guest_created)
	NakamaManager.session_failed.connect(_on_session_failed)
	
	if GameState.session != null:
		_goto_main_menu()

func _apply_styles() -> void:
	var inputs = [%EmailInput, %OtpInput, %UsernameInput, %PasswordInput]
	for inp in inputs:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.3)
		sb.border_color = C_PANEL_EDGE
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		
		var sb_f := sb.duplicate() as StyleBoxFlat
		sb_f.border_color = C_ACCENT2
		sb_f.bg_color = Color(0, 0, 0, 0.5)
		
		inp.add_theme_stylebox_override("normal", sb)
		inp.add_theme_stylebox_override("focus", sb_f)
		inp.add_theme_color_override("font_color", C_WHITE)
		inp.add_theme_color_override("font_placeholder_color", C_MUTED)

	var btns_primary = [%GuestBtn, %SendOtpBtn, %VerifyOtpBtn, %FinishBtn]
	for btn in btns_primary:
		var sb_n := StyleBoxFlat.new()
		sb_n.bg_color = C_ACCENT2.darkened(0.2)
		sb_n.border_color = C_ACCENT2
		sb_n.set_border_width_all(1)
		sb_n.set_corner_radius_all(8)
		
		var sb_h := sb_n.duplicate() as StyleBoxFlat
		sb_h.bg_color = C_ACCENT2.lightened(0.2)
		
		btn.add_theme_stylebox_override("normal", sb_n)
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_stylebox_override("pressed", sb_n)
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", C_WHITE)

	var btns_sec = [%EmailLoginBtn, %BackBtn1, %BackBtn2]
	for btn in btns_sec:
		var sb_n := StyleBoxFlat.new()
		sb_n.bg_color = Color(1, 1, 1, 0.05)
		sb_n.border_color = C_PANEL_EDGE
		sb_n.set_border_width_all(1)
		sb_n.set_corner_radius_all(8)
		
		var sb_h := sb_n.duplicate() as StyleBoxFlat
		sb_h.bg_color = Color(1, 1, 1, 0.1)
		sb_h.border_color = C_ACCENT
		
		btn.add_theme_stylebox_override("normal", sb_n)
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_stylebox_override("pressed", sb_n)
		btn.add_theme_font_size_override("font_size", 14)
		if btn == %EmailLoginBtn:
			btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))

func _show_panel(panel: Control) -> void:
	main_panel.visible = false
	email_panel.visible = false
	otp_panel.visible = false
	register_panel.visible = false
	panel.visible = true
	error_label.text = ""

func _on_guest_pressed() -> void:
	NakamaManager.authenticate_device(OS.get_unique_id())

func _on_email_login_pressed() -> void:
	_show_panel(email_panel)

func _is_valid_email(email: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$")
	return regex.search(email) != null

func _on_send_otp_pressed() -> void:
	_current_email = email_input.text.strip_edges()
	if _current_email.is_empty():
		error_label.text = "Email is required"
		return
		
	if not _is_valid_email(_current_email):
		error_label.text = "Please enter a valid email address"
		return
		
	var result = await NakamaManager.rpc_call("send_otp", {"email": _current_email})
	if result.has("error"):
		error_label.text = result.error
	else:
		_show_panel(otp_panel)

func _on_verify_otp_pressed() -> void:
	var otp = otp_input.text
	if otp.is_empty():
		error_label.text = "OTP is required"
		return
		
	var result = await NakamaManager.rpc_call("verify_otp", {"email": _current_email, "otp": otp})
	if result.has("error"):
		error_label.text = result.error
	else:
		_is_guest_mode = false
		%RegLabel.text = "Complete Profile"
		password_input.visible = true
		_show_panel(register_panel)

func _on_guest_created(_session) -> void:
	_is_guest_mode = true
	%RegLabel.text = "Choose Username"
	password_input.visible = false
	_show_panel(register_panel)

func _on_finish_auth_pressed() -> void:
	var password = password_input.text
	var username = username_input.text
	
	if _is_guest_mode:
		if username.is_empty():
			error_label.text = "Username is required"
			return
		var success = await NakamaManager.update_account(username)
		if success:
			_goto_main_menu()
	else:
		if password.length() < 8:
			error_label.text = "Password must be at least 8 characters"
			return
			
		if GameState.session:
			var success = await NakamaManager.link_email(_current_email, password)
			if success:
				_goto_main_menu()
		else:
			NakamaManager.authenticate_email(_current_email, password, username)

func _on_back_pressed() -> void:
	_show_panel(main_panel)

func _on_session_connected(_session) -> void:
	_goto_main_menu()

func _goto_main_menu() -> void:
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")

func _on_session_failed(message: String) -> void:
	error_label.text = message
