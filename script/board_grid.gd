extends Node2D
class_name BoardGrid

@export var line_color: Color = Color(0.0, 0.0, 0.0, 0.65)
@export_range(1.0, 12.0, 0.5) var line_width: float = 5.0

func build(width: int, height: int, x_start: int, y_start: int, offset: int):
	for child in get_children():
		child.queue_free()
	
	var left = x_start - (offset * 0.5)
	var right = x_start + ((width - 1) * offset) + (offset * 0.5)
	var top = y_start - ((height - 1) * offset) - (offset * 0.5)
	var bottom = y_start + (offset * 0.5)
	
	for i in range(1, width):
		var x = left + (i * offset)
		_add_line(Vector2(x, top), Vector2(x, bottom))
	
	for j in range(1, height):
		var y = bottom - (j * offset)
		_add_line(Vector2(left, y), Vector2(right, y))

func _add_line(start_point: Vector2, end_point: Vector2):
	var line = Line2D.new()
	line.width = line_width
	line.default_color = line_color
	line.antialiased = true
	line.points = PackedVector2Array([start_point, end_point])
	add_child(line)
