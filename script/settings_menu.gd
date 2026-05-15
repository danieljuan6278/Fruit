extends CanvasLayer

@onready var volume_slider = $Control/VBoxContainer/VolumeSlider
@onready var back_button = $Control/VBoxContainer/BackButton

func _ready():
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)

func _on_volume_changed(value: float):
	AudioManager.set_master_volume(value)

func _on_back_pressed():
	AudioManager.play_buttons()
	queue_free()
