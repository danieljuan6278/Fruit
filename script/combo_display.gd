extends Control
class_name ComboDisplay

var combo_font: Font
var combo_color: Color = Color(1.0, 0.86, 0.25)
var multiplier_color: Color = Color(1.0, 0.28, 0.16)
var combo_font_size: int = 64
var multiplier_font_size: int = 52
var start_scale: float = 0.25
var peak_scale: float = 1.35

var label_container: VBoxContainer
var combo_label: Label
var multiplier_label: Label

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	pivot_offset = Vector2.ZERO
	scale = Vector2(start_scale, start_scale)
	_build_labels()

func apply_preset(font: Font, combo_text_color: Color, multiplier_text_color: Color, main_size: int, multiplier_size: int, small_scale: float, explosion_scale: float):
	combo_font = font
	combo_color = combo_text_color
	multiplier_color = multiplier_text_color
	combo_font_size = main_size
	multiplier_font_size = multiplier_size
	start_scale = small_scale
	peak_scale = explosion_scale

func show_combo_at(world_position: Vector2, combo_count: int = 3):
	if combo_label == null or multiplier_label == null:
		_build_labels()
	
	combo_label.text = "Combo"
	multiplier_label.text = "%dx" % combo_count
	_update_label_style()
	await get_tree().process_frame
	_update_layout_size()
	
	pivot_offset = size * 0.5
	global_position = world_position - pivot_offset
	scale = Vector2(start_scale, start_scale)
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.08)
	tween.tween_property(self, "scale", Vector2(peak_scale, peak_scale), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_interval(0.18)
	
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - 24.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_interval(0.18)
	
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.tween_property(self, "scale", Vector2(0.82, 0.82), 0.22).set_trans(Tween.TRANS_SINE)
	
	tween.set_parallel(false)
	tween.tween_callback(self.queue_free)

func _build_labels():
	if combo_label != null:
		return
	
	label_container = VBoxContainer.new()
	label_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(label_container)
	
	combo_label = Label.new()
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_container.add_child(combo_label)
	
	multiplier_label = Label.new()
	multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	multiplier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_container.add_child(multiplier_label)
	
	_update_label_style()
	_update_layout_size()

func _update_label_style():
	for label in [combo_label, multiplier_label]:
		if label == null:
			continue
		if combo_font:
			label.add_theme_font_override("font", combo_font)
		label.add_theme_color_override("font_outline_color", Color(0.16, 0.07, 0.02))
		label.add_theme_constant_override("outline_size", 8)
	
	if combo_label:
		combo_label.add_theme_color_override("font_color", combo_color)
		combo_label.add_theme_font_size_override("font_size", combo_font_size)
	if multiplier_label:
		multiplier_label.add_theme_color_override("font_color", multiplier_color)
		multiplier_label.add_theme_font_size_override("font_size", multiplier_font_size)

func _update_layout_size():
	if label_container == null:
		return
	
	label_container.reset_size()
	label_container.size = label_container.get_combined_minimum_size()
	size = label_container.size
