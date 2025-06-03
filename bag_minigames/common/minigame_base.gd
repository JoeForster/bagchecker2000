class_name MiniGameBase
extends Node2D

# Set up these rules for testing the minigame directly as a stand-alone scene.
# in normal gameplay the owner will pass in the rules to init_with_contents
@export var test_rules : GameRules

signal on_completed

var bag_contents : BagContents
var is_test_mode = false

# TEMP HACK for test mode until rules are refactored out of ScannerScreen
func shape_breaks_rule(shape : ScannedShape) -> bool:
	if shape.colour_name == "Red" && shape.shape_name == "Square":
		return true
	return false

func complete():
	on_completed.emit()
	queue_free()
	
func init_with_contents(new_bag_contents : BagContents):
	bag_contents = new_bag_contents.clone()

func _ready() -> void:
	is_test_mode = self.get_parent() == get_tree().root
	$TestModeLabel.set_visible(is_test_mode)
	if is_test_mode:
		var test_contents = test_rules.generate_bag_contents(true)
		init_with_contents(test_contents)
