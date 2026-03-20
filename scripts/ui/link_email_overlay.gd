extends CanvasLayer

signal link_succeeded

@onready var email_step: VBoxContainer  = $Center/Panel/Margin/VBox/EmailStep
@onready var otp_step: VBoxContainer    = $Center/Panel/Margin/VBox/OtpStep
@onready var email_input: LineEdit      = $Center/Panel/Margin/VBox/EmailStep/EmailInput
@onready var otp_input: LineEdit        = $Center/Panel/Margin/VBox/OtpStep/OtpInput
@onready var password_input: LineEdit   = $Center/Panel/Margin/VBox/OtpStep/PasswordInput
@onready var status_label: Label        = $Center/Panel/Margin/VBox/StatusLabel
@onready var send_otp_btn: Button       = $Center/Panel/Margin/VBox/EmailStep/SendOtpButton
@onready var verify_btn: Button         = $Center/Panel/Margin/VBox/OtpStep/VerifyButton

var _verified_email: String = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func _on_send_otp_pressed() -> void:
	var email := email_input.text.strip_edges()
	if email.is_empty() or not "@" in email or not "." in email:
		_set_status("Please enter a valid email address.", true)
		return
	send_otp_btn.disabled = true
	_set_status("Sending verification code…", false)
	var result = await NakamaManager.rpc_call("send_otp", {"email": email})
	if result.has("error"):
		send_otp_btn.disabled = false
		_set_status(result.get("error", "Failed to send OTP."), true)
		return
	_verified_email = email
	email_step.visible = false
	otp_step.visible = true
	_set_status("Code sent! Check your inbox.", false)

func _on_verify_pressed() -> void:
	var otp := otp_input.text.strip_edges()
	var password := password_input.text
	if otp.length() != 6 or not otp.is_valid_int():
		_set_status("Enter the 6-digit code from your email.", true)
		return
	if password.length() < 8:
		_set_status("Password must be at least 8 characters.", true)
		return
	verify_btn.disabled = true
	_set_status("Verifying…", false)
	var otp_result = await NakamaManager.rpc_call("verify_otp", {"email": _verified_email, "otp": otp})
	if otp_result.has("error"):
		verify_btn.disabled = false
		_set_status(otp_result.get("error", "Invalid code."), true)
		return
	var ok: bool = await NakamaManager.link_email(_verified_email, password)
	if ok:
		GameState.account["email"] = _verified_email
		_set_status("Account linked successfully!", false)
		await get_tree().create_timer(1.5).timeout
		link_succeeded.emit()
		queue_free()
	else:
		verify_btn.disabled = false
		_set_status("Linking failed. Email may already be in use.", true)

func _on_cancel_pressed() -> void:
	queue_free()

func _on_otp_text_changed(new_text: String) -> void:
	var old_caret = otp_input.caret_column
	var filtered = ""
	for i in range(new_text.length()):
		var c = new_text[i]
		if c.is_valid_float() and not c in [".", ",", "+", "-"]:
			filtered += c
	
	if filtered.length() > 6:
		filtered = filtered.substr(0, 6)
		
	if new_text != filtered:
		otp_input.text = filtered
		otp_input.caret_column = clampi(old_caret - (new_text.length() - filtered.length()), 0, filtered.length())

func _set_status(text: String, is_error: bool) -> void:
	status_label.text = text
	status_label.modulate = Color(1, 0.35, 0.35) if is_error else Color(0.5, 1, 0.6)
