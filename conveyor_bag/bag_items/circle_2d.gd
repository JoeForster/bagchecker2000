@tool

extends Node2D

@export var color : Color = Color.WHITE :
	set(value):
		color = value
		queue_redraw()
@export var radius : float = 100.0 :
	set(value):
		radius = value
		queue_redraw()

func _draw():
	draw_circle(Vector2(0,0), radius, color)

func set_color(new_color : Color):
	self.color = new_color
