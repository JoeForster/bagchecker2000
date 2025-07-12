class_name GameProgression
extends Node

class ShiftResults:
	var num_safe_bags_passed = 0
	var num_successful_searches = 0
	var num_mistakes = 0
	var time_spent = 0

	func get_total_score(game_rules : GameRules, shift_rules : ShiftRules) -> int:
		var total_score = 0
		total_score += num_safe_bags_passed * game_rules.score_per_safe_bag
		total_score += num_successful_searches * game_rules.score_per_searched_bag
		total_score -= num_mistakes * game_rules.penalty_per_mistake
		if time_spent > shift_rules.time_limit:
			total_score -= game_rules.out_of_time_penalty
		return total_score

var current_shift_no = 0
# TODO save previous shift results when needed (note you may repeat shifts!)
var shift_results : ShiftResults

func get_current_shift_results() -> ShiftResults:
	return shift_results

func reset_shift_results():
	shift_results = ShiftResults.new()
