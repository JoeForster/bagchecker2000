class_name BagZip
extends Node2D

var mouse_held = false
var zip_handle_moving = false
var dragging_mouse_pos : Vector2
var zip_next_point_pos : Vector2
var zip_colour : Color

@export var zip_colour_unheld : Color
@export var zip_colour_dragging_success : Color
@export var zip_colour_dragging_failure : Color

@export var mouse_button_index = 1
@export var rotation_threshold_degrees = 10.0
@export var pull_max_distance = 250.0
@export var zip_move_speed = 200.0
@export var zip_line_variance = 100.0
@export var bag_front_top : Polygon2D
@export var bag_front_bottom : Polygon2D

signal on_zip_opened


func _on_zip_reached_end() -> void:
	$ZipHandle.queue_free()
	$ZipLine.queue_free()
	on_zip_opened.emit()
	
func _on_zip_end_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if has_node("ZipHandle") && area == $ZipHandle:
		_on_zip_reached_end()

func _on_mouse_move_with_zip(_mouse_event : InputEventMouseMotion):
	dragging_mouse_pos = get_global_mouse_position()
	# Basic idea here: determine where along the line the zip handle is, and where the 
	# next point along the zip should be. Use that to determine th e drag angle
	# for rotating the angle and deciding whether to move it in _update_zip_handle
	# TODO inefficient and I know this can be done geometrically but I'm in a hurry.
	var zip_line : Line2D = $ZipLine
	var zip_handle : Node2D = $ZipHandle
	var closest_dist_sq = -1
	var point_after_closest_point_to_handle : Vector2 = to_global(zip_line.get_point_position(zip_line.get_point_count()-1))
	var zip_handle_pos = zip_handle.get_global_position()
	for from_point in range(0, zip_line.get_point_count()-1):
		var to_point = from_point + 1
		var from_point_pos = zip_line.to_global(zip_line.get_point_position(from_point))
		var to_point_pos = zip_line.to_global(zip_line.get_point_position(to_point))
		for percent in range(0, 100):
			var check_point = lerp(from_point_pos, to_point_pos, percent/100.0)
			var dist_sq = zip_handle_pos.distance_squared_to(check_point)
			if closest_dist_sq < 0 || dist_sq < closest_dist_sq:
				closest_dist_sq = dist_sq
				point_after_closest_point_to_handle = to_point_pos
	
	# Determine if the angle is in threshold to "drag" the zip along
	var zip_to_mouse = dragging_mouse_pos - zip_handle_pos
	var zip_to_next_point = point_after_closest_point_to_handle - zip_handle_pos
	var drag_angle = zip_to_mouse.angle_to(zip_to_next_point)
	var drag_distance = zip_to_mouse.length()
	if abs(drag_angle) < deg_to_rad(rotation_threshold_degrees) && (pull_max_distance < 0.0 || drag_distance < pull_max_distance):
		zip_handle_moving = true

	zip_next_point_pos = point_after_closest_point_to_handle

func _update_zip_handle(delta: float, zip_handle: Area2D):
	var zip_poly = zip_handle.get_node("Polygon2D")
	if mouse_held:
		zip_poly.color = Color.WHITE
		var to_rotate = zip_handle.get_angle_to(dragging_mouse_pos)
		zip_handle.rotate(to_rotate)
		if zip_handle_moving:
			var direction = zip_next_point_pos - zip_handle.get_global_position()
			if !direction.is_zero_approx():
				direction = direction.normalized() * zip_move_speed * delta
				zip_handle.global_translate(direction)
				
			zip_poly.color = zip_colour_dragging_success
		else:
			zip_poly.color = zip_colour_dragging_failure
	else:
		zip_poly.color = zip_colour_unheld

# TODO HACK The below is probably not the nicest way to handle input here...
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == mouse_button_index and click_event.pressed:
		mouse_held = true

func _input(event: InputEvent) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == mouse_button_index && !click_event.pressed:
		mouse_held = false

	zip_handle_moving = false
	if mouse_held and has_node("ZipLine") and has_node("ZipHandle"):
		var move_event = event as InputEventMouseMotion
		if move_event:
			_on_mouse_move_with_zip(move_event)

func _randomise_zip() -> void:
	var zip_line : Line2D = $ZipLine
	var zip_handle : Node2D = $ZipHandle
	
	var bfb_polygon = bag_front_bottom.get_polygon()
	var bft_polygon = bag_front_top.get_polygon()
	
	for point_index in range(zip_line.get_point_count()):
		var point_pos = zip_line.get_point_position(point_index)
		var y_random_delta = randf_range(-zip_line_variance, zip_line_variance)
		point_pos.y += y_random_delta
		zip_line.set_point_position(point_index, point_pos)
		if point_index == 0:
			zip_handle.position.y += y_random_delta
		for poly in [bfb_polygon, bft_polygon]:
			var poly_point = poly.get(point_index)
			poly_point.y += y_random_delta
			poly.set(point_index, poly_point)

	bag_front_bottom.set_polygon(bfb_polygon)
	bag_front_top.set_polygon(bft_polygon)

func _ready() -> void:
	$ZipHandle.input_event.connect(_on_input_event)
	zip_colour = $ZipHandle/Polygon2D.color
	
	$ZipEnd.area_shape_entered.connect(_on_zip_end_entered)
	
	if zip_line_variance > 0.0:
		_randomise_zip()

func _process(delta: float) -> void:
	if has_node("ZipHandle"):
		_update_zip_handle(delta, $ZipHandle)
