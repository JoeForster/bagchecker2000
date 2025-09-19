extends VBoxContainer

@export var buttons : Array[Button]

func _on_toggled(toggled_on : bool, button : Button):
	if toggled_on:
		for check_button in buttons:
			if check_button != button:
				check_button.set_pressed_no_signal(false)

func _ready() -> void:
	for button in buttons:
		button.toggled.connect(_on_toggled.bind(button))
