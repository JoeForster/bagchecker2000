extends Panel

@export var score_label : Label
@export var score_needed_label : Label
@export var successes_label : Label
@export var failures_label : Label

func _process(_delta: float) -> void:
	if score_label:
		score_label.text = str(GameProgressionProto.score)
	if score_needed_label && GameRulesProto.get_shift_rules():
		score_needed_label.text = str(GameRulesProto.get_shift_rules().passing_score_threshold)
	if successes_label:
		successes_label.text = str(GameProgressionProto.num_successes)
	if failures_label:
		failures_label.text = str(GameProgressionProto.num_failures)
