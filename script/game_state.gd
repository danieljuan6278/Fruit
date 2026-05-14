extends Node
class_name GameState

# Phase progression system
var current_phase: int = 0
var phases: Array = ["C", "B", "A", "S", "S+"]
var phase_targets: Array = [1200, 2200, 3200, 4200, 0]  # 0 for unlimited in S+
var phase_moves: Array = [30, 25, 20, 15, 10]

# Score and moves tracking
var moves_left: int = 30
var total_score: int = 0  # Cumulative score across phases
var phase_score: int = 0  # Score for current phase (resets each phase)
var match_count: int = 0  # For combo bonus in S+

# Signals for other systems to listen to
signal phase_changed(new_phase: String, moves: int)
signal score_updated(total: int, phase: int)
signal moves_updated(moves_left: int)
signal game_over(phase: String)
signal combo_bonus(bonus_moves: int)

func _ready():
	reset_phase()

func reset_phase():
	"""Reset for new phase"""
	phase_score = 0
	moves_left = phase_moves[current_phase]
	match_count = 0
	score_updated.emit(total_score, phase_score)
	moves_updated.emit(moves_left)

func add_score(points: int) -> bool:
	"""Add score and return true if phase target reached"""
	total_score += points
	phase_score += points
	score_updated.emit(total_score, phase_score)
	
	# Check if phase target reached
	if current_phase < 4 and phase_score >= phase_targets[current_phase]:
		return true
	return false

func use_move() -> bool:
	"""Use a move, return true if moves left"""
	if moves_left > 0:
		moves_left -= 1
		moves_updated.emit(moves_left)
		
		if moves_left <= 0 and current_phase < 4:
			game_over.emit(phases[current_phase])
		return true
	return false

func increment_matches():
	"""Increment match count for combo tracking"""
	match_count += 1

func check_combo_bonus() -> int:
	"""Check if combo bonus should be awarded in S+ phase"""
	var bonus = 0
	if current_phase == 4 and match_count >= 2:
		bonus = 1
		moves_left += bonus
		combo_bonus.emit(bonus)
		moves_updated.emit(moves_left)
	return bonus

func advance_phase():
	"""Move to next phase"""
	if current_phase < 4:
		current_phase += 1
		reset_phase()
		phase_changed.emit(phases[current_phase], moves_left)

func get_current_phase_info() -> Dictionary:
	"""Return current phase info"""
	return {
		"rank": phases[current_phase],
		"target": phase_targets[current_phase],
		"moves": moves_left,
		"total_score": total_score,
		"phase_score": phase_score
	}

func reset_game():
	"""Reset entire game"""
	current_phase = 0
	total_score = 0
	phase_score = 0
	moves_left = phase_moves[0]
	match_count = 0
	reset_phase()
