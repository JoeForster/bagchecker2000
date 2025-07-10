extends Button

# TODO can't be a PackedScene because we'd get a circular ref. Instead, centralise scene management
@export var scene_to_load : String

func _button_pressed():
	get_tree().change_scene_to_file(scene_to_load)

func _ready():
	pressed.connect(_button_pressed)
