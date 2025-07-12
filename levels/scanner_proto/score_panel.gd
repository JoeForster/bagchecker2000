extends Panel

@export var score_label : Label
@export var score_needed_label : Label
@export var num_safe_bags_passed_label : Label
@export var num_successful_searches_label : Label
@export var num_mistakes_label : Label
@export var time_label : Label



func _process(_delta: float) -> void:
	var shift_results = GameProgressionProto.get_current_shift_results()
	if score_label:
		score_label.text = str(shift_results.get_total_score(GameRulesProto, GameRulesProto.get_shift_rules()))
	if score_needed_label && GameRulesProto.get_shift_rules():
		score_needed_label.text = str(GameRulesProto.get_shift_rules().passing_score_threshold)
	if num_safe_bags_passed_label:
		num_safe_bags_passed_label.text = str(shift_results.num_safe_bags_passed)
	if num_successful_searches_label:
		num_successful_searches_label.text = str(shift_results.num_successful_searches)
	if num_mistakes_label:
		num_mistakes_label.text = str(shift_results.num_mistakes)
	if time_label:
		time_label.text = str(shift_results.time_spent)
		if GameRulesProto.get_shift_rules():
			time_label.text += " / " + str(GameRulesProto.get_shift_rules().time_limit)
