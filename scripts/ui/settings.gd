extends Control

const SETTINGS_KEY := "user_settings"

@onready var master_slider: HSlider = $Center/Panel/VBox/MasterSlider
@onready var bgm_slider: HSlider = $Center/Panel/VBox/BGMSlider
@onready var sfx_slider: HSlider = $Center/Panel/VBox/SFXSlider
@onready var logout_button: Button = $Center/Panel/VBox/LogoutButton
@onready var link_button: Button = $Center/Panel/VBox/LinkEmailButton
@onready var back_button: Button = $Center/Panel/VBox/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	link_button.pressed.connect(_on_link_pressed)
	master_slider.value_changed.connect(AudioManager.set_master_volume)
	bgm_slider.value_changed.connect(AudioManager.set_bgm_volume)
	sfx_slider.value_changed.connect(AudioManager.set_sfx_volume)
	_load_settings()
	_update_account_buttons()

func _update_account_buttons() -> void:
	if GameState.account.get("email", "") != "":
		link_button.visible = false

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	master_slider.value = config.get_value(SETTINGS_KEY, "master", 1.0)
	bgm_slider.value = config.get_value(SETTINGS_KEY, "bgm", 0.8)
	sfx_slider.value = config.get_value(SETTINGS_KEY, "sfx", 1.0)
	AudioManager.set_master_volume(master_slider.value)
	AudioManager.set_bgm_volume(bgm_slider.value)
	AudioManager.set_sfx_volume(sfx_slider.value)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_KEY, "master", master_slider.value)
	config.set_value(SETTINGS_KEY, "bgm", bgm_slider.value)
	config.set_value(SETTINGS_KEY, "sfx", sfx_slider.value)
	config.save("user://settings.cfg")

func _on_back_pressed() -> void:
	_save_settings()
	SceneTransition.fade_to_scene("res://scenes/ui/main_menu/main_menu.tscn")

func _on_logout_pressed() -> void:
	NakamaManager.logout()
	SceneTransition.fade_to_scene("res://scenes/ui/login_overlay.tscn")

func _on_link_pressed() -> void:
	var overlay = load("res://scenes/ui/login_overlay.tscn").instantiate()
	add_child(overlay)
