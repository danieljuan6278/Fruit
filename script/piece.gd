extends Area2D

var fruit_type: String
var is_matched: bool = false

# Preload your 5 fruit images here
var fruit_textures = {
	"black": preload("res://assets/Fruits/Singles/02_Cherry_Black.png"),
	"red": preload("res://assets/Fruits/Singles/03_Cranberry.png"),
	"green": preload("res://assets/Fruits/Singles/04_Cucumber.png"),
	"yellow": preload("res://assets/Fruits/Singles/05_CustardApple.png"),
	"orange": preload("res://assets/Fruits/Singles/17_Orange.png"),
}

func _ready() -> void:
	# Ensure the piece can be clicked
	input_pickable = true
	self.scale = Vector2(2, 2)

func set_fruit(type: String):
	fruit_type = type
	if fruit_textures.has(type):
		$Sprite2D.texture = fruit_textures[type]

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Tell the Game script this piece was clicked
			if get_parent().has_method("piece_clicked"):
				get_parent().piece_clicked(self)

# --- Visual Feedback for Selection ---

func dim():
	# Dims the fruit when selected (50% transparency/darkness)
	modulate = Color(0.5, 0.5, 0.5, 1)

func brighten():
	# Returns the fruit to normal color
	modulate = Color(1, 1, 1, 1)
	
	# Add this to piece.gd so the Game knows which piece is at which screen position
func get_rect_rect():
	return Rect2(position - Vector2(64, 64), Vector2(128, 128)) 
	# Adjust 64/128 based on your offset/2
