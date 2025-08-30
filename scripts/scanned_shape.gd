# TODO this is both the scanned displayed shape and a physics object
# should be split or at least renamed
class_name ScannedShape
extends RigidBody2D

@export var shape_name : String
@export var shape_node : Node2D
@export var shape_width_in_scanner = 100.0
@export var scanned_appearance : Node2D
@export var real_appearance : Node2D
@export var bag_section_id = 0
@export var is_legit = true

@export var rotate_upright_rate = PI * 1.5

# NOTE these won't be copied when added to a minigame via clone so should only be runtime values!
var colour : Color
var colour_name : String
var mouse_dragging = false
var physics_enabled = false

# Internal hard-code settings

enum ITEM_DRAG_MODE
{
	FORCE_POS,
	THRUST,
	MOVE_AND_COLLIDE
}

var item_drag_mode = ITEM_DRAG_MODE.FORCE_POS
var move_and_collide_speed = 100.0

func enable_physics():
	if !physics_enabled:
		freeze = false
		freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		input_event.connect(_on_input_event)
		if real_appearance:
			scanned_appearance.set_visible(false)
			real_appearance.set_visible(true)
			# HACK: Assume we have a polygon collision and change it to match
			# the "real" object since it is otherwise pure visual better would
			# be to separate the real from the scanned object in code,
			# but big refactor..
			var poly = real_appearance.get_node_or_null("OutlinePolygon")
			var collision = get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
			assert(poly and collision)
			if poly and collision:
				collision.polygon = poly.polygon
			real_appearance.scale = Vector2.ONE
			
		physics_enabled = true
		

func set_colour_and_name(new_colour : Color, new_colour_name: String):
	shape_node.set_color(new_colour)
	colour = new_colour
	colour_name = new_colour_name

func clone():
	# HACK workaround for issue with real_appearance, doesn't work with DUPLICATE_INSTANTIATION for some reasion?
	var new_node = duplicate(DUPLICATE_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS)
	new_node.set_colour_and_name(colour, colour_name)
	return new_node

func set_highlighter_visible(value : bool):
	$Highlighter.set_visible(value)

func is_highlighted() -> bool:
	return $Highlighter.is_visible()

# TODO HACK The below is probably not the nicest way to handle input here...
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == 1 and click_event.pressed:
		mouse_dragging = true
				

func _input(event: InputEvent) -> void:
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == 1 && !click_event.pressed:
		mouse_dragging = false

func _physics_process_pickup_force_pos(delta: float) -> void:
	freeze = mouse_dragging
	if mouse_dragging:
		var drag_offset = get_global_position() - $DragPoint.get_global_position()
		set_global_position(get_global_mouse_position() + drag_offset)
		var rotate_rate = rotate_upright_rate * delta
		var rotate_diff = 0.0 - rotation
		rotate(rotate_diff if rotate_diff < rotate_rate else rotate_rate)
	
func _physics_process_pickup_thrust(_delta: float) -> void:
	if mouse_dragging:
		# TODO this can be simplified
		gravity_scale = 0.0
		var drag_offset = get_global_position() - $DragPoint.get_global_position()
		var target_position_global = get_global_mouse_position() + drag_offset
		var to_target_position : Vector2 = target_position_global - get_global_position()
		# TODO for stability we need to do some maths here to figure out the ideal force once close to the target so it doesn't overshoot
		if to_target_position.length() > 100.0:
			apply_force(to_target_position.normalized() * 5000.0)
	else:
		gravity_scale = 1.0

func _physics_process_pickup_move_and_collide(delta: float) -> void:
	if mouse_dragging:
		# TODO this can be simplified
		gravity_scale = 0.0
		var drag_offset = get_global_position() - $DragPoint.get_global_position()
		var target_position_global = get_global_mouse_position() + drag_offset
		var to_target_position : Vector2 = target_position_global - get_global_position()
		
		# TODO for stability we need to do some maths here to figure out the ideal force once close to the target so it doesn't overshoot
		
		var move_vector = to_target_position
		var move_amount_max = move_and_collide_speed * delta
		if move_vector.length() > move_amount_max:
			move_vector = move_vector.normalized() * move_amount_max
		move_and_collide(move_vector)
			
			
	else:
		gravity_scale = 1.0

func _physics_process(delta: float) -> void:
	# Method 1: freeze and force it to the mouse position.
	# TODO slowly rotate to upright
	if physics_enabled:
		if item_drag_mode == ITEM_DRAG_MODE.FORCE_POS:
			_physics_process_pickup_force_pos(delta)
		elif item_drag_mode == ITEM_DRAG_MODE.THRUST:
			_physics_process_pickup_thrust(delta)
		elif item_drag_mode == ITEM_DRAG_MODE.MOVE_AND_COLLIDE:
			_physics_process_pickup_move_and_collide(delta)

			
