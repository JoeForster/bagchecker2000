extends Node2D

@export var scroller : Node2D
@export var despawn_area : Area2D
@export var stop_bag_area : Area2D
@export var scroll_speed : float = 50.0
@export var possible_bags : Array[PackedScene]

func _process_scroll(delta: float) -> void:
	#scroller.translate(Vector2.DOWN * scroll_speed * delta)
	for child in scroller.get_children():
		var bag = child as ConveyorBag
		if bag:
			var collision = bag.move_and_collide(Vector2.DOWN * scroll_speed * delta)
			print(collision)

#func _stop_entered(body: Node2D)

func _despawn_entered(body: Node2D):
	var bag = body as ConveyorBag
	if bag:
		bag.on_reached_bottom()



#func _process(delta: float) -> void:
#	for maybe_bag in scroller.get_children():
#		var bag = maybe_bag as StaticBody2D
		

func _ready() -> void:
	var result = despawn_area.body_entered.connect(_despawn_entered)
	print(result)

func _physics_process(delta: float) -> void:
	if scroller:
		_process_scroll(delta)
