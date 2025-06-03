class_name BagContents
extends Node2D

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
