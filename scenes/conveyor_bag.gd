class_name ConveyorBag
extends RigidBody2D

@export var my_minigame : PackedScene

var shape_rows : Array[Node2D]

func start_minigame(scanner: ScannerScreen) -> MiniGameBase:
	if my_minigame:
		var minigame_scene = my_minigame.instantiate() as MiniGameBase
		if minigame_scene:
			minigame_scene._init_with_contents(scanner)
			return minigame_scene
	return null

func on_reached_bottom():
	queue_free()

func add_row() -> Node2D:
	var num_rows = shape_rows.size()
	var new_row = Node2D.new()
	new_row.name = "Row " + str(num_rows+1)
	add_child(new_row)
	new_row.set_owner(self)
	shape_rows.push_back(new_row)
	return new_row
