class_name MiniGameBase
extends Node2D

signal on_completed

func complete():
	on_completed.emit()
	queue_free()
	
func _init_with_contents(scanner : ScannerScreen):
	pass#%BagBG/Zip.on_zip_opened.connect(_open_bag)
	
# TODO need to split this off into the subclass
var opening = false
var opened_dist = 0.0
@export var open_speed = 40.0
@export var open_dist = 200.0
@export var zip : Node2D
@export var bag_front_top : Node2D
@export var bag_front_bottom : Node2D

func _open_bag():
	opening = true

func _ready() -> void:
	zip.on_zip_opened.connect(_open_bag)

func _process(delta: float) -> void:
	if opening:
		bag_front_top.translate(Vector2(0, -open_speed * delta))
		bag_front_bottom.translate(Vector2(0, open_speed * delta))
		opened_dist += open_speed * delta
		if opened_dist >= open_dist:
			complete()
