class_name BagContents
extends Node2D

# TODO tidy to encapsulate all these rules (just make them members of the bag for now?)
func generate_random_contents(breaks_rule : bool, possible_shape_colour_combos_passing_rule : Array[ScannedShape], possible_shape_colour_combos_failing_rule : Array[ScannedShape], bad_shapes_in_bag_min : int, bad_shapes_in_bag_max: int, num_rows : int, num_shapes_per_row : int):
	if possible_shape_colour_combos_passing_rule.is_empty() || possible_shape_colour_combos_failing_rule.is_empty():
		# this means "no possible bag is valid", so we want to return null
		# meaning erroneous rather than an empty bag.
		return null

	var new_bag_contents = BagContents.new()
	# A random number of shapes 
	var num_shapes_in_bag = num_rows * num_shapes_per_row
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
	for row_index in range(0, num_rows):
		var offset = Vector2.ZERO
		var shape_row = new_bag_contents.add_row()
		for row_shape_index in range(num_shapes_per_row):
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

func add_row() -> Node2D:
	var num_rows = get_child_count()
	var new_row = Node2D.new()
	new_row.set_visible(false)
	new_row.name = "Row " + str(num_rows+1)
	add_child(new_row)
	new_row.set_owner(self)
	return new_row

func get_rows():
	return get_children()

func is_empty():
	return get_child_count() == 0

# TODO We need to manually clone here because the shapes contain variables
# that won't get copied via duplicate, but we need a copy for the screen.
# maybe it'd be better to split concepts of ScannedShape from ShapeInBag 
# and make this process the "scanning" that creates ScannedShapes rather than
# cloning secret shapes within the bag..
func clone():
	var new_contents = BagContents.new()
	for row in get_rows():
		var new_row = new_contents.add_row()
		for shape : ScannedShape in row.get_children():
			var shape_clone = shape.clone()
			new_row.add_child(shape_clone)
	return new_contents
