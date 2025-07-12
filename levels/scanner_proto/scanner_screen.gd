class_name ScannerScreen
extends Node2D

# Game rules
# TODO many to be moved into GameRules
@export var shift_results_scene : PackedScene
@export var shape_refresh_period = 4.0
@export var delay_after_success = 0.5
@export var delay_after_failure = 2.0
@export var initial_max_num_of_shape : int
@export var number_of_bags : int = 10
@export var number_of_bad_bags : int = 4
@export var bag_spawn_period : float = 4.0

# Game elements
@export var conveyor : Conveyor
@export var minigame_holder : Node2D

# UI Elements
@export var timer_label : Label
@export var bags_label : Label
@export var accept_button : Button
@export var reject_button : Button

# Game state
var timer = 0.0
var first_turn = true
var bag_spawn_timer = 0.0
var allow_through_timer = 0.0
var bags_left_to_spawn : Array[BagContents]
var remaining_bags : int
# The scanned bag on the conveyor itself
var current_scanned_bag : ConveyorBag
# NOTE this is a duplicate of the BagContents node within the current_scanned_bag
var scanned_bag_contents : BagContents 

func _get_rules():
	return GameRulesProto

func _get_progression():
	return GameProgressionProto

func _generate_bag_contents(breaks_rule : bool) -> BagContents:
	var new_bag_contents = _get_rules().generate_bag_contents(breaks_rule)
	return new_bag_contents

func _display_bag_contents(bag : ConveyorBag):
	scanned_bag_contents = bag.get_contents().clone()
	add_child(scanned_bag_contents)	
	scanned_bag_contents.set_owner(self)
	var offset = Vector2.ZERO
	for show_row : Node2D in scanned_bag_contents.get_rows():
		show_row.set_position(offset)
		show_row.set_visible(true)
		offset.y += 200

func _clear_displayed_contents():
	for child in get_children():
		child.queue_free()


func _check_forbidden_shapes():
	for r in scanned_bag_contents.get_rows():
		for shape : ScannedShape in r.get_children():
			if _get_rules().shape_breaks_rule(shape):
				return true
	return false

func _highlight_forbidden_shapes():
	var found_any = false
	for r in scanned_bag_contents.get_rows():
		for shape : ScannedShape in r.get_children():
			if _get_rules().shape_breaks_rule(shape):
				found_any = true
				shape.set_highlighter_visible(true)
	return found_any

func _on_bag_removed():
	remaining_bags -= 1


func _allow_bag_through():
	# the scanner stopper only blocks layer 1 but the despawner blocks layers 1 and 2,
	# so this nwill allow it through whilst still hitting the despawner.
	current_scanned_bag.set_collision_mask_value(1, false)

func _check_accept():
	if current_scanned_bag == null:
		return # TODO disable the button in all cases there's no bag
	
	if _highlight_forbidden_shapes():
		_get_progression().num_failures += 1
		allow_through_timer = delay_after_failure
	else:
		_get_progression().num_successes += 1
		allow_through_timer = delay_after_success

	accept_button.disabled = true
	reject_button.disabled = true

func _on_completed_bag_minigame():
	_clear_displayed_contents()
	_get_progression().num_successes += 1
	allow_through_timer = delay_after_success

func _check_reject():
	if current_scanned_bag == null:
		return # TODO disable the button in all cases there's no bag
	
	_clear_displayed_contents()
	
	if _check_forbidden_shapes():
		var search_minigame : MiniGameBase = current_scanned_bag.start_minigame(_get_rules())
		if search_minigame:
			search_minigame.on_completed.connect(_on_completed_bag_minigame)
			minigame_holder.add_child(search_minigame)
			search_minigame.set_owner(minigame_holder)
			
		else:
			_on_completed_bag_minigame()
	else:
		_get_progression().num_failures += 1
		allow_through_timer = delay_after_failure

	accept_button.disabled = true
	reject_button.disabled = true

func _ready():
	# Generate t he bags- meeting our quota of "bad" bags in random order
	var bags_bad_flags : Array[bool]
	assert(number_of_bad_bags <= number_of_bags, "number_of_bad_bags is larger than number_of_bags!!")
	for bag_index in range(0, number_of_bags):
		var this_bag_is_bad = (bag_index < number_of_bad_bags)
		bags_bad_flags.push_back(this_bag_is_bad)
	bags_bad_flags.shuffle()

	bags_left_to_spawn.clear()
	for this_bag_is_bad in bags_bad_flags:
		var new_bag = _generate_bag_contents(this_bag_is_bad)
		assert(new_bag, "could not generate new bag - rule issue?")
		if new_bag != null:
			bags_left_to_spawn.push_back(new_bag)
	
	if conveyor:
		conveyor.bag_reached_bottom.connect(_on_bag_removed)
	if accept_button:
		accept_button.pressed.connect(_check_accept)
	if reject_button:
		reject_button.pressed.connect(_check_reject)
	
	if conveyor:
		timer = _get_rules().time_limit
		remaining_bags = number_of_bags

func _game_over():
	get_tree().change_scene_to_packed(shift_results_scene)

func _conveyor_process(delta):
	if remaining_bags <= 0:
		_game_over()
		return
	
	timer -= delta
	if timer <= 0:
		timer = 0
		_game_over()
		return

	bag_spawn_timer -= delta
	if bag_spawn_timer <= 0 and conveyor.can_spawn_new_bag() and not bags_left_to_spawn.is_empty():
		var next_bag = bags_left_to_spawn.pop_back()
		conveyor.spawn_new_bag(next_bag)
		bag_spawn_timer = bag_spawn_period
	
	var scanned_bag : ConveyorBag = conveyor.get_scanned_bag()
	if scanned_bag:
		if current_scanned_bag != scanned_bag:
			current_scanned_bag = scanned_bag
			_display_bag_contents(scanned_bag)

			accept_button.disabled = false
			reject_button.disabled = false

	if allow_through_timer > 0.0:
		allow_through_timer -= delta
		if allow_through_timer <= 0.0:
			allow_through_timer = 0.0
			_clear_displayed_contents()
			_allow_bag_through()

func _update_ui():
	if timer_label:
		timer_label.text = str(timer).pad_decimals(2).replace(".", ":")
	if bags_label:
		bags_label.text = str(remaining_bags)

func _process(delta):
	_conveyor_process(delta)
	_update_ui()
