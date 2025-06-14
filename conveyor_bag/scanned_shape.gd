# TODO this is both the scanned displayed shape and a physics object
# should be split or at least renamed
class_name ScannedShape
extends RigidBody2D

@export var shape_name : String
@export var shape_node : Node2D
@export var shape_width_in_scanner = 200.0

var colour : Color
var colour_name : String
var mouse_dragging = false
var physics_enabled = false

func enable_physics():
	if !physics_enabled:
		freeze = false
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		input_event.connect(_on_input_event)
		physics_enabled = true

func set_colour_and_name(new_colour : Color, new_colour_name: String):
	shape_node.set_color(new_colour)
	colour = new_colour
	colour_name = new_colour_name

func clone():
	var new_node = duplicate()
	new_node.set_colour_and_name(colour, colour_name)
	return new_node

func set_highlighter_visible(value : bool):
	$Highlighter.set_visible(value)

func is_highlighted() -> bool:
	return $Highlighter.is_visible()

# TODO HACK The below is probably not the nicest way to handle input here...
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == 1 and click_event.pressed:
		mouse_dragging = true
				

func _input(event: InputEvent) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == 1 && !click_event.pressed:
		mouse_dragging = false
		
func _physics_process(delta: float) -> void:
	if physics_enabled:
		freeze = mouse_dragging
		if mouse_dragging:
			var drag_offset = get_global_position() - $DragPoint.get_global_position()
			set_global_position(get_global_mouse_position() + drag_offset)
