extends MiniGameBase

@export var open_speed = 100.0
@export var open_dist = 240.0
@export var complete_time = 1.0
@export var clasps : Array[BagClasp]
@export var contents_holder : Node2D
@export var item_spawn_line : Path2D
@export var tray_area : Area2D

var complete_timer = -1.0

func init_with_contents(game_rules : GameRules, new_bag_contents : BagContents):
	super(game_rules, new_bag_contents)
	for child in contents_holder.get_children():
		child.queue_free()
	contents_holder.add_child(bag_contents)
	bag_contents.set_owner(contents_holder)

func _ready() -> void:
	super()
	for clasp in clasps:
		var turner = clasp.get_node("ClaspTurner")
		turner.input_event.connect(_on_clasp_input_event.bind(clasp))

func _on_clasp_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, clasp : BagClasp):
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == 1 and click_event.pressed:
		clasp.open()

# TODO replace this mess with a state machine
var forbidden_items_for_tray : Array[ScannedShape]
var spawned_items = false

func _process(delta: float) -> void:
	if complete_timer > 0.0:
		complete_timer -= delta
		if complete_timer <= 0.0:
			complete()
	else:
		var has_unopened_clasps = false
		for clasp in clasps:
			if !clasp.is_opened:
				has_unopened_clasps = true
				break
				
		if !has_unopened_clasps and !spawned_items:
			# take all the shapes out of the bag and spawn them so they'll fall
			for show_row : Node2D in contents_holder.get_child(0).get_rows():
				for show_shape : ScannedShape in show_row.get_children():
					show_row.remove_child(show_shape)
					add_sibling(show_shape)
					show_shape.set_visible(true)
					show_shape.set_process_mode(Node.PROCESS_MODE_INHERIT)
					show_shape.enable_physics()
					
					var point_index = randi_range(0, item_spawn_line.curve.get_point_count())
					var point_interp = randf()
					var spawn_point = item_spawn_line.curve.sample(point_index, point_interp)
					var spawn_point_global = item_spawn_line.to_global(spawn_point)
					show_shape.set_global_position(spawn_point_global)
					if rules.shape_breaks_rule(show_shape):
						forbidden_items_for_tray.push_back(show_shape)
			spawned_items = true
			
		if spawned_items && complete_timer == -1.0:
			# Assumes only items can overlap with the area (should be set in layers)
			if tray_area.get_overlapping_bodies().size() == forbidden_items_for_tray.size():
				var all_correct_items_in_tray = true
				for body in forbidden_items_for_tray:
					if body not in tray_area.get_overlapping_bodies():
						all_correct_items_in_tray = false
						break
				if all_correct_items_in_tray:
					complete_timer = complete_time
