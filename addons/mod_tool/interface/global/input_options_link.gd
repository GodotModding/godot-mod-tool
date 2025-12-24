tool
class_name ModToolInterfaceInputOptionsWithButton
extends ModToolInterfaceInput


signal button_pressed
signal left_value_changed(new_value, input_node)
signal right_value_changed(new_value, input_node)

export var label_text_left_options: String
export var label_text_right_options: String
export var input_options_left: PoolStringArray setget set_input_options_left
export var input_options_right: PoolStringArray setget set_input_options_right

onready var input_left: OptionButton = $"%InputLeft"
onready var input_right: OptionButton = $"%InputRight"
onready var button: Button = $"%Button"


func set_button_disabled(state: bool) -> void:
	button.disabled = state


func set_input_disabled_left(state: bool) -> void:
	input_left.disabled = state


func set_input_disabled_right(state: bool) -> void:
	input_right.disabled = state


func set_input_options_left(new_options: PoolStringArray) -> void:
	input_options_left = new_options
	if input_left:
		set_input_options(input_left, input_options_left)


func set_input_options_right(new_options: PoolStringArray) -> void:
	input_options_right = new_options
	if input_right:
		set_input_options(input_right, input_options_right)


func set_input_options(node: OptionButton, options: PoolStringArray) -> void:
	node.clear()
	for option in options:
		node.add_item(option)
	node.select(0)


func select_left(option: String) -> void:
	var index := input_options_left.find(option)
	input_left.select(index)
	emit_signal("left_value_changed", get_input_string_left(), self)


func select_right(option: String) -> void:
	var index := input_options_right.find(option)
	input_right.select(index)
	emit_signal("right_value_changed", get_input_string_right(), self)


func get_input_value_left() -> int:
	return input_left.get_selected_id()


func get_input_value_right() -> int:
	return input_right.get_selected_id()


func get_input_string_left() -> String:
	if get_input_value_left() == -1:
		return ""
	return input_options_left[get_input_value_left()]


func get_input_string_right() -> String:
	if get_input_value_right() == -1:
		return ""
	return input_options_right[get_input_value_right()]


func validate(condition: bool) -> bool:
	# Check if input is required and empty
	if is_required:
		if get_input_value_left() == -1 or get_input_value_right() == -1:
			is_valid = false
			return false

	# Invalidate field if the condition is not met
	is_valid = condition
	return is_valid


func _on_Button_pressed() -> void:
	emit_signal("button_pressed")


func _on_InputLeft_item_selected(index: int) -> void:
	emit_signal("left_value_changed", get_input_string_left(), self)


func _on_InputRight_item_selected(index: int) -> void:
	emit_signal("right_value_changed", get_input_string_right(), self)
