class_name ConveyorBag
extends RigidBody2D

@export var possible_minigames : Array[PackedScene]

var bag_contents : BagContents

func start_minigame(game_rules : GameRules) -> MiniGameBase:
	if !possible_minigames.is_empty():
		var minigame_scene = possible_minigames.pick_random().instantiate() as MiniGameBase
		if minigame_scene:
			minigame_scene.init_with_contents(game_rules, bag_contents)
			return minigame_scene
	return null

func on_reached_bottom():
	queue_free()

func set_contents(new_bag_contents : BagContents):
	bag_contents = new_bag_contents
	if new_bag_contents:
		add_child(new_bag_contents)
		new_bag_contents.set_owner(self)

func get_contents() -> BagContents:
	return bag_contents
