extends MiniGameBase

@export var open_speed = 100.0
@export var open_dist = 240.0
@export var complete_time = 1.0
@export var zip : BagZip
@export var bag_front_top : Node2D
@export var bag_front_bottom : Node2D
@export var contents_holder : Node2D

var opening = false
var opened_dist = 0.0
var complete_timer = -1.0

func init_with_contents(game_rules : GameRules, new_bag_contents : BagContents):
	super(game_rules, new_bag_contents)
	for child in contents_holder.get_children():
		child.queue_free()
	contents_holder.add_child(bag_contents)
	bag_contents.set_owner(contents_holder)

func _start_opening_bag():
	opening = true
	var offset = Vector2.ZERO
	# HACK
	for show_row : Node2D in contents_holder.get_child(0).get_rows():
		show_row.set_position(offset)
		show_row.set_visible(true)
		offset.y += 200
		
	for row in bag_contents.get_rows():
		for shape : ScannedShape in row.get_children():
			shape.input_event.connect(_on_shape_input_event.bind(shape))

func _ready() -> void:
	super()
	zip.on_zip_opened.connect(_start_opening_bag)

func _all_rule_breakers_marked() -> bool:
	for row in bag_contents.get_rows():
		for shape : ScannedShape in row.get_children():
			if rules.shape_breaks_rule(shape) && !shape.is_highlighted():
				return false
	return true

func _on_shape_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, shape : ScannedShape):
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == 1 and click_event.pressed:
		if rules.shape_breaks_rule(shape):
			shape.set_highlighter_visible(true)
			
		if _all_rule_breakers_marked() && complete_timer == -1.0:
			complete_timer = complete_time

func _process(delta: float) -> void:
	if opening:
		bag_front_top.translate(Vector2(0, -open_speed * delta))
		bag_front_bottom.translate(Vector2(0, open_speed * delta))
		opened_dist += open_speed * delta
		if opened_dist >= open_dist:
			opening = false
			
	if complete_timer > 0.0:
		complete_timer -= delta
		if complete_timer <= 0.0:
			complete()
