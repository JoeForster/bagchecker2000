class_name ScannedShape
extends Node2D

@export var shape_name : String
@export var shape_node : Node2D
@export var shape_width_in_scanner = 200.0

var colour_name : String

func set_colour(new_colour : Color, new_colour_name: String):
	shape_node.set_color(new_colour)
	colour_name = new_colour_name
