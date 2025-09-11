class_name GameRules
extends Node

@export var initial_rule_count = 1
@export var rule_count_add_per_shift = 1
@export var max_rule_count = 4 
@export var rows_per_bag = 3
@export var shapes_per_row = 4
@export var bad_shapes_in_bag_min = 1
@export var bad_shapes_in_bag_max = 3
@export var shape_name_to_scene : Dictionary
@export var possible_colours : Dictionary

@export var score_per_safe_bag = 30
@export var score_per_searched_bag = 50
@export var penalty_per_mistake = 60
@export var out_of_time_penalty = 100
# NOTE in process of replacing this with new system - shape determines real items possible
# and extra scan needed needs to be part of real item metadata OR rule?
# eventually remove the bool once everything works with it true
@export var extra_check_items : Array[PackedScene]
@export var no_extra_check_items : Array[PackedScene]
@export var use_shape_based_items = true

class Rule:
	var restricted_shape : String
	var restricted_colour_name : String
	var restricted_item_tag : String
	var max_num_of_shape : int

func rules_match(rule_1 : Rule, rule_2 : Rule) -> bool:
	return (
			rule_1.restricted_shape == rule_2.restricted_shape &&
			rule_1.restricted_colour_name == rule_2.restricted_colour_name &&
			rule_1.max_num_of_shape == rule_2.max_num_of_shape
		)

var HACK_ui_dirty = true
var current_rules : Array[Rule]
var possible_bag_items_passing_rule : Array[ScannedShape]
var possible_bag_items_failing_rule : Array[ScannedShape]
#var item_tag_to_item_specs : Dictionary
var all_item_tags : Array[String]
var all_possible_bag_items_tagged : Array[BagItemSpec]

var shift_rules : Array[ShiftRules]

func get_shift_rules() -> ShiftRules:
	var current_shift_no = GameProgressionProto.current_shift_no
	return shift_rules[current_shift_no] if current_shift_no < shift_rules.size() else null

func get_shift_total_score() -> int:
	return GameProgressionProto.get_current_shift_results().get_total_score(self, get_shift_rules())

func shape_breaks_rule(shape : ScannedShape) -> bool:
	for rule in current_rules:
		if shape.colour_name == rule.restricted_colour_name && shape.shape_name == rule.restricted_shape:
			return true
	return false

func tag_breaks_rule(tag : String) -> bool:
	for rule in current_rules:
		if tag == rule.restricted_item_tag:
			return true
	return false

func any_tag_breaks_rule(tag_array : Array[String]) -> bool:
	for tag in tag_array:
		if tag_breaks_rule(tag):
			return true
	return false

# TODO fix and tidy all the unwanted properties here once fully moved to "real" shapes
class BagItemSpec:
	var breaks_rule  = false
	var extra_check_needed = false
	var scanned_shape_temp : ScannedShape = null
	var scanned_shape_scene : PackedScene = null
	var real_item : PackedScene = null # TODO NOT USED - use this instead of clonign the shape?
	var real_item_tags : Array[String]
	var possible_real_items : Array[PackedScene]
	var bag_section_id = 0


func generate_bag_contents_tagged(bag_breaks_rule : bool):

	if possible_bag_items_passing_rule.is_empty() || possible_bag_items_failing_rule.is_empty():
		# this means "no possible bag is valid", so we want to return null
		# meaning erroneous rather than an empty bag.
		return null
	
	# TODO for now generate the same set of random shapes/rows
	var new_bag_contents = BagContents.new()
	var num_items_in_bag = rows_per_bag * shapes_per_row
	
	var item_specs : Array[BagItemSpec]
	item_specs.resize(num_items_in_bag)
	for i in range(num_items_in_bag):
		var item_spec = BagItemSpec.new()
		item_spec.bag_section_id = i % 2
		item_specs[i] = item_spec
	
	# Determine how many, if any, items in the bag break our rule(s)	
	var num_rule_breakers
	if bag_breaks_rule:
		assert(bad_shapes_in_bag_min > 0)
		assert(bad_shapes_in_bag_min <= bad_shapes_in_bag_max)
		assert(bad_shapes_in_bag_max <= num_items_in_bag)
		num_rule_breakers = randi_range(bad_shapes_in_bag_min, bad_shapes_in_bag_max)
	else:
		num_rule_breakers = 0
	
	# Pick random items to fit the quote for rule breaking/passing items.
	for item_index in range(0, num_items_in_bag):
		var item_spec = item_specs[item_index]
		item_spec.breaks_rule = (item_index < num_rule_breakers)

		var picked_item : ScannedShape
		if item_spec.breaks_rule:
			# TODO restore extra check logic
			#item_spec.extra_check_needed = true
			picked_item = possible_bag_items_failing_rule.pick_random()
		else:
			picked_item = possible_bag_items_passing_rule.pick_random()

		assert(picked_item)
		item_spec.scanned_shape_temp = picked_item

	# Randomise the items (even if not rule-breaking, e.g. for bag_section_id)
	item_specs.shuffle()

	# Finally build the bag contents and make sure each has a "real item" in it - just a random one that matches its shape for now.
	var overall_shape_index = 0
	for row_index in range(0, rows_per_bag):
		var offset = Vector2.ZERO
		var shape_row = new_bag_contents.add_row()
		for row_shape_index in range(shapes_per_row):
			var this_shape_spec : BagItemSpec = item_specs[overall_shape_index]
			# TODO instantiate 
			var new_shape_orig : ScannedShape = this_shape_spec.scanned_shape_temp
			var new_shape_dupe : ScannedShape = new_shape_orig.clone()
			shape_row.add_child(new_shape_dupe)
			new_shape_dupe.set_owner(shape_row)
			new_shape_dupe.translate(offset)
			offset.x += new_shape_dupe.shape_width_in_scanner
			
			var section_id = this_shape_spec.bag_section_id
			new_shape_dupe.bag_section_id = section_id

			var real_appearance = new_shape_dupe.real_appearance
			#new_shape_dupe.real_appearance = real_appearance
			
			# TODO bring back the extra check here (for item that breaks rule but may or may not be legit)
			new_shape_dupe.is_legit = true # (randi() % 2 == 0)

			overall_shape_index += 1
	
	return new_bag_contents

func generate_bag_contents_abstract(bag_breaks_rule : bool, extra_check_needed : bool):

	if possible_bag_items_passing_rule.is_empty() || possible_bag_items_failing_rule.is_empty():
		# this means "no possible bag is valid", so we want to return null
		# meaning erroneous rather than an empty bag.
		return null

	var new_bag_contents = BagContents.new()
	# A random number of shapes 
	var num_shapes_in_bag = rows_per_bag * shapes_per_row
	var num_extra_check_items = 1 if extra_check_needed else 0
	
	# Set up item specs for any bag
	var item_specs : Array[BagItemSpec]
	item_specs.resize(num_shapes_in_bag)
	for i in range (num_shapes_in_bag):
		var item_spec = BagItemSpec.new()
		item_spec.bag_section_id = i % 2
		item_specs[i] = item_spec

	# set up items that break the rules, if this is needed
	if bag_breaks_rule:
		assert(bad_shapes_in_bag_min > 0 && bad_shapes_in_bag_min <= bad_shapes_in_bag_max && bad_shapes_in_bag_max <= num_shapes_in_bag)
		var num_rule_breakers = randi_range(bad_shapes_in_bag_min, bad_shapes_in_bag_max)
		for i in range(0, num_shapes_in_bag):
			var item_spec = item_specs[i]
			item_spec.breaks_rule = (i < num_rule_breakers)
			
			if not use_shape_based_items:
				if item_spec.breaks_rule and num_extra_check_items > 0 and not extra_check_items.is_empty():
					item_spec.extra_check_needed = true
					item_spec.real_item = extra_check_items.pick_random()
				#	num_extra_check_items -= 1
				elif !no_extra_check_items.is_empty():
					item_spec.real_item = no_extra_check_items.pick_random()

	# Randomise the items (even if not rule-breaking, e.g. for bag_section_id)
	item_specs.shuffle()

	# Finally build the bag contents and make sure each has a "real item" in it - just a random one that matches its shape for now.
	var overall_shape_index = 0
	for row_index in range(0, rows_per_bag):
		var offset = Vector2.ZERO
		var shape_row = new_bag_contents.add_row()
		for row_shape_index in range(shapes_per_row):
			var this_shape_spec : BagItemSpec = item_specs[overall_shape_index]
			var possible_combos = possible_bag_items_passing_rule if this_shape_spec.breaks_rule else possible_bag_items_failing_rule
			var new_shape_orig : ScannedShape = possible_combos.pick_random()
			var new_shape_dupe : ScannedShape = new_shape_orig.clone()
			shape_row.add_child(new_shape_dupe)
			new_shape_dupe.set_owner(shape_row)
			new_shape_dupe.translate(offset)
			offset.x += new_shape_dupe.shape_width_in_scanner
			
			var section_id = this_shape_spec.bag_section_id
			new_shape_dupe.bag_section_id = section_id
			
			if use_shape_based_items and not this_shape_spec.real_item:
				this_shape_spec.real_item =  new_shape_dupe.possible_real_appearances.pick_random()

			if this_shape_spec.real_item:
				var real_appearance = this_shape_spec.real_item.instantiate()
				real_appearance.set_visible(false)
				new_shape_dupe.add_child(real_appearance)
				real_appearance.set_owner(new_shape_dupe)
				new_shape_dupe.real_appearance = real_appearance
				# TGODO NEEDS FIX FOR NEW REAL_ITEM RULES
				new_shape_dupe.is_legit = (randi() % 2 == 0)

			overall_shape_index += 1
	
	return new_bag_contents


func _generate_shape_colour_combos(want_to_break_rule : bool) -> Array[ScannedShape]:
	var possible_shape_colour_combos : Array[ScannedShape]
	for possible_colour_name in possible_colours:
		for possible_shape_name in shape_name_to_scene:
			var shape_scene : PackedScene = shape_name_to_scene[possible_shape_name]
			assert(shape_scene, "Could not find mapped PackedScene for shape name '"  + possible_shape_name + "'")
			var this_shape_entry = shape_name_to_scene[possible_shape_name].instantiate() as ScannedShape
			assert(this_shape_entry, "Could not find or instantiate PackedScene for shape name '"  + possible_shape_name + "'")
			this_shape_entry.set_colour_and_name(possible_colours[possible_colour_name], possible_colour_name)
			this_shape_entry.shape_name = possible_shape_name
			if shape_breaks_rule(this_shape_entry) == want_to_break_rule:
				possible_shape_colour_combos.push_back(this_shape_entry)
	return possible_shape_colour_combos

func _generate_possible_items_for_rule(want_to_break_rule : bool) -> Array[ScannedShape]:
	var possible_items : Array[ScannedShape]
	for item_spec in all_possible_bag_items_tagged:
		if any_tag_breaks_rule(item_spec.real_item_tags) == want_to_break_rule:
			# TODO don't instnatiate here! Store the spec and instantiate when generating bag!
			var this_shape_entry = item_spec.scanned_shape_scene.instantiate() as ScannedShape
			var real_appearance = item_spec.real_item.instantiate()
			this_shape_entry.real_appearance = real_appearance
			real_appearance.set_visible(false)
			this_shape_entry.add_child(real_appearance)
			real_appearance.set_owner(this_shape_entry)	
			assert(this_shape_entry.real_appearance)
			possible_items.push_back(this_shape_entry)
	return possible_items

# TODO DEAD FUNCTION - DELETE when done with abstract rules.
func _generate_new_rule_abstract():
	# Since there's not that many possible combinations, it should be fine for now to generate them all here.
	if current_rules.size() < max_rule_count:
		var possible_rules : Array[Rule]
		for new_rule_colour in possible_colours:
			for new_rule_shape_name in shape_name_to_scene.keys():
				var new_rule = Rule.new()
				new_rule.restricted_colour_name = new_rule_colour
				new_rule.restricted_shape = new_rule_shape_name
				new_rule.max_num_of_shape = 0

				var rule_matches = func(check_rule : Rule) -> bool:
					return rules_match(new_rule, check_rule)
				
				if current_rules.any(rule_matches):
					print("rejecting existing rule: %s/%s/%d" % [new_rule.restricted_colour_name, new_rule.restricted_shape, new_rule.max_num_of_shape])
				else:
					possible_rules.push_back(new_rule)

		if possible_rules.is_empty():
			printerr("_generate_new_rule_abstract unable to find any more valid rules")
		else:
			current_rules.push_back(possible_rules.pick_random())

func _generate_new_rule_tagged():
	# Since there's not that many possible combinations, it should be fine for now to generate them all here.
	if current_rules.size() < max_rule_count:
		var possible_rules : Array[Rule]
		
		for new_rule_tag in all_item_tags:
				var new_rule = Rule.new()
				new_rule.restricted_item_tag = new_rule_tag
				new_rule.max_num_of_shape = 0

				var rule_matches = func(check_rule : Rule) -> bool:
					return rules_match(new_rule, check_rule)
				
				if current_rules.any(rule_matches):
					print("rejecting existing tag rule: %s/%d" % [new_rule.restricted_item_tag, new_rule.max_num_of_shape])
				else:
					possible_rules.push_back(new_rule)

		if possible_rules.is_empty():
			printerr("_generate_new_rule_tagged unable to find any more valid rules")
		else:
			current_rules.push_back(possible_rules.pick_random())

func _generate_possible_item_specs_tagged():
	# HACK we need to load ALL possible items. to figure out which tags are possible.
	print("_generate_possible_item_specs_tagged:")
	#item_tag_to_item_specs.clear()
	all_item_tags.clear()
	all_possible_bag_items_tagged.clear()
	
	for possible_shape_name in shape_name_to_scene:
		var shape_scene : PackedScene = shape_name_to_scene[possible_shape_name]
		var temp_shape = shape_scene.instantiate() as ScannedShape
		assert(temp_shape, "INVALID shape scene: %s" % possible_shape_name)
		if temp_shape:
			for real_appearance_scene : PackedScene in temp_shape.possible_real_appearances:
				var temp_real_appearance = real_appearance_scene.instantiate()
				if temp_real_appearance and temp_real_appearance.has_node("ItemTags"):
					var tags_node = temp_real_appearance.get_node("ItemTags")
					
					# HACK using same struct just to store the shape and item. Other values
					# aren't used because they're not in context of a rule
					var new_item_spec = BagItemSpec.new()
					new_item_spec.scanned_shape_scene = shape_scene
					new_item_spec.real_item = real_appearance_scene
				
					# TODO remove this if we don't need to build the mapping after all
					#for tag_node in tags_node.get_children():
					#	pass
						# TODO human-readable name
						#var tag_item_specs : Array[BagItemSpec]
						#if tag_node.name in all_item_tags_to_specs:
						#	tag_item_specs = all_item_tags_to_specs.get(tag_node.name)
						#else:
						#	all_item_tags_to_specs[tag_node.name] = tag_item_specs
						
						#tag_item_specs.push_back(new_item_spec)
					
					for tag_node in tags_node.get_children():
						if tag_node.name not in new_item_spec.real_item_tags:
							new_item_spec.real_item_tags.push_back(tag_node.name)
							print("ITEM_TAG: %s -> %s" % [tag_node.name, possible_shape_name])
							
						if tag_node.name not in all_item_tags:
							all_item_tags.push_back(tag_node.name)

					all_possible_bag_items_tagged.push_back(new_item_spec)

	
	#return item_tag_to_item_specs

func _ready() -> void:
	_generate_possible_item_specs_tagged()

	# Generate random rules based on the parameters
	for rule_index in range(initial_rule_count):
		_generate_new_rule_tagged()

	# Generate the shape possibilites for these rules
	if use_shape_based_items:
		possible_bag_items_passing_rule = _generate_possible_items_for_rule(true)
		possible_bag_items_failing_rule = _generate_possible_items_for_rule(false)
	else:
		possible_bag_items_passing_rule = _generate_shape_colour_combos(true)
		possible_bag_items_failing_rule = _generate_shape_colour_combos(false)
	
	# Get the per-shift rules which are in the scene as children of this node
	for child in get_children():
		if child is ShiftRules:
			shift_rules.push_back(child)
	assert(shift_rules.size() > 0, "No shift rules found!")
	GameProgressionProto.reset_shift_results()

func next_shift():
	var total_score = get_shift_total_score()
	var go_to_next_shift = total_score >= get_shift_rules().passing_score_threshold
	GameProgressionProto.reset_shift_results()

	# TODO handle end of last shift here
	# TODO split concepts of "next shift" and "next level"
	if go_to_next_shift && GameProgressionProto.current_shift_no + 1 < shift_rules.size():
		GameProgressionProto.current_shift_no += 1
		for _next_rule_num in range(rule_count_add_per_shift):
			_generate_new_rule_tagged()
