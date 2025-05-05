extends Node2D

@export var shape_refresh_period : float = 1.0
@export var possible_shapes : Array[PackedScene]

class ShapeRow:
	var node : Node2D
	var nodes : Array[Node]

var shape_refresh_timer : float = 0
var rows : Array[ShapeRow]

func _enter_tree():
	# TEMP combine with _spawn_shapes
	for r in get_children():
		var sr = ShapeRow.new()
		sr.node = r
		for node in r.get_children():
			var shape_node = node as Node2D
			if shape_node:
				sr.nodes.push_back(shape_node)
		rows.push_back(sr)

func _clear_shapes():
	for r in rows:
		for s in r.nodes:
			s.queue_free()
	rows.clear()

func _spawn_shapes():
	if possible_shapes.is_empty():
		return

	var num_in_row = 3
	for row_node in get_children():

		var offset = Vector2.ZERO
		var shape_row = ShapeRow.new()
		shape_row.node = row_node


		for i in num_in_row:
			var spawn_from : PackedScene = possible_shapes.pick_random()
			var shape_node = spawn_from.instantiate() as Node2D
			if shape_node:
				row_node.add_child(shape_node)
				shape_node.translate(offset)
				offset.x += 200

			shape_row.nodes.push_back(shape_node)
			
		rows.push_back(shape_row)
		


func _process(delta):
	shape_refresh_timer += delta
	if (shape_refresh_timer >= shape_refresh_period):
		shape_refresh_timer -= shape_refresh_period
		_clear_shapes()
		_spawn_shapes()
