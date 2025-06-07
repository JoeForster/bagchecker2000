class_name Conveyor
extends Node2D

@export var scroller : Node2D
@export var despawn_area : Area2D
@export var stop_bag_collider : CollisionObject2D
@export var scroll_speed : float = 50.0
@export var bag_spawn_point : Node2D
@export var conveyor_bag_scene : PackedScene

signal bag_reached_bottom

var scanned_bag : ConveyorBag = null
#var reenable_timer : float = 0.0

func can_spawn_new_bag():
	if $ConveyorBG/SpawnArea.has_overlapping_bodies():
		return false

	if conveyor_bag_scene == null || !conveyor_bag_scene.can_instantiate():
		return false
		
	return true

func spawn_new_bag(new_bag_contents : BagContents):
	assert(can_spawn_new_bag())

	var new_bag = conveyor_bag_scene.instantiate() as ConveyorBag
	new_bag.set_contents(new_bag_contents)

	scroller.add_child(new_bag)
	new_bag.set_global_position(bag_spawn_point.global_position) # TODO local?
	new_bag.set_owner(scroller)
	# TODO select minigame per type of bag here

func get_scanned_bag() -> ConveyorBag:
	return scanned_bag

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

func _despawn_entered(body: Node2D):
	var bag = body as ConveyorBag
	if bag:
		bag.on_reached_bottom()
		bag_reached_bottom.emit()
		

func _ready() -> void:
	var result = despawn_area.body_entered.connect(_despawn_entered)
	print(result)

func _physics_process(delta: float) -> void:
	if scroller:
		_process_scroll(delta)
