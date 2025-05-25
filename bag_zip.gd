extends Node2D

var mouse_held = false
var zip_handle_moving = false
var dragging_mouse_pos : Vector2
var zip_next_point_pos : Vector2
var zip_colour : Color

@export var mouse_button_index = 1
@export var rotation_threshold_degrees = 20
@export var zip_move_speed = 200.0

signal on_zip_opened


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
	
	#print(event.as_text())
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == mouse_button_index and click_event.pressed:
		mouse_held = true
		print("click on " + str(click_event.button_index))


func _input(event: InputEvent) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == mouse_button_index && !click_event.pressed:
		print("click off")
		mouse_held = false

	zip_handle_moving = false
	if has_node("ZipLine"):
		if mouse_held:
			var move_event = event as InputEventMouseMotion
			if move_event:
				dragging_mouse_pos = move_event.global_position
				
				# TODO this is incredibly inefficient and I know this can be done geometrically but I'm in a hurry.
				var zip_line : Line2D = $ZipLine
				var closest_dist_sq = -1
				var first_point_pos = zip_line.get_point_position(0)
				var line_global_pos = zip_line.get_global_position()
				var closest_point : Vector2 = first_point_pos + line_global_pos
				var point_after_closest_point : Vector2 = zip_line.get_point_position(zip_line.get_point_count()-1)
				for from_point in range(0, zip_line.get_point_count()-1):
					var to_point = from_point + 1
					var from_point_pos = zip_line.get_point_position(from_point) + zip_line.get_global_position()
					var to_point_pos = zip_line.get_point_position(to_point) + zip_line.get_global_position()
					for percent in range(0, 100):
						var check_point = lerp(from_point_pos, to_point_pos, percent/100.0)
						var dist_sq = dragging_mouse_pos.distance_squared_to(check_point)
						if closest_dist_sq < 0 || dist_sq < closest_dist_sq:
							closest_point = check_point
							closest_dist_sq = dist_sq
							point_after_closest_point = to_point_pos
				
				if abs(dragging_mouse_pos.angle_to_point(point_after_closest_point)) < deg_to_rad(rotation_threshold_degrees):
					zip_handle_moving = true
					zip_next_point_pos = point_after_closest_point
					#$ZipHandle.set_global_position(closest_point)

func _ready() -> void:
	$ZipHandle.input_event.connect(_on_input_event)
	#$ZipHandle.mouse_exited.connect(_on_mouse_exited)
	zip_colour = $ZipHandle/Polygon2D.color
	
	$ZipEnd.area_shape_entered.connect(_on_zip_end_entered)

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
				zip_handle.translate(direction)
		
	else:
		zip_poly.color = zip_colour

func _process(delta: float) -> void:
	if has_node("ZipHandle"):
		_update_zip_handle(delta, $ZipHandle)
