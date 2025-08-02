extends Node2D
class_name ScannerLever

@export var mouse_button_index = 1
@export var lever_max_speed = 30.0
@export var handle : Area2D
@export var path : Path2D
@export var path_follow : PathFollow2D

var mouse_held = false

func is_lever_at_bottom():
	if path_follow and path_follow.progress_ratio == 1.0:
		return true
	else:
		return false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == mouse_button_index and click_event.pressed:
		mouse_held = true

func _input(event: InputEvent) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == mouse_button_index && !click_event.pressed:
		mouse_held = false

func _ready() -> void:
	if handle:
		handle.input_event.connect(_on_input_event)

func _process_lever_movement(delta: float) -> void:
	# Move the lever handle to the point closest to the mouse, if held, or return it to start if not.
	var global_mouse_pos = get_global_mouse_position()
	var path_local_mouse_pos = path.to_local(global_mouse_pos)
	var current_offset = path_follow.get_progress()
	var delta_px = lever_max_speed * delta

	var desired_offset = 0.0
	if mouse_held:
		desired_offset = path.curve.get_closest_offset(path_local_mouse_pos)

	if absf(desired_offset - current_offset) < delta_px:
		path_follow.set_progress(desired_offset)
	elif desired_offset > current_offset:
		path_follow.set_progress(current_offset + delta_px)
	else:#if desired_offset < current_offset:
		path_follow.set_progress(current_offset - delta_px)
	

func _process(delta: float) -> void:
	if path and path_follow:
		_process_lever_movement(delta)
