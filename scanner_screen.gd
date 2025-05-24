class_name ScannerScreen
extends Node2D

# Game rules
@export var shape_refresh_period = 4.0
@export var horizontal_offset = 200.0
@export var possible_shapes : Array[PackedScene]
@export var possible_colours : Dictionary
@export var initial_restricted_shape : String
@export var initial_restricted_colour_name : String
@export var initial_max_num_of_shape : int
@export var number_of_bags : int = 10
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

# Internal data structures
class ShapeEntry:
	var node : Node
	var colour_name : String
	var shape_name : String

class ShapeRow:
	var node : Node2D
	var shapes : Array[ShapeEntry]

class BagContents:
	var rows : Array[ShapeRow]

class Rule:
	var restricted_shape : String
	var restricted_colour_name : String
	var max_num_of_shape : int

# Game state
var timer : float = 0
var first_turn = true
var bag_spawn_timer : float = 0
var bags_left_to_spawn : int
var remaining_bags : int
var scanned_bag_contents : BagContents
var num_failures = 0
var num_successes = 0
var current_rule : Rule
var current_scanned_bag : ConveyorBag = null

func get_bag_contents():
	return scanned_bag_contents

func _clear_shapes():
	if scanned_bag_contents:
		for r in scanned_bag_contents.rows:
			for s in r.shapes:
				s.node.queue_free()
		scanned_bag_contents.rows.clear()
	scanned_bag_contents = BagContents.new()

func _spawn_shapes():
	if possible_shapes.is_empty():
		return

	var num_in_row = 4
	for row_node in get_children():

		var offset = Vector2.ZERO
		var shape_row = ShapeRow.new()
		shape_row.node = row_node

		for i in num_in_row:
			var spawn_from : PackedScene = possible_shapes.pick_random()
			var shape_colour_name = possible_colours.keys().pick_random()
			var shape_colour = possible_colours[shape_colour_name]
			var shape_node = spawn_from.instantiate() as Node2D
			if shape_node:
				shape_node.set_colour(shape_colour)
				row_node.add_child(shape_node)
				shape_node.translate(offset)
				offset.x += horizontal_offset

			var new_shape = ShapeEntry.new()
			new_shape.node = shape_node
			new_shape.colour_name = shape_colour_name
			new_shape.shape_name = shape_node.shape_name
			shape_row.shapes.push_back(new_shape)
			
		scanned_bag_contents.rows.push_back(shape_row)

func _highlight_forbidden_shapes():
	var found_any = false
	for r in scanned_bag_contents.rows:
		for s in r.shapes:
			if s.colour_name == current_rule.restricted_colour_name && s.shape_name == current_rule.restricted_shape:
				found_any = true
				var highlighter_node = s.node.get_child(0) as Node2D
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
		var search_minigame : MiniGameBase = current_scanned_bag.start_minigame(self)
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
	current_rule = Rule.new()
	current_rule.restricted_colour_name = initial_restricted_colour_name
	current_rule.restricted_shape = initial_restricted_shape
	current_rule.max_num_of_shape = 0
	
	if conveyor:
		conveyor.bag_reached_bottom.connect(_on_bag_removed)
	if accept_button:
		accept_button.pressed.connect(_check_accept)
	if reject_button:
		reject_button.pressed.connect(_check_reject)
	
	if conveyor:
		timer = time_limit
		remaining_bags = number_of_bags
		bags_left_to_spawn = number_of_bags

func _on_scan_new_bag():
	_clear_shapes()
	_spawn_shapes()

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
		if conveyor.spawn_new_bag():
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
