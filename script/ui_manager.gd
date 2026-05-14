extends Node
class_name UIManager

@export var score_label: Label
@export var rank_label: Label
@export var moves_label: Label
@export var progress_bar: TextureProgressBar

var game_state: GameState

func _ready():
	# Initialize progress bar
	if progress_bar:
		progress_bar.min_value = 0
		progress_bar.max_value = 1200  # Default for phase C
		progress_bar.value = 0
	
	# Connect to game state signals
	if game_state:
		game_state.score_updated.connect(_on_score_updated)
		game_state.moves_updated.connect(_on_moves_updated)
		game_state.phase_changed.connect(_on_phase_changed)
		game_state.combo_bonus.connect(_on_combo_bonus)
		game_state.game_over.connect(_on_game_over)

func set_game_state(state: GameState):
	"""Set reference to game state"""
	game_state = state
	_ready()

func _on_score_updated(total_score: int, phase_score: int):
	"""Update score display"""
	if score_label:
		score_label.text = "Score: " + str(total_score)
		_pulse_score_label()
	
	if progress_bar:
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", phase_score, 0.5).set_trans(Tween.TRANS_SINE)

func _on_moves_updated(moves_left: int):
	"""Update moves display"""
	if moves_label:
		moves_label.text = "Moves: " + str(moves_left)

func _on_phase_changed(phase: String, moves: int):
	"""Update rank display and progress bar when phase changes"""
	if rank_label:
		rank_label.text = phase
	
	# Update progress bar for new phase
	if progress_bar:
		var target = 0
		match phase:
			"C": target = 1200
			"B": target = 2200
			"A": target = 3200
			"S": target = 4200
			"S+": target = 999999  # Unlimited
		
		progress_bar.max_value = target
		progress_bar.value = 0

func _on_combo_bonus(bonus_moves: int):
	"""Show combo bonus feedback"""
	print("Combo Bonus! +%d Move(s)" % bonus_moves)
	if moves_label:
		_pulse_label(moves_label, Color.GREEN)

func _on_game_over(phase: String):
	"""Handle game over"""
	print("Game Over! Out of moves in phase %s." % phase)
	# Add game over screen here later

func _pulse_score_label():
	"""Animate score label"""
	if not score_label:
		return
	
	var scoreboard_ui = score_label.get_parent()
	var tween = create_tween()
	tween.tween_property(scoreboard_ui, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(scoreboard_ui, "modulate", Color.GOLD, 0.1)
	tween.chain().tween_property(scoreboard_ui, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(scoreboard_ui, "modulate", Color.WHITE, 0.2)

func _pulse_label(label: Label, color: Color = Color.GOLD):
	"""Generic label pulse animation"""
	if not label:
		return
	
	var tween = create_tween()
	tween.tween_property(label, "modulate", color, 0.1)
	tween.chain().tween_property(label, "modulate", Color.WHITE, 0.2)

func initialize_display():
	"""Initialize all UI displays"""
	if game_state:
		var info = game_state.get_current_phase_info()
		if score_label:
			score_label.text = "Score: " + str(info["total_score"])
		if rank_label:
			rank_label.text = info["rank"]
		if moves_label:
			moves_label.text = "Moves: " + str(info["moves"])
		if progress_bar:
			progress_bar.value = info["phase_score"]
