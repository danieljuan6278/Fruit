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
	
	var buttons = [pause_btn, resume_btn, restart_btn, quit_btn]
	for btn in buttons:
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_normal.bind(btn))
		btn.button_down.connect(_on_btn_down.bind(btn))
		btn.button_up.connect(_on_btn_up.bind(btn))

func _on_btn_down(btn):
	_tween_modulate(btn, Color(0.7, 0.7, 0.7), 0.1)

func _on_btn_up(btn):
	if btn.is_hovered():
		_on_btn_hover(btn)
	else:
		_on_btn_normal(btn)

func _on_btn_hover(btn):
	_tween_modulate(btn, Color(1.2, 1.2, 1.2), 0.1)

func _on_btn_normal(btn):
	_tween_modulate(btn, Color(1, 1, 1), 0.2)

func _tween_modulate(btn, color, duration):
	var tween = create_tween()
	tween.tween_property(btn, "modulate", color, duration).set_trans(Tween.TRANS_SINE)


func _on_pause_pressed():
	AudioManager.play_buttons()
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
	AudioManager.play_buttons()
	get_tree().paused = false
	overlay.hide()

func _on_restart_pressed():
	AudioManager.play_buttons()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	AudioManager.play_buttons()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func show_game_over():
	show_menu("GAME OVER")
