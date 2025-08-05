extends Button

class_name SceneTransitionButton

# TODO can't be a PackedScene because we'd get a circular ref. Instead, centralise scene management
@export var scene_to_load : String

signal on_transitioning_scene

func _button_pressed():
	on_transitioning_scene.emit()
	get_tree().change_scene_to_file(scene_to_load)

func _ready():
	pressed.connect(_button_pressed)
