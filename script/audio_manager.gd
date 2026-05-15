extends Node

var success_snd = preload("res://assets/sounds/success.wav")
var failed_snd = preload("res://assets/sounds/failed.wav")
var menu_snd = preload("res://assets/sounds/menu.wav")
var main_play_snd = preload("res://assets/sounds/Kingdom at the Ready.wav")
var buttons_snd = preload("res://assets/sounds/buttons.wav")
var combo_snd = preload("res://assets/sounds/combo.wav")
var game_over_snd = preload(	"res://assets/sounds/game_over.wav")

var bgm_player: AudioStreamPlayer
var sfx_players: Array = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.bus = "Master"
	
	for i in range(8):
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)

func play_main_bgm():
	if bgm_player.stream != main_play_snd:
		bgm_player.stream = main_play_snd
		bgm_player.play()
	elif not bgm_player.playing:
		bgm_player.play()

func play_sfx(stream: AudioStream):
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	if sfx_players.size() > 0:
		sfx_players[0].stream = stream
		sfx_players[0].play()

func play_success():
	play_sfx(success_snd)

func play_failed():
	play_sfx(failed_snd)

func play_buttons():
	play_sfx(buttons_snd)

func play_combo():
	play_sfx(combo_snd)

func play_game_over():
	play_sfx(game_over_snd)

func play_menu_music():
	if bgm_player.stream != menu_snd:
		bgm_player.stream = menu_snd
		bgm_player.play()
	elif not bgm_player.playing:
		bgm_player.play()

func stop_music():
	bgm_player.stop()

func set_master_volume(volume: float):
	"""Set master volume (0.0 to 1.0)"""
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))
