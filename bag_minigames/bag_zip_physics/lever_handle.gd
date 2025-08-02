extends Area2D

@export var mouse_button_index = 1

var mouse_held = false

# TODO is this unnecessary?
#func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
#	var click_event = event as InputEventMouseButton
#	if click_event and click_event.button_index == mouse_button_index and click_event.pressed:
#		mouse_held = true

func _input(event: InputEvent) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == mouse_button_index:
		mouse_held = click_event.pressed

func _ready() -> void:
	pass
	#input_event.connect(_on_input_event)
