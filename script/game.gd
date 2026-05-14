extends Node2D

@export var grid_tile_scene: PackedScene
@export var piece_scene: PackedScene
@export var score_label: Label 
@export var rank_label: Label
@export var moves_label: Label 

@export var width: int = 8
@export var height: int = 10
@export var x_start: int = 65
@export var y_start: int = 1000
@export var offset: int = 80
@onready var progress_bar = $score_label/ScoreProgress

var current_phase: int = 0
var phases: Array = ["C", "B", "A", "S", "S+"]
var phase_targets: Array = [1200, 2200, 3200, 4200, 0]  # 0 for unlimited in S+
var phase_moves: Array = [30, 25, 20, 15, 10]
var moves_left: int = 30
var total_score: int = 0  # Cumulative score across phases
var match_count: int = 0  # For combo bonus in S+

var fruits = ["black", "red", "green", "yellow", "orange"]
var all_pieces = []
var score: int = 0

var first_piece = null
var is_swapping = false 
var touch_start_pos = Vector2.ZERO
var swipe_threshold = 50 

func _ready() -> void:
	if progress_bar:
		progress_bar.min_value = 0
		progress_bar.max_value = phase_targets[current_phase]
		progress_bar.value = 0
		
	all_pieces = make_2d_array()
	spawn_board()
	update_score_display()
	update_rank_display()
	update_moves_display()

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
	match_count = 0  # Reset for this turn
	if find_matches():
		moves_left -= 1  # Only count if score made
		update_moves_display()
		check_game_over()
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
	match_count += 1
	var destroyed_count = 0
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].is_matched:
				destroyed_count += 1
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	
	if destroyed_count > 0:
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
	total_score += (base_points + bonus)  # Add to total score
	score += (base_points + bonus)  # Phase score for progress bar
	update_score_display()
	
	if current_phase < 4 and score >= phase_targets[current_phase]:
		reach_checkpoint()

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
		# Bonus move for combos in S+
		if current_phase == 4 and match_count >= 2:
			moves_left += 1
			update_moves_display()
			print("Combo Bonus! +1 Move")

func update_score_display():
	if score_label:
		score_label.text = "Score: " + str(total_score)
		score_label.add_theme_font_size_override("font_size", 50)
		# --- Added Visual Juice ---
		# This makes the score board "pulse" when points are added
		var scoreboard_ui = score_label.get_parent() # Assuming Label is child of TextureRect
		var score_tween = create_tween()
		
		# Scale up slightly and turn gold, then back to normal
		score_tween.tween_property(scoreboard_ui, "scale", Vector2(1.1, 1.1), 0.1)
		score_tween.tween_property(scoreboard_ui, "modulate", Color.GOLD, 0.1)
		
		score_tween.chain().tween_property(scoreboard_ui, "scale", Vector2(1.0, 1.0), 0.2)
		score_tween.tween_property(scoreboard_ui, "modulate", Color.WHITE, 0.2)

	if progress_bar:
		print("Updating bar: ", score)
		var bar_tween = create_tween()
		bar_tween.tween_property(progress_bar, "value", score, 0.5).set_trans(Tween.TRANS_SINE)

func reach_checkpoint():
	current_phase += 1
	score = 0  # Reset phase score
	progress_bar.max_value = phase_targets[current_phase] if current_phase < 4 else 999999  # Unlimited for S+
	progress_bar.value = 0
	moves_left = phase_moves[current_phase]
	update_rank_display()
	update_moves_display()
	print("Phase Complete! Advanced to " + phases[current_phase])

func update_rank_display():
	if rank_label:
		rank_label.text = phases[current_phase]

func update_moves_display():
	if moves_label:
		moves_label.text = "Moves: " + str(moves_left)

func check_game_over():
	if moves_left <= 0 and current_phase < 4:
		print("Game Over! Out of moves.")
		# Add game over logic here (e.g., show a screen or restart)	
