class_name ModToolInterfaceInputCheckBoxCollection
extends ModToolInterfaceInput
tool


export var input_options: PoolStringArray setget set_input_options

onready var check_boxes: GridContainer = $"%CheckBoxes"

var selected_options := []


func set_input_options(new_options: PoolStringArray) -> void:
	input_options = new_options

	if not check_boxes: return

	if input_options.empty():
		hide()
		return

	show()
	clear()
	for option in input_options:
		var new_check_box := CheckBox.new()
		new_check_box.text = option
		new_check_box.name = option
		check_boxes.add_child(new_check_box)
		new_check_box.connect("pressed", self, "_on_check_box_pressed", [new_check_box])


func clear() -> void:
	for check_box in check_boxes.get_children():
		check_box.free()


func set_check_box_state(tag: String, new_value: bool) -> void:
	print("set_check_box_state tag: %s new_value: %s" % [tag, new_value])
	var tag_check_box: CheckBox = check_boxes.get_node_or_null(tag)
	if tag_check_box:
		tag_check_box.pressed = new_value


func disable_all() -> void:
	for check_box in check_boxes.get_children():
		check_box.disabled = true


func enable_all() -> void:
	for check_box in check_boxes.get_children():
		check_box.disabled = false


func _on_check_box_pressed(check_box: CheckBox) -> void:
	print("Checkbox pressed: %s" % check_box.pressed)
	if check_box.pressed:
		selected_options.push_back(check_box.text)
	else:
		selected_options.erase(check_box.text)

	emit_signal("value_changed", selected_options, self)
