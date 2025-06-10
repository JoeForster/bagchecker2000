class_name ScannedShape
extends CollisionObject2D

@export var shape_name : String
@export var shape_node : Node2D
@export var shape_width_in_scanner = 200.0

var colour : Color
var colour_name : String

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
