extends Control

@export var title_value : Label

func _ready():
	if title_value:
		title_value.text = "Shift " + str(GameRulesProto.current_shift_no + 1)
