@tool

extends Node2D

@export var colour : Color = Color.WHITE
@export var radius : float = 100.0

func _draw():
	draw_circle(Vector2(0,0), radius, colour)
