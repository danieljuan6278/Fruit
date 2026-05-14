extends Control

func _ready():
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$VBoxContainer/SettingButton.pressed.connect(_on_setting_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scene/game.tscn")

func _on_setting_pressed():
	print("Settings not implemented yet")

func _on_quit_pressed():
	get_tree().quit()
