class_name ScannerScreen
extends Node2D

# Game rules
@export var shape_refresh_period = 4.0
@export var shapes_per_row = 4
@export var shape_name_to_scene : Dictionary
@export var possible_colours : Dictionary
@export var initial_restricted_shape : String
@export var initial_restricted_colour_name : String
@export var initial_max_num_of_shape : int
@export var number_of_bags : int = 10
@export var number_of_bad_bags : int = 4
@export var bag_spawn_period : float = 4.0
@export var time_limit : float = 300.0

# Game elements
@export var conveyor : Conveyor
@export var conveyor_bag_scene : PackedScene

# UI Elements
@export var timer_label : Label
@export var bags_label : Label
@export var successes_label : Label
@export var failures_label : Label
@export var rule_label : Label
@export var accept_button : Button
@export var reject_button : Button

class Rule:
	var restricted_shape : String
	var restricted_colour_name : String
	var max_num_of_shape : int

# Game state
var timer : float = 0
var first_turn = true
var bag_spawn_timer : float = 0
var possible_shape_colour_combos_passing_rule : Array[ScannedShape]
var possible_shape_colour_combos_failing_rule : Array[ScannedShape]
var bags_left_to_spawn : Array[ConveyorBag]
var remaining_bags : int
var num_failures = 0
var num_successes = 0
var current_rule : Rule
var current_scanned_bag : ConveyorBag = null

func _clear_shapes():
	for child in get_children():
		child.queue_free()

func _shape_breaks_rule(shape : ScannedShape) -> bool:
	return shape.colour_name == current_rule.restricted_colour_name && shape.shape_name == current_rule.restricted_shape

func _generate_shape_colour_combos(want_to_break_rule : bool) -> Array[ScannedShape]:
	var possible_shape_colour_combos : Array[ScannedShape]
	for possible_colour_name in possible_colours:
		for possible_shape_name in shape_name_to_scene:
			var shape_scene : PackedScene = shape_name_to_scene[possible_shape_name]
			assert(shape_scene, "Could not find mapped PackedScene for shape name '"  + possible_shape_name + "'")
			var this_shape_entry = shape_name_to_scene[possible_shape_name].instantiate() as ScannedShape
			assert(this_shape_entry, "Could not find instantiate PackedScene for shape name '"  + possible_shape_name + "'")
			this_shape_entry.set_colour(possible_colours[possible_colour_name], possible_colour_name)
			this_shape_entry.shape_name = possible_shape_name
			if _shape_breaks_rule(this_shape_entry) == want_to_break_rule:
				possible_shape_colour_combos.push_back(this_shape_entry)
	return possible_shape_colour_combos


func _generate_bag_contents(breaks_rule : bool) -> ConveyorBag:
	var possible_combos = possible_shape_colour_combos_passing_rule if breaks_rule else possible_shape_colour_combos_failing_rule
	if possible_combos.is_empty():
		# this means "no possible bag is valid", so we want to return null
		# meaning erroneous rather than an empty bag.
		return null

	var new_bag_contents = conveyor_bag_scene.instantiate()
	for row_index in range(0, shapes_per_row):
		var offset = Vector2.ZERO
		var shape_row = new_bag_contents.add_row()
		for shape_index in range(shapes_per_row):
			var new_shape_orig : ScannedShape = possible_combos.pick_random()
			var new_shape_dupe = new_shape_orig.duplicate()
			shape_row.add_child(new_shape_dupe)
			new_shape_dupe.set_owner(shape_row)
			new_shape_dupe.translate(offset)
			offset.x += new_shape_dupe.shape_width_in_scanner
	
	return new_bag_contents

func _display_bag_contents(bag_contents : ConveyorBag):
	# TODO can we eliminate this variable in favour of an index (or assuming the last) in the main array of shapes?
	current_scanned_bag = bag_contents
	if bag_contents.is_empty():
		return
	
	add_child(bag_contents)	
	
	var child_rows = get_children()
	assert(child_rows.size() == bag_contents.rows.size(), "Fixed row count expected to match bag_contents.rows")



func _highlight_forbidden_shapes():
	var found_any = false
	for r in current_scanned_bag.get_children():
		for shape : ScannedShape in r.get_children():
			if _shape_breaks_rule(shape):
				found_any = true
				var highlighter_node = shape.get_child(0) as Node2D
				if highlighter_node:
					highlighter_node.visible = true
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
		num_failures += 1
	else:
		num_successes += 1
	accept_button.disabled = true
	reject_button.disabled = true

	_clear_shapes()
	_allow_bag_through()

func _on_completed_bag_minigame():
	current_scanned_bag.queue_free()
	_clear_shapes()
	_on_bag_removed()

func _check_reject():
	if current_scanned_bag == null:
		return # TODO disable the button in all cases there's no bag
	
	if _highlight_forbidden_shapes():
		num_successes += 1 # TODO this should be tied to success in the minigame
		var search_minigame : MiniGameBase = null # current_scanned_bag.start_minigame(self)
		if search_minigame:
			search_minigame.on_completed.connect(_on_completed_bag_minigame)
			# HACK
			get_parent().add_child(search_minigame)
			search_minigame.set_owner(get_parent())
		else:
			_on_completed_bag_minigame()
	else:
		num_failures += 1
		_allow_bag_through()

	accept_button.disabled = true
	reject_button.disabled = true

func _ready():
	# Generate a rule
	current_rule = Rule.new()
	current_rule.restricted_colour_name = initial_restricted_colour_name
	current_rule.restricted_shape = initial_restricted_shape
	current_rule.max_num_of_shape = 0
	
	# Generate the possible shapes based on the rules
	possible_shape_colour_combos_passing_rule =  _generate_shape_colour_combos(true)
	possible_shape_colour_combos_failing_rule =  _generate_shape_colour_combos(false)
	
	# Generate the bags - meeting our quota of "bad" bags in random order
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
		timer = time_limit
		remaining_bags = number_of_bags

func _on_scan_new_bag():
	_display_bag_contents(current_scanned_bag)

	accept_button.disabled = false
	reject_button.disabled = false

func _conveyor_process(delta):
	timer -= delta
	if timer <= 0:
		timer = 0
		# TODO GAME OVER LOGIC
		return

	bag_spawn_timer -= delta
	if bag_spawn_timer <= 0:
		var next_bag = bags_left_to_spawn.pop_back()
		if next_bag:
			conveyor.spawn_new_bag(next_bag)
		bag_spawn_timer = bag_spawn_period
	
	var scanned_bag = conveyor.get_scanned_bag()
	if scanned_bag:
		if current_scanned_bag != scanned_bag:
			current_scanned_bag = scanned_bag
			_on_scan_new_bag()

func _update_ui():
	if timer_label:
		timer_label.text = str(timer).pad_decimals(2).replace(".", ":")
	if bags_label:
		bags_label.text = str(remaining_bags)
	if successes_label:
		successes_label.text = str(num_successes)
	if failures_label:
		failures_label.text = str(num_failures)
	if rule_label:
		if current_rule.max_num_of_shape <= 0:
			rule_label.text = "No " + current_rule.restricted_colour_name + " " + current_rule.restricted_shape + "s"
		else:
			rule_label.text = "No more than " + rule_label.max_num_of_shape + " " + current_rule.restricted_colour_name + " " + current_rule.restricted_shape + "s"
		rule_label.add_theme_color_override("font_color", current_rule.restricted_colour_name)

func _process(delta):
	_conveyor_process(delta)
	_update_ui()
