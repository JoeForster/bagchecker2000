class_name ConveyorBag
extends RigidBody2D

func on_reached_bottom():
	queue_free()
