class_name Conveyor
extends Node2D

@export var scroller : Node2D
@export var despawn_area : Area2D
@export var stop_bag_collider : CollisionObject2D
@export var scroll_speed : float = 50.0
@export var possible_bags : Array[PackedScene]

var scanned_bag : ConveyorBag = null
#var reenable_timer : float = 0.0

func get_scanned_bag() -> ConveyorBag:
	return scanned_bag

#func allow_bag_through():
#	stop_bag_collider.set_
#	stop_bag_collider.process_mode = Node.PROCESS_MODE_DISABLED
#	reenable_timer = 2 # HACK - this makes us dependent 

func _process_scroll(delta: float) -> void:
	#scroller.translate(Vector2.DOWN * scroll_speed * delta)
	scanned_bag = null
	for child in scroller.get_children():
		var bag = child as ConveyorBag
		if bag:
			var collision = bag.move_and_collide(Vector2.DOWN * scroll_speed * delta)
			if collision:
				if collision.get_collider() == stop_bag_collider:
					scanned_bag = bag

#func _stop_entered(body: Node2D)

func _despawn_entered(body: Node2D):
	var bag = body as ConveyorBag
	if bag:
		bag.on_reached_bottom()
		

func _ready() -> void:
	var result = despawn_area.body_entered.connect(_despawn_entered)
	print(result)

func _physics_process(delta: float) -> void:
	if scroller:
		_process_scroll(delta)

func _process(delta: float) -> void:
	pass
	#if reenable_timer > 0:
	#	reenable_timer -= delta
	#	if reenable_timer <= 0:
	#		stop_bag_collider.process_mode = Node.PROCESS_MODE_INHERIT
			
