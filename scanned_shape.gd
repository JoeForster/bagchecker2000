extends Node2D

@export var shape_name : String
@export var shape_node : Node2D

func set_colour(colour : Color):
	shape_node.set_color(colour)
