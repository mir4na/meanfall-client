extends Control

const OP_CHAT_MESSAGE := 5
const MAX_MESSAGES := 100

@onready var scroll: ScrollContainer = $VBox/ScrollContainer
@onready var messages_container: VBoxContainer = $VBox/ScrollContainer/MessagesContainer
@onready var input_field: LineEdit = $VBox/InputRow/InputField
@onready var send_button: Button = $VBox/InputRow/SendButton

func _ready() -> void:
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	NakamaManager.message_received.connect(_on_message)

func _on_send_pressed() -> void:
	_send_message()

func _on_text_submitted(_text: String) -> void:
	_send_message()

func _send_message() -> void:
	var msg := input_field.text.strip_edges()
	if msg.is_empty() or msg.length() > 200:
		return
	NakamaManager.send_message(OP_CHAT_MESSAGE, {"message": msg})
	input_field.text = ""

func _on_message(op_code: int, data: Dictionary) -> void:
	if op_code != OP_CHAT_MESSAGE:
		return
	var username: String = data.get("username", "Unknown")
	var message: String = data.get("message", "")
	_append_message(username, message)

func _append_message(username: String, message: String) -> void:
	if messages_container.get_child_count() >= MAX_MESSAGES:
		messages_container.get_child(0).queue_free()
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.text = "[b]" + username.xml_escape() + ":[/b] " + message.xml_escape()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	messages_container.add_child(label)
	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
