class_name MiniGameBase
extends Node2D

signal on_completed

var bag_contents : BagContents
var is_test_mode = false

func complete():
	on_completed.emit()
	queue_free()
	
func init_with_contents(new_bag_contents : BagContents):
	bag_contents = new_bag_contents.clone()

func _ready() -> void:
	is_test_mode = self.get_parent() == get_tree().root
	$TestModeLabel.set_visible(is_test_mode)
