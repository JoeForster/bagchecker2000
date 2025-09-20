class_name BagItem
extends Node


# Default to BLACK to indicate not set and fall back to default scan colour for this mode
# TODO: Could make this a dictionary if there was a nice way to export the key enum to the editor...
@export var xray_colour : Color
@export var thermal_colour : Color
@export var audio_colour : Color

func get_scanned_colour(scan_mode : ScannerScreen.ITEM_SCAN_MODE, default_colour : Color) -> Color:
	var override_colour : Color
	if scan_mode == ScannerScreen.ITEM_SCAN_MODE.XRAY:
		override_colour = xray_colour
	elif scan_mode == ScannerScreen.ITEM_SCAN_MODE.THERMAL:
		override_colour = thermal_colour
	else:
		assert(scan_mode == ScannerScreen.ITEM_SCAN_MODE.AUDIO)
		override_colour = audio_colour
		
	return override_colour if override_colour else default_colour
