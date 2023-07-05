class_name ModToolInterfaceInputString
extends ModToolInterfaceInput
tool


export var input_text: String setget set_input_text
export var input_placeholder: String setget set_input_placeholder


func set_input_text(new_text: String) -> void:
	input_text = new_text
	$"%Input".text = new_text
	emit_signal("value_changed", new_text, self)


func set_input_placeholder(new_text: String) -> void:
	input_placeholder = new_text
	$"%Input".placeholder_text = new_text


func get_input_value() -> String:
	return $"%Input".text.strip_edges()


# Gets the values of a comma separated string as an Array,
# strips any white space contained in this values.
func get_input_as_array_from_comma_separated_string() -> Array:
	var string_split := get_input_value().split(",", false)
	var array := []

	for string in string_split:
		array.append(string.strip_edges())

	return array


func validate(condition: bool) -> bool:
	# Check if input is required and empty
	if is_required and get_input_value() == "":
		is_valid = false
		return false

	# Invalidate field if the condition is not met
	self.is_valid = condition
	return is_valid


func emit_value_changed() -> void:
	emit_signal("value_changed", get_input_value(), self)


func _on_Input_text_changed(new_text: String) -> void:
	emit_value_changed()



