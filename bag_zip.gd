extends Node2D

var mouse_held = false
var zip_colour : Color

signal on_zip_opened

func get_closest_point_along_zip(current_point : Vector2):
	# TODO this is incredibly inefficient and I know this can be done geometrically but I'm in a hurry.
	var zip_line : Line2D = $ZipLine
	var closest_dist_sq = -1
	var first_point_pos = zip_line.get_point_position(0)
	var line_global_pos = zip_line.get_global_position()
	var closest_point : Vector2 = first_point_pos + line_global_pos
	for from_point in range(0, zip_line.get_point_count()-1):
		var to_point = from_point + 1
		var from_point_pos = zip_line.get_point_position(from_point) + zip_line.get_global_position()
		var to_point_pos = zip_line.get_point_position(to_point) + zip_line.get_global_position()
		for percent in range(0, 100):
			var check_point = lerp(from_point_pos, to_point_pos, percent/100.0)
			var dist_sq = current_point.distance_squared_to(check_point)
			if closest_dist_sq < 0 || dist_sq < closest_dist_sq:
				closest_point = check_point
				closest_dist_sq = dist_sq
	#print(closest_point)
	return closest_point

func _on_mouse_exited() -> void:
	mouse_held = false

func _on_zip_reached_end() -> void:
	$ZipHandle.queue_free()
	on_zip_opened.emit()
	
func _on_zip_end_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area == $ZipHandle:
		_on_zip_reached_end()
	
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# TODO HACK this is probably not the nicest way to handle input in godot...
	
	print(event.as_text())
	var click_event = event as InputEventMouseButton
	if click_event:
		mouse_held = click_event.pressed

	if mouse_held:
		var move_event = event as InputEventMouseMotion
		if move_event:
			var mouse_pos = move_event.global_position
			var pos_along_zip = get_closest_point_along_zip(mouse_pos)
			$ZipHandle.set_global_position(pos_along_zip)
				
func _ready() -> void:
	$ZipHandle.input_event.connect(_on_input_event)
	#$ZipHandle.mouse_exited.connect(_on_mouse_exited)
	zip_colour = $ZipHandle/Polygon2D.color
	
	$ZipEnd.area_shape_entered.connect(_on_zip_end_entered)
	
func _process(delta: float) -> void:
	if has_node("ZipHandle"):
		if mouse_held:
			$ZipHandle/Polygon2D.color = Color.WHITE
		else:
			$ZipHandle/Polygon2D.color = zip_colour
