extends Node

const BUS_MASTER := "Master"
const BUS_BGM := "BGM"
const BUS_SFX := "SFX"

const FADE_DURATION := 0.5

var _bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_size := 8

func _ready() -> void:
	_setup_audio_buses()
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_BGM
	_bgm_player.volume_db = -6.0
	add_child(_bgm_player)
	for i in _sfx_pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)

func _setup_audio_buses() -> void:
	if AudioServer.get_bus_index(BUS_BGM) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_BGM)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, BUS_MASTER)
	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_SFX)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, BUS_MASTER)

func play_bgm(stream: AudioStream, fade_in: bool = true) -> void:
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	if fade_in and _bgm_player.playing:
		var tween := create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, FADE_DURATION)
		await tween.finished
	_bgm_player.stream = stream
	_bgm_player.play()
	if fade_in:
		_bgm_player.volume_db = -80.0
		var tween := create_tween()
		tween.tween_property(_bgm_player, "volume_db", -6.0, FADE_DURATION)

func stop_bgm(fade_out: bool = true) -> void:
	if fade_out:
		var tween := create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, FADE_DURATION)
		await tween.finished
	_bgm_player.stop()

func play_sfx(stream: AudioStream) -> void:
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.play()
			return

func set_bgm_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_BGM), linear_to_db(linear))

func set_sfx_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), linear_to_db(linear))

func set_master_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), linear_to_db(linear))
