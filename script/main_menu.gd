extends Control

func _ready():
	AudioManager.play_menu_music()
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$VBoxContainer/SettingButton.pressed.connect(_on_setting_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	AudioManager.play_buttons()
	get_tree().change_scene_to_file("res://scene/main_scene.tscn")

func _on_setting_pressed():
	AudioManager.play_buttons()
	print("Settings not implemented yet")

func _on_quit_pressed():
	AudioManager.play_buttons()
	get_tree().quit()
