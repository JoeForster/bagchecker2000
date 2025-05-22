extends Node2D

# Game rules
@export var shape_refresh_period = 4.0
@export var horizontal_offset = 200.0
@export var possible_shapes : Array[PackedScene]
@export var possible_colours : Dictionary
@export var initial_restricted_shape : String
@export var initial_restricted_colour_name : String
@export var initial_max_num_of_shape : int

# UI Elements
@export var timer_label : Label
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

class Rule:
	var restricted_shape : String
	var restricted_colour_name : String
	var max_num_of_shape : int

# Game state
var shape_refresh_timer : float = 0
var rows : Array[ShapeRow]
var num_failures = 0
var num_successes = 0
var current_rule : Rule

func clear_shapes():
	for r in rows:
		for s in r.shapes:
			s.node.queue_free()
	rows.clear()

func spawn_shapes():
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
			
		rows.push_back(shape_row)

func highlight_forbidden_shapes():
	var found_any = false
	for r in rows:
		for s in r.shapes:
			if s.colour_name == current_rule.restricted_colour_name && s.shape_name == current_rule.restricted_shape:
				found_any = true
				var highlighter_node = s.node.get_child(0) as Node2D
				if highlighter_node:
					highlighter_node.visible = true
	return found_any

func check_accept():
	if highlight_forbidden_shapes():
		num_failures += 1
	else:
		num_successes += 1
	accept_button.disabled = true
	reject_button.disabled = true

func check_reject():
	if highlight_forbidden_shapes():
		num_successes += 1
	else:
		num_failures += 1
	accept_button.disabled = true
	reject_button.disabled = true

func update_ui():
	if timer_label:
		timer_label.text = str(shape_refresh_timer).pad_decimals(2).replace(".", ":")
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


func _ready():
	current_rule = Rule.new()
	current_rule.restricted_colour_name = initial_restricted_colour_name
	current_rule.restricted_shape = initial_restricted_shape
	current_rule.max_num_of_shape = 0
	
	if accept_button:
		accept_button.pressed.connect(check_accept)
	if reject_button:
		reject_button.pressed.connect(check_reject)

var first_turn = true

func _process(delta):
	shape_refresh_timer -= delta
	if (shape_refresh_timer <= 0):
		# HACK Force accept if no guess made on first
		if !first_turn && !accept_button.disabled:
			check_accept()
		first_turn = false
		
		shape_refresh_timer = shape_refresh_period
		clear_shapes()
		spawn_shapes()

		accept_button.disabled = false
		reject_button.disabled = false


	update_ui()
