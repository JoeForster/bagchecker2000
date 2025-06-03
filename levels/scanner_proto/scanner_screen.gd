class_name ScannerScreen
extends Node2D

# Game rules
# TODO many to be moved into GameRules
@export var game_rules : GameRules
@export var shape_refresh_period = 4.0
@export var initial_max_num_of_shape : int
@export var number_of_bags : int = 10
@export var number_of_bad_bags : int = 4
@export var bag_spawn_period : float = 4.0
@export var time_limit : float = 300.0

# Game elements
@export var conveyor : Conveyor

# UI Elements
@export var timer_label : Label
@export var bags_label : Label
@export var successes_label : Label
@export var failures_label : Label
@export var rule_label : Label
@export var accept_button : Button
@export var reject_button : Button

# Game state
var timer : float = 0
var first_turn = true
var bag_spawn_timer : float = 0
var bags_left_to_spawn : Array[BagContents]
var remaining_bags : int
var num_failures = 0
var num_successes = 0
# The scanned bag on the conveyor itself
var current_scanned_bag : ConveyorBag
# NOTE this is a duplicate of the BagContents node within the current_scanned_bag
var scanned_bag_contents : BagContents 

func _generate_bag_contents(breaks_rule : bool) -> BagContents:
	var new_bag_contents = game_rules.generate_bag_contents(breaks_rule)
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

func _highlight_forbidden_shapes():
	var found_any = false
	for r in scanned_bag_contents.get_rows():
		for shape : ScannedShape in r.get_children():
			if game_rules.shape_breaks_rule(shape):
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

	_clear_displayed_contents()
	_allow_bag_through()

func _on_completed_bag_minigame():
	current_scanned_bag.queue_free()
	_clear_displayed_contents()
	_on_bag_removed()

func _check_reject():
	if current_scanned_bag == null:
		return # TODO disable the button in all cases there's no bag
	
	if _highlight_forbidden_shapes():
		num_successes += 1 # TODO this should be tied to success in the minigame
		var search_minigame : MiniGameBase = current_scanned_bag.start_minigame()
		if search_minigame:
			search_minigame.on_completed.connect(_on_completed_bag_minigame)
			# HACK
			get_parent().add_child(search_minigame)
			search_minigame.set_owner(get_parent())
		else:
			_on_completed_bag_minigame()
	else:
		num_failures += 1
		_clear_displayed_contents()
		_allow_bag_through()

	accept_button.disabled = true
	reject_button.disabled = true

func _init_ui():
	# setup persistent UI (just rules at the moment)
	if rule_label:
		var current_label_offset = 0
		for rule in game_rules.current_rules:
			# HACK: Get or duplicate the rule label per rule
			var this_rule_label : Label
			if current_label_offset == 0:
				this_rule_label = rule_label
			else:
				this_rule_label = rule_label.duplicate()
				rule_label.add_sibling(this_rule_label)
				this_rule_label.set_owner(rule_label.get_parent())
				this_rule_label.set_position(rule_label.get_position() + Vector2(0, current_label_offset))
			current_label_offset += this_rule_label.get_size().y
			# Populate the rule label
			if rule.max_num_of_shape <= 0:
				this_rule_label.text = "No " + rule.restricted_colour_name + " " + rule.restricted_shape + "s"
			else:
				this_rule_label.text = "No more than " + this_rule_label.max_num_of_shape + " " + rule.restricted_colour_name + " " + rule.restricted_shape + "s"
			var text_colour = game_rules.possible_colours[rule.restricted_colour_name]
			this_rule_label.add_theme_color_override("font_color", text_colour)

func _ready():
	_init_ui()
	
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
	
	var scanned_bag : ConveyorBag = conveyor.get_scanned_bag()
	if scanned_bag:
		if current_scanned_bag != scanned_bag:
			current_scanned_bag = scanned_bag
			_display_bag_contents(scanned_bag)

		accept_button.disabled = false
		reject_button.disabled = false

func _update_ui():
	if timer_label:
		timer_label.text = str(timer).pad_decimals(2).replace(".", ":")
	if bags_label:
		bags_label.text = str(remaining_bags)
	if successes_label:
		successes_label.text = str(num_successes)
	if failures_label:
		failures_label.text = str(num_failures)

func _process(delta):
	_conveyor_process(delta)
	_update_ui()
