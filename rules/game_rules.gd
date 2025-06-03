class_name GameRules
extends Node

@export var initial_rule_count = 2
@export var rows_per_bag = 3
@export var shapes_per_row = 4
@export var bad_shapes_in_bag_min = 1
@export var bad_shapes_in_bag_max = 3
@export var shape_name_to_scene : Dictionary
@export var possible_colours : Dictionary

class Rule:
	var restricted_shape : String
	var restricted_colour_name : String
	var max_num_of_shape : int

var current_rules : Array[Rule]
var possible_shape_colour_combos_passing_rule : Array[ScannedShape]
var possible_shape_colour_combos_failing_rule : Array[ScannedShape]

func shape_breaks_rule(shape : ScannedShape) -> bool:
	for rule in current_rules:
		if shape.colour_name == rule.restricted_colour_name && shape.shape_name == rule.restricted_shape:
			return true
	return false


func generate_bag_contents(breaks_rule : bool):
	if possible_shape_colour_combos_passing_rule.is_empty() || possible_shape_colour_combos_failing_rule.is_empty():
		# this means "no possible bag is valid", so we want to return null
		# meaning erroneous rather than an empty bag.
		return null

	var new_bag_contents = BagContents.new()
	# A random number of shapes 
	var num_shapes_in_bag = rows_per_bag * shapes_per_row
	var rule_breaking_shapes : Array[bool]
	if breaks_rule:
		assert(bad_shapes_in_bag_min > 0 && bad_shapes_in_bag_min <= bad_shapes_in_bag_max && bad_shapes_in_bag_max <= num_shapes_in_bag)
		var num_rule_breakers = randi_range(bad_shapes_in_bag_min, bad_shapes_in_bag_max)
		for i in range(0, num_shapes_in_bag):
			rule_breaking_shapes.push_back(i < num_rule_breakers)
		rule_breaking_shapes.shuffle()
	else:
		for i in range(0, num_shapes_in_bag):
			rule_breaking_shapes.push_back(false)

	var overall_shape_index = 0
	for row_index in range(0, rows_per_bag):
		var offset = Vector2.ZERO
		var shape_row = new_bag_contents.add_row()
		for row_shape_index in range(shapes_per_row):
			var shape_breaks_rule = rule_breaking_shapes[overall_shape_index]
			var possible_combos = possible_shape_colour_combos_passing_rule if shape_breaks_rule else possible_shape_colour_combos_failing_rule
			var new_shape_orig : ScannedShape = possible_combos.pick_random()
			var new_shape_dupe = new_shape_orig.clone()
			shape_row.add_child(new_shape_dupe)
			new_shape_dupe.set_owner(shape_row)
			new_shape_dupe.translate(offset)
			offset.x += new_shape_dupe.shape_width_in_scanner
			
			overall_shape_index += 1
	
	return new_bag_contents


func _generate_shape_colour_combos(want_to_break_rule : bool) -> Array[ScannedShape]:
	var possible_shape_colour_combos : Array[ScannedShape]
	for possible_colour_name in possible_colours:
		for possible_shape_name in shape_name_to_scene:
			var shape_scene : PackedScene = shape_name_to_scene[possible_shape_name]
			assert(shape_scene, "Could not find mapped PackedScene for shape name '"  + possible_shape_name + "'")
			var this_shape_entry = shape_name_to_scene[possible_shape_name].instantiate() as ScannedShape
			assert(this_shape_entry, "Could not find instantiate PackedScene for shape name '"  + possible_shape_name + "'")
			this_shape_entry.set_colour_and_name(possible_colours[possible_colour_name], possible_colour_name)
			this_shape_entry.shape_name = possible_shape_name
			if shape_breaks_rule(this_shape_entry) == want_to_break_rule:
				possible_shape_colour_combos.push_back(this_shape_entry)
	return possible_shape_colour_combos

func _ready() -> void:
	# Generate random rules based on the parameters
	for rule_index in range(initial_rule_count):
		var new_rule = Rule.new()
		new_rule.restricted_colour_name = possible_colours.keys().pick_random()
		new_rule.restricted_shape = shape_name_to_scene.keys().pick_random()
		new_rule.max_num_of_shape = 0
		current_rules.push_back(new_rule)

	# Generate the shape possibilites for these rules
	possible_shape_colour_combos_passing_rule = _generate_shape_colour_combos(true)
	possible_shape_colour_combos_failing_rule = _generate_shape_colour_combos(false)
	
