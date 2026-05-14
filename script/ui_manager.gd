extends Node
class_name UIManager

@export var score_label: Label
@export var rank_label: Label
@export var moves_label: Label
@export var progress_bar: TextureProgressBar

var game_state: GameState

# Color themes per phase: C, B, A, S, S+
# Each theme: { font_color, outline_color, shadow_color, bar_tint, accent }
var phase_themes: Array = [
	{  # C - Orange/warm (starting phase)
		"font_color": Color(1, 0.92, 0.2, 1),
		"outline_color": Color(0, 0, 0, 1),
		"shadow_color": Color(0.15, 0.1, 0.0, 0.7),
		"bar_tint": Color(1, 0.85, 0.3, 1),
		"accent": Color(1, 0.75, 0.2, 1),
		"bar_texture": "res://assets/horizontal bars/most rounded/progress bar most rounded progress orange.png"
	},
	{  # B - Blue/cool
		"font_color": Color(0.4, 0.75, 1.0, 1),
		"outline_color": Color(0, 0, 0, 1),
		"shadow_color": Color(0.0, 0.05, 0.2, 0.7),
		"bar_tint": Color(0.5, 0.8, 1.0, 1),
		"accent": Color(0.3, 0.65, 1.0, 1),
		"bar_texture": "res://assets/horizontal bars/most rounded/progress bar most rounded progress blue.png"
	},
	{  # A - Red/fiery
		"font_color": Color(1.0, 0.35, 0.25, 1),
		"outline_color": Color(0, 0, 0, 1),
		"shadow_color": Color(0.2, 0.0, 0.0, 0.7),
		"bar_tint": Color(1.0, 0.4, 0.3, 1),
		"accent": Color(1.0, 0.25, 0.15, 1),
		"bar_texture": "res://assets/horizontal bars/most rounded/progress bar most rounded progress red.png"
	},
	{  # S - Yellow/brilliant
		"font_color": Color(1.0, 1.0, 0.2, 1),
		"outline_color": Color(0, 0, 0, 1),
		"shadow_color": Color(0.15, 0.12, 0.0, 0.7),
		"bar_tint": Color(1.0, 1.0, 0.4, 1),
		"accent": Color(1.0, 0.95, 0.2, 1),
		"bar_texture": "res://assets/horizontal bars/most rounded/progress bar most rounded progress purple.png"
	},
	{  # S+ - Gold/legendary
		"font_color": Color(1.0, 0.84, 0.0, 1),
		"outline_color": Color(0, 0, 0, 1),
		"shadow_color": Color(0.2, 0.15, 0.0, 0.7),
		"bar_tint": Color(1.0, 0.78, 0.2, 1),
		"accent": Color(1.0, 0.75, 0.0, 1),
		"bar_texture": "res://assets/horizontal bars/most rounded/progress bar most rounded progress orange.png"
	}
]

func _ready():
	_resolve_node_paths()
	_apply_rank_style()
	if progress_bar:
		progress_bar.min_value = 0
		progress_bar.max_value = 1200
		progress_bar.value = 0

func _resolve_node_paths():
	"""Resolve node paths if they haven't been resolved yet"""
	if not score_label:
		score_label = get_node("../score_label/ScoreContainer/TextureRect/Label")
	if not rank_label:
		rank_label = get_node("../score_label/RankLabel")
	if not moves_label:
		moves_label = get_node("../score_label/MovesLabel")
	if not progress_bar:
		progress_bar = get_node("../score_label/ScoreProgress")

func _setup_signal_connections():
	"""Connect to game state signals"""
	if game_state:
		if not game_state.score_updated.is_connected(_on_score_updated):
			game_state.score_updated.connect(_on_score_updated)
		if not game_state.moves_updated.is_connected(_on_moves_updated):
			game_state.moves_updated.connect(_on_moves_updated)
		if not game_state.phase_changed.is_connected(_on_phase_changed):
			game_state.phase_changed.connect(_on_phase_changed)
		if not game_state.combo_bonus.is_connected(_on_combo_bonus):
			game_state.combo_bonus.connect(_on_combo_bonus)
		if not game_state.game_over.is_connected(_on_game_over):
			game_state.game_over.connect(_on_game_over)

func set_game_state(state: GameState):
	"""Set reference to game state"""
	game_state = state
	_setup_signal_connections()
	initialize_display()

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
	"""Update rank display and apply color theme when phase changes"""
	if rank_label:
		rank_label.text = phase
		_apply_rank_style()
		_play_rank_transition()
	
	# Update progress bar for new phase
	if progress_bar:
		progress_bar.max_value = 1200
	
	# Apply the color theme for this phase
	_apply_phase_theme()

func _on_combo_bonus(bonus_moves: int):
	"""Show combo bonus feedback"""
	print("Combo Bonus! +%d Move(s)" % bonus_moves)
	if moves_label:
		var theme = _get_current_theme()
		_pulse_label(moves_label, Color(0.55, 0.9, 0.35))

func _on_game_over(phase: String):
	"""Handle game over"""
	print("Game Over! Out of moves in phase %s." % phase)

func _get_current_theme() -> Dictionary:
	"""Get the theme for the current phase"""
	if game_state:
		return phase_themes[clampi(game_state.current_phase, 0, phase_themes.size() - 1)]
	return phase_themes[0]

func _apply_phase_theme():
	"""Apply color theme to all UI elements based on current phase"""
	var theme = _get_current_theme()
	
	# Animate RankLabel color change
	if rank_label:
		var tween_rank = create_tween().set_parallel(true)
		# Flash white then settle to the new color
		rank_label.add_theme_color_override("font_color", Color.WHITE)
		tween_rank.tween_property(rank_label, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_BACK)
		await tween_rank.finished
		
		var tween_settle = create_tween().set_parallel(true)
		rank_label.add_theme_color_override("font_color", theme["font_color"])
		rank_label.add_theme_color_override("font_shadow_color", theme["shadow_color"])
		tween_settle.tween_property(rank_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)
		await tween_settle.finished
	
	# Animate progress bar color swap
	if progress_bar:
		var bar_texture = load(theme["bar_texture"])
		if bar_texture:
			# Fade out, swap, fade in
			var tween_bar = create_tween()
			tween_bar.tween_property(progress_bar, "modulate:a", 0.0, 0.15)
			await tween_bar.finished
			progress_bar.texture_progress = bar_texture
			progress_bar.modulate = Color(theme["bar_tint"].r, theme["bar_tint"].g, theme["bar_tint"].b, 0.0)
			var tween_bar_in = create_tween()
			tween_bar_in.tween_property(progress_bar, "modulate", theme["bar_tint"], 0.25)
	
	# Animate ScoreContainer label accent
	if score_label:
		var score_texture = score_label.get_parent()  # The TextureRect
		if score_texture:
			var accent_color = Color(
				lerp(1.0, theme["accent"].r, 0.3),
				lerp(1.0, theme["accent"].g, 0.3),
				lerp(1.0, theme["accent"].b, 0.3),
				1.0
			)
			var tween_score = create_tween()
			tween_score.tween_property(score_texture, "modulate", accent_color, 0.4).set_trans(Tween.TRANS_SINE)
		
		# Tint the score font slightly toward the phase color
		var font_tint = Color(
			lerp(1.0, theme["font_color"].r, 0.2),
			lerp(0.95, theme["font_color"].g, 0.2),
			lerp(0.82, theme["font_color"].b, 0.2),
			1.0
		)
		score_label.add_theme_color_override("font_color", font_tint)

func _pulse_score_label():
	"""Animate score label"""
	if not score_label:
		return
	
	var scoreboard_ui = score_label.get_parent()
	var theme = _get_current_theme()
	var tween = create_tween()
	tween.tween_property(scoreboard_ui, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(scoreboard_ui, "modulate", theme["accent"], 0.1)
	tween.chain().tween_property(scoreboard_ui, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(scoreboard_ui, "modulate", Color.WHITE, 0.2)

func _pulse_label(label: Label, color: Color = Color(1.0, 0.86, 0.25)):
	"""Generic label pulse animation"""
	if not label:
		return
	
	var tween = create_tween()
	tween.tween_property(label, "modulate", color, 0.1)
	tween.chain().tween_property(label, "modulate", Color.WHITE, 0.2)

func _apply_rank_style():
	if not rank_label:
		return
	
	# We set pivot_offset but let phase_theme handle the color
	rank_label.pivot_offset = rank_label.size * 0.5

func _play_rank_transition():
	if not rank_label:
		return
	
	rank_label.scale = Vector2(0.65, 0.65)
	rank_label.modulate.a = 0.0
	rank_label.pivot_offset = rank_label.size * 0.5
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(rank_label, "modulate:a", 1.0, 0.08)
	tween.tween_property(rank_label, "scale", Vector2(1.8, 1.8), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_property(rank_label, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func initialize_display():
	"""Initialize all UI displays"""
	if game_state:
		# First trigger the initial state signals
		game_state.reset_phase()
		
		var info = game_state.get_current_phase_info()
		if score_label:
			score_label.text = "Score: " + str(info["total_score"])
		if rank_label:
			rank_label.text = info["rank"]
			_apply_rank_style()
		if moves_label:
			moves_label.text = "Moves: " + str(info["moves"])
		if progress_bar:
			progress_bar.max_value = info["phase_size"]
			progress_bar.value = info["phase_score"]
		
		# Apply initial theme without animation
		var theme = _get_current_theme()
		if rank_label:
			rank_label.add_theme_color_override("font_color", theme["font_color"])
			rank_label.add_theme_color_override("font_shadow_color", theme["shadow_color"])
		if progress_bar:
			var bar_texture = load(theme["bar_texture"])
			if bar_texture:
				progress_bar.texture_progress = bar_texture
			progress_bar.modulate = theme["bar_tint"]
