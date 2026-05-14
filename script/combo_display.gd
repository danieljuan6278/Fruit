extends Label
class_name ComboDisplay

# Combo feedback visual

func _ready():
	# Setup initial state
	modulate.a = 0  # Start transparent
	text = "COMBO!"
	add_theme_font_size_override("font_size", 60)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func show_combo_at(position: Vector2, combo_count: int = 3):
	"""Show combo notification at given position"""
	self.global_position = position - size / 2
	text = "Combo"
	
	# Animation: fade in, scale up, then fade out
	var tween = create_tween()
	
	# Step 1: Fade in and scale up (parallel)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	
	# Step 2: Wait
	tween.set_parallel(false)
	tween.tween_interval(0.5)
	
	# Step 3: Fade out and scale down (parallel)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_BACK)
	
	# Step 4: Remove
	tween.set_parallel(false)
	tween.tween_callback(self.queue_free)
