extends Node2D

@export var grid_tile_scene: PackedScene
@export var piece_scene: PackedScene
@export var ui_manager: UIManager

@export var width: int = 8
@export var height: int = 10
@export var x_start: int = 65
@export var y_start: int = 1000
@export var offset: int = 80

var game_state: GameState
var fruits = ["black", "red", "green", "yellow", "orange"]
var all_pieces = []
var combo_positions: Array = []  # Track positions of destroyed pieces for combo display

var first_piece = null
var is_swapping = false 
var touch_start_pos = Vector2.ZERO
var swipe_threshold = 50 

func _ready() -> void:
	# Initialize game state
	game_state = GameState.new()
	add_child(game_state)
	
	# Connect game state signals
	game_state.phase_changed.connect(_on_phase_advance)
	game_state.score_updated.connect(_on_score_updated)
	
	# Set UI manager's game state reference
	if ui_manager:
		ui_manager.set_game_state(game_state)
	
	setup_pause_menu()
	
	all_pieces = make_2d_array()
	spawn_board()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func spawn_board():
	if piece_scene == null or grid_tile_scene == null: 
		return
	for i in width:
		for j in height:
			# Example: nudge every piece 5 pixels right and 5 pixels up
			var nudge_x = -5
			var nudge_y = -5 

			var pos = Vector2(x_start + (i * offset) + nudge_x, y_start - (j * offset) + nudge_y)
			var tile = grid_tile_scene.instantiate()
			add_child(tile)
			tile.position = pos
			tile.z_index = -1 
			spawn_safe_piece(i, j, pos)

func spawn_safe_piece(i, j, pos):
	var piece = piece_scene.instantiate()
	add_child(piece)
	var random_fruit = fruits[randi() % fruits.size()]
	var attempts = 0
	while is_initial_match(i, j, random_fruit) and attempts < 10:
		random_fruit = fruits[randi() % fruits.size()]
		attempts += 1
	if piece.has_method("set_fruit"):
		piece.set_fruit(random_fruit)
	piece.position = pos
	all_pieces[i][j] = piece

func is_initial_match(i, j, type):
	if i >= 2:
		if all_pieces[i-1][j] != null and all_pieces[i-2][j] != null:
			if all_pieces[i-1][j].fruit_type == type and all_pieces[i-2][j].fruit_type == type:
				return true
	if j >= 2:
		if all_pieces[i][j-1] != null and all_pieces[i][j-2] != null:
			if all_pieces[i][j-1].fruit_type == type and all_pieces[i][j-2].fruit_type == type:
				return true
	return false

func _input(event):
	if is_swapping: return
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
			first_piece = get_piece_from_screen_pos(touch_start_pos)
		elif not event.pressed and first_piece != null:
			var swipe_vector = event.position - touch_start_pos
			if swipe_vector.length() > swipe_threshold:
				calculate_swipe_direction(swipe_vector)
			first_piece = null 

func get_piece_from_screen_pos(pos):
	for i in width:
		for j in height:
			var p = all_pieces[i][j]
			if p != null:
				if pos.distance_to(p.position) < int(offset / 2):
					return p
	return null

func calculate_swipe_direction(swipe):
	var grid_pos = get_grid_pos(first_piece.position)
	var target_x = grid_pos.x
	var target_y = grid_pos.y
	if abs(swipe.x) > abs(swipe.y):
		target_x += 1 if swipe.x > 0 else -1 
	else:
		target_y += -1 if swipe.y > 0 else 1 
	if target_x >= 0 and target_x < width and target_y >= 0 and target_y < height:
		var second_piece = all_pieces[target_x][target_y]
		if second_piece != null:
			swap_pieces(first_piece, second_piece)

func get_grid_pos(pos: Vector2):
	var x = round((pos.x - x_start) / offset)
	var y = round((y_start - pos.y) / offset)
	return Vector2(x, y)

func swap_pieces(p1, p2):
	is_swapping = true
	var p1_pos = p1.position
	var p2_pos = p2.position
	var g1 = get_grid_pos(p1_pos)
	var g2 = get_grid_pos(p2_pos)
	all_pieces[g1.x][g1.y] = p2
	all_pieces[g2.x][g2.y] = p1
	var tween = create_tween().set_parallel(true)
	tween.tween_property(p1, "position", p2_pos, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(p2, "position", p1_pos, 0.2).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	game_state.match_count = 0  # Reset for this turn
	if find_matches():
		if game_state.use_move():  # Deduct move only if successful match
			pass
	else:
		# Swap back if no matches
		all_pieces[g1.x][g1.y] = p1
		all_pieces[g2.x][g2.y] = p2
		var tween_back = create_tween().set_parallel(true)
		tween_back.tween_property(p1, "position", p1_pos, 0.2).set_trans(Tween.TRANS_SINE)
		tween_back.tween_property(p2, "position", p2_pos, 0.2).set_trans(Tween.TRANS_SINE)
		await tween_back.finished
	is_swapping = false 

func find_matches() -> bool:
	var found_match = false
	for i in width:
		for j in height:
			var p = all_pieces[i][j]
			if p != null:
				var type = p.fruit_type
				if i > 0 and i < width - 1:
					if all_pieces[i-1][j] != null and all_pieces[i+1][j] != null:
						if all_pieces[i-1][j].fruit_type == type and all_pieces[i+1][j].fruit_type == type:
							all_pieces[i-1][j].is_matched = true
							p.is_matched = true
							all_pieces[i+1][j].is_matched = true
							found_match = true
				if j > 0 and j < height - 1:
					if all_pieces[i][j-1] != null and all_pieces[i][j+1] != null:
						if all_pieces[i][j-1].fruit_type == type and all_pieces[i][j+1].fruit_type == type:
							all_pieces[i][j-1].is_matched = true
							p.is_matched = true
							all_pieces[i][j+1].is_matched = true
							found_match = true
	if found_match:
		destroy_matches()
	return found_match

func destroy_matches():
	game_state.increment_matches()
	var destroyed_count = 0
	var avg_pos = Vector2.ZERO
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].is_matched:
				avg_pos += all_pieces[i][j].global_position
				destroyed_count += 1
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	
	if destroyed_count > 0:
		avg_pos /= destroyed_count
		if game_state.match_count >= 3:
			var combo_display = preload("res://script/combo_display.gd").new()
			combo_display.text = "Combo" # Just "Combo" per user instructions
			add_child(combo_display)
			combo_display.show_combo_at(avg_pos, game_state.match_count)
			
		calculate_score(destroyed_count)
	
	await get_tree().create_timer(0.2).timeout
	collapse_columns()

func calculate_score(count: int):
	var base_points = count * 10
	var bonus = 0
	if count == 4:
		bonus = 20
	elif count == 5:
		bonus = 40
	elif count >= 6:
		bonus = 80
	
	var total_points = base_points + bonus
	if game_state.add_score(total_points):
		# Phase target reached, advance when animations finish
		await get_tree().create_timer(0.5).timeout
		game_state.advance_phase()

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						var new_pos = Vector2(x_start + (i * offset), y_start - (j * offset))
						create_tween().tween_property(all_pieces[i][j], "position", new_pos, 0.3).set_trans(Tween.TRANS_BOUNCE)
						break
	await get_tree().create_timer(0.3).timeout
	refill_columns()

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				var piece = piece_scene.instantiate()
				add_child(piece)
				piece.set_fruit(fruits[randi() % fruits.size()])
				var end_pos = Vector2(x_start + (i * offset), y_start - (j * offset))
				piece.position = end_pos + Vector2(0, -offset * 2) 
				all_pieces[i][j] = piece
				create_tween().tween_property(piece, "position", end_pos, 0.3).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.4).timeout
	if not find_matches():
		is_swapping = false
		# Check for combo bonus in S+ phase
		game_state.check_combo_bonus()

func _on_phase_advance(phase: String, moves: int):
	"""Called when phase changes"""
	print("Advanced to phase: %s with %d moves" % [phase, moves])

func _on_score_updated(total: int, phase: int):
	"""Called when score updates"""
	print("Score updated - Total: %d, Phase: %d" % [total, phase])	

# --- PAUSE MENU LOGIC ---
var pause_panel: ColorRect

func setup_pause_menu():
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # Put it on top
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	
	# Pause button on HUD
	var pause_btn = Button.new()
	pause_btn.text = "||" # Pause icon or text
	pause_btn.add_theme_font_size_override("font_size", 40)
	
	# For mobile, it's nice to have it in the top corner. Since width is 8 * 80 = 640 approx, x=600 is good
	pause_btn.position = Vector2(600, 20)
	pause_btn.size = Vector2(80, 80)
	pause_btn.pressed.connect(show_pause_menu)
	canvas.add_child(pause_btn)
	
	# Pause panel
	pause_panel = ColorRect.new()
	pause_panel.color = Color(0, 0, 0, 0.7)
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Size manually since anchors might be tricky if parent isn't a Control
	var viewport_size = get_viewport_rect().size
	pause_panel.size = viewport_size
	if viewport_size == Vector2.ZERO:
		pause_panel.size = Vector2(720, 1280) # Fallback size
		
	pause_panel.hide()
	canvas.add_child(pause_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 20)
	vbox.position = Vector2(pause_panel.size.x / 2 - 150, pause_panel.size.y / 2 - 150)
	vbox.size = Vector2(300, 300)
	pause_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var resume_btn = Button.new()
	resume_btn.text = "Play"
	resume_btn.custom_minimum_size = Vector2(300, 80)
	resume_btn.add_theme_font_size_override("font_size", 40)
	resume_btn.pressed.connect(resume_game)
	vbox.add_child(resume_btn)
	
	var restart_btn = Button.new()
	restart_btn.text = "Restart"
	restart_btn.custom_minimum_size = Vector2(300, 80)
	restart_btn.add_theme_font_size_override("font_size", 40)
	restart_btn.pressed.connect(restart_game)
	vbox.add_child(restart_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(300, 80)
	quit_btn.add_theme_font_size_override("font_size", 40)
	quit_btn.pressed.connect(quit_to_main)
	vbox.add_child(quit_btn)

func show_pause_menu():
	get_tree().paused = true
	var viewport_size = get_viewport_rect().size
	if viewport_size != Vector2.ZERO:
		pause_panel.size = viewport_size
		var vbox = pause_panel.get_child(0)
		vbox.position = Vector2(pause_panel.size.x / 2 - vbox.size.x / 2, pause_panel.size.y / 2 - vbox.size.y / 2)
	pause_panel.show()

func resume_game():
	get_tree().paused = false
	pause_panel.hide()

func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit_to_main():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
