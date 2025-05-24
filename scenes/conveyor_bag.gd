class_name ConveyorBag
extends RigidBody2D

@export var my_minigame : PackedScene

func start_minigame(scanner: ScannerScreen) -> MiniGameBase:
	if my_minigame:
		var minigame_scene = my_minigame.instantiate() as MiniGameBase
		if minigame_scene:
			minigame_scene._init_with_contents(scanner)
			return minigame_scene
	return null

func on_reached_bottom():
	queue_free()
