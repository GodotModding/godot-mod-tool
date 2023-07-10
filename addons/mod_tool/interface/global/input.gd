class_name ModToolInterfaceInput
extends HBoxContainer
tool


signal value_changed(new_value, input_node)

export var is_required: bool setget set_is_required
export var key: String
export var label_text: String setget set_label_text
export var editor_icon_name: String = "NodeWarning"
export(String, MULTILINE) var hint_text setget set_hint_text

var is_valid := true setget set_is_valid


func _ready() -> void:
	# Set up warning icons to show if a field is invalid
	set_editor_icon(editor_icon_name)


func set_is_required(required: bool) -> void:
	is_required = required
	set_label_text(label_text)


func set_is_valid(new_is_valid: bool) -> void:
	is_valid = new_is_valid
	show_error_if_not(is_valid)


func set_label_text(new_text: String) -> void:
	label_text = new_text
	$Label.text = new_text if is_required else new_text + " (optional)"


func set_hint_text(new_text: String) -> void:
	hint_text = new_text
	hint_tooltip = new_text
	mouse_default_cursor_shape = CURSOR_ARROW if new_text == "" else CURSOR_HELP


func set_editor_icon(icon_name: String) -> void:
	var mod_tool_store: ModToolStore = get_node_or_null("/root/ModToolStore")

	if icon_name and mod_tool_store:
		set_error_icon(mod_tool_store.base_theme.get_icon(icon_name, "EditorIcons"))


func set_error_icon(icon: Texture) -> void:
	$"%ErrorIcon".texture = icon


func show_error_if_not(condition: bool) -> void:
	if not condition:
		$"%ErrorIcon".self_modulate = Color.white
	else:
		$"%ErrorIcon".self_modulate = Color.transparent


func validate(_condition: bool) -> bool:
	printerr("Implement a validation method")
	return false

