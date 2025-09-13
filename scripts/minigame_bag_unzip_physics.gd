extends MiniGameBase

@export var open_speed = 100.0
@export var open_dist = 80.0
@export var complete_time = 1.0
@export var light_time = 1.0
@export var zips : Array[BagZip]
@export var bag_front_top : Node2D
@export var bag_front_bottom : Node2D
@export var contents_holder : Node2D
@export var item_spawn_line : Path2D
@export var tray_area : Area2D
@export var repack_button : Button
@export var repack_indicator : Circle2D
@export var item_scanner : ItemScanner

# Internal state
var forbidden_items_for_tray : Array[ScannedShape]
var spawned_all_items = false
var opening = false
var opening_section = -1
var opened_dist = 0.0
var complete_timer = -1.0
var light_timer = -1.0

func init_with_contents(game_rules : GameRules, new_bag_contents : BagContents):
	super(game_rules, new_bag_contents)
	for child in contents_holder.get_children():
		child.queue_free()
	contents_holder.add_child(bag_contents)
	bag_contents.set_owner(contents_holder)

func _ready() -> void:
	super()
	for zip in zips:
		zip.on_zip_opened.connect(_start_opening_bag)

func _on_clasp_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, clasp : BagClasp):
	var click_event = event as InputEventMouseButton
	if click_event and click_event.button_index == 1 and click_event.pressed:
		clasp.open()

func _start_opening_bag(bag_section_index: int):
	opening = true
	opening_section = bag_section_index

func _spawn_items(section_index : int):
	# take all the shapes out of the bag and spawn them so they'll fall
	item_scanner.items_needing_scan.clear()
	var has_any_left = false
	for show_row : Node2D in contents_holder.get_child(0).get_rows():
		for show_shape : ScannedShape in show_row.get_children():
			if section_index >= 0 && show_shape.bag_section_id != section_index:
				has_any_left = true
				continue # Skip item not in specified section
			
			show_row.remove_child(show_shape)
			add_child(show_shape)
			show_shape.set_owner(self)
			show_shape.set_visible(true)
			show_shape.set_process_mode(Node.PROCESS_MODE_INHERIT)
			show_shape.enable_physics()
			
			var point_index = randi_range(0, item_spawn_line.curve.get_point_count())
			var point_interp = randf()
			var spawn_point = item_spawn_line.curve.sample(point_index, point_interp)
			var spawn_point_global = item_spawn_line.to_global(spawn_point)
			show_shape.set_global_position(spawn_point_global)

			if show_shape.real_appearance:
				item_scanner.items_needing_scan.push_back(show_shape)
			if rules.item_really_breaks_rule(show_shape) and (!show_shape.real_appearance or !show_shape.is_legit):
				forbidden_items_for_tray.push_back(show_shape)

	spawned_all_items = !has_any_left

# TODO for multi-bag + check: replace this mess with a state machine & separate out
# the different bag open methods from the item check methods if it keeps getting duplicated.
func _process(delta: float) -> void:
	# #4 COMPLETING STATE: complete once timer has expired.
	if complete_timer > 0.0:
		complete_timer -= delta
		if complete_timer <= 0.0:
			complete()
	# #2 OPENING STATE: Move the bag BG a certain distance before moving to the CHECKING state
	elif opening:
		# HARD-CODED bag sections: 0 opens gradually, any others open instantly.
		if opening_section <= 0:
			bag_front_top.translate(Vector2(0, -open_speed * delta))
			bag_front_bottom.translate(Vector2(0, open_speed * delta))
			opened_dist += open_speed * delta
			if opened_dist >= open_dist:
				opening = false
				_spawn_items(opening_section)
		else:
			opening = false
			_spawn_items(opening_section)
			
	# #3 CHECKING ITEMS STATE - wait for forbidden items processing to be satisfied 
	var valid_repack = false
	if spawned_all_items && complete_timer == -1.0:
		# Assumes only items can overlap with the area (should be set in layers)
		# also only allow us to repack if we've scanned all the items that need it
		if tray_area.get_overlapping_bodies().size() == forbidden_items_for_tray.size():
			valid_repack = true
			for body in forbidden_items_for_tray:
				if body not in tray_area.get_overlapping_bodies():
					valid_repack = false
					break
	
		if light_timer > 0.0:
			light_timer -= delta
			if light_timer <= 0.0:
				light_timer = 0.0
				repack_indicator.set_color(Color.BLACK)
		
		if repack_button.is_pressed():
			if valid_repack:
				complete_timer = complete_time
				repack_indicator.set_color(Color.GREEN)
			else:
				repack_indicator.set_color(Color.RED)
			light_timer = light_time
