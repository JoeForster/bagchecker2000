extends GridContainer

@export var buttons : Array[Button]
@export var scanner_screen : ScannerScreen

func _on_toggled(toggled_on : bool, button : Button):
	if toggled_on:
		for check_button in buttons:
			if check_button != button:
				check_button.set_pressed_no_signal(false)
	_update_active_mode()

func _update_active_mode():
	for button in buttons:
		if button.button_pressed:
			scanner_screen.set_scan_mode(button.scan_mode)
			break

func _ready() -> void:
	assert(scanner_screen)
	for button in buttons:
		button.toggled.connect(_on_toggled.bind(button))
	_update_active_mode()
