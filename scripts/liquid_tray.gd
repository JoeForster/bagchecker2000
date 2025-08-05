extends StaticBody2D
class_name ItemScanner

@export var lever : ScannerLever
@export var scanner_area : Area2D
@export var indicator_light : Circle2D

var items_needing_scan : Array[ScannedShape]

func _process(delta: float) -> void:
	if indicator_light:
		if lever and lever.is_lever_at_bottom():
			var new_colour = Color.BLACK
			for body in scanner_area.get_overlapping_bodies():
				var item_body = body as ScannedShape
				if item_body.is_legit:
					new_colour = Color.GREEN
				else:
					new_colour = Color.RED
				
				var found_index = items_needing_scan.find(item_body)
				if found_index != -1:
					items_needing_scan.remove_at(found_index)

				break # assume only one item can fit in the scanner
			indicator_light.set_color(new_colour)
