extends MiniGameBase

@export var open_speed = 60.0
@export var open_dist = 200.0
@export var zip : BagZip
@export var bag_front_top : Node2D
@export var bag_front_bottom : Node2D
@export var contents_holder : Node2D

var opening = false
var opened_dist = 0.0

func init_with_contents(new_bag_contents : BagContents):
	super(new_bag_contents)
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

func _ready() -> void:
	super()
	zip.on_zip_opened.connect(_start_opening_bag)

func _process(delta: float) -> void:
	if opening:
		bag_front_top.translate(Vector2(0, -open_speed * delta))
		bag_front_bottom.translate(Vector2(0, open_speed * delta))
		opened_dist += open_speed * delta
		if opened_dist >= open_dist:
			opening = false
			# TEMP selection minigame goes here, complete when selected
			complete()
