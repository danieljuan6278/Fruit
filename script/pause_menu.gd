extends CanvasLayer

@onready var overlay = $Overlay
@onready var title = $Overlay/VBoxContainer/Title
@onready var resume_btn = $Overlay/VBoxContainer/ResumeButton
@onready var restart_btn = $Overlay/VBoxContainer/RestartButton
@onready var quit_btn = $Overlay/VBoxContainer/QuitButton
@onready var pause_btn = $PauseButton

func _ready():
	pause_btn.pressed.connect(_on_pause_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_pause_pressed():
	show_menu("PAUSED")

func show_menu(menu_title: String):
	get_tree().paused = true
	title.text = menu_title
	overlay.show()
	if menu_title == "GAME OVER":
		resume_btn.hide()
		pause_btn.hide()
	else:
		resume_btn.show()

func _on_resume_pressed():
	get_tree().paused = false
	overlay.hide()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func show_game_over():
	show_menu("GAME OVER")
