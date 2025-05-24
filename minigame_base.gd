class_name MiniGameBase
extends Node2D

signal on_completed

func complete():
	on_completed.emit()
	queue_free()

func _init_with_contents(scanner : ScannerScreen):
	pass
