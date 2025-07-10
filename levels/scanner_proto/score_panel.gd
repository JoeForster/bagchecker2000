extends Panel

@export var successes_label : Label
@export var failures_label : Label

func _ready():
	if successes_label:
		successes_label.text = str(GameProgressionProto.num_successes)
	if failures_label:
		failures_label.text = str(GameProgressionProto.num_failures)
