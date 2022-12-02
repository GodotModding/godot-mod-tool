# https://github.com/godotengine/godot-demo-projects/blob/3.4-b0d4a7c/gui/input_mapping/ActionRemapButton.gd

extends Button

var action = "start_game"

func _ready():
	assert(InputMap.has_action(action))
	set_process_unhandled_key_input(false)
	display_current_key()


func _toggled(button_pressed):
	set_process_unhandled_key_input(button_pressed)
	if button_pressed:
		text = " "
		release_focus()
	else:
		display_current_key()


func _unhandled_key_input(event):
	# Note that you can use the _input callback instead, especially if
	# you want to work with gamepads.
	if(event.pressed || event.alt_pressed || event.ctrl_pressed || event.meta_pressed || event.shift_pressed):
		remap_action_to(event)


func remap_action_to(event):
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	text = event.as_text()


func display_current_key():
	var current_key = InputMap.action_get_events(action)[0].as_text()
	text = current_key
