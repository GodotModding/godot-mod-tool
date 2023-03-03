tool
class_name InputString
extends HBoxContainer


signal input_text_changed(new_text, node)

export var is_required: bool setget set_is_required
export var key: String
export var label_text: String setget set_label_text
export var input_text: String setget set_input_text
export var input_placeholder: String setget set_input_placeholder
export(String, MULTILINE) var hint_text setget set_hint_text


func set_is_required(required: bool) -> void:
	is_required = required
	set_label_text(label_text)


func set_label_text(new_text: String) -> void:
	label_text = new_text
	$Label.text = new_text if is_required else new_text + " (optional)"


func set_input_text(new_text: String) -> void:
	input_text = new_text
	$"%Input".text = new_text


func set_input_placeholder(new_text: String) -> void:
	input_placeholder = new_text
	$"%Input".placeholder_text = new_text


func set_hint_text(new_text: String) -> void:
	hint_text = new_text
	hint_tooltip = new_text
	mouse_default_cursor_shape = CURSOR_ARROW if new_text == "" else CURSOR_HELP


func set_error_icon(icon: Texture) -> void:
	$ErrorIcon.texture = icon


func get_value() -> String:
	return $"%Input".text.strip_edges()


func show_error_if_not(condition: bool) -> bool:
	if not condition:
		$ErrorIcon.show()
	else:
		$ErrorIcon.hide()
	return condition


func _on_Input_text_changed(new_text) -> void:
	emit_signal("input_text_changed", new_text, self)
