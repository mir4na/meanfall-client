extends Control

@onready var main_panel: Control = $MainPanel
@onready var email_panel: Control = $EmailPanel
@onready var otp_panel: Control = $OtpPanel
@onready var register_panel: Control = $RegisterPanel

@onready var email_input: LineEdit = $EmailPanel/EmailInput
@onready var otp_input: LineEdit = $OtpPanel/OtpInput
@onready var password_input: LineEdit = $RegisterPanel/PasswordInput
@onready var username_input: LineEdit = $RegisterPanel/UsernameInput
@onready var error_label: Label = $ErrorLabel

var _current_email: String = ""

func _ready() -> void:
	_show_panel(main_panel)
	NakamaManager.session_connected.connect(_on_session_connected)
	NakamaManager.session_failed.connect(_on_session_failed)

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

func _on_send_otp_pressed() -> void:
	_current_email = email_input.text
	if _current_email.is_empty():
		error_label.text = "Email is required"
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
		_show_panel(register_panel)

func _on_finish_auth_pressed() -> void:
	var password = password_input.text
	var username = username_input.text
	
	if password.length() < 8:
		error_label.text = "Password must be at least 8 characters"
		return
		
	if GameState.session:
		var success = await NakamaManager.link_email(_current_email, password)
		if success:
			hide()
	else:
		NakamaManager.authenticate_email(_current_email, password, username)

func _on_back_pressed() -> void:
	_show_panel(main_panel)

func _on_session_connected(_session) -> void:
	hide()

func _on_session_failed(message: String) -> void:
	error_label.text = message
