tool
extends Control


# passed from the EditorPlugin
var editor_interface: EditorInterface setget set_editor_interface

var tab_parent_bottom_panel: PanelContainer
var log_richtext_label: RichTextLabel
var log_output_dock_button: ToolButton

onready var popup := $"%Popup"
onready var create_mod := $"%CreateMod"
onready var label_output := $"%Output"
onready var mod_id := $"%ModId"


func _ready() -> void:
	tab_parent_bottom_panel = get_parent().get_parent() as PanelContainer

	ModToolStore.label_output = label_output

	_load_manifest()
	_is_manifest_valid()
	_update_ui()

	get_log_nodes()


func set_editor_interface(interface: EditorInterface) -> void:
	editor_interface = interface
	ModToolStore.base_theme = editor_interface.get_base_control().theme
	ModToolStore.editor_file_system = editor_interface.get_resource_filesystem()

	$TabContainer.add_stylebox_override("panel", ModToolStore.base_theme.get_stylebox("DebuggerPanel", "EditorStyles"))

	# set up warning icons to show if a field is invalid
	for node in $"TabContainer/Mod Manifest/ScrollContainer/VBox".get_children():
		if node.has_method("set_error_icon"):
			node.set_error_icon(ModToolStore.base_theme.get_icon("NodeWarning", "EditorIcons"))

	ModToolStore.label_output = label_output

	$"%ConfigEditor".editor_settings = editor_interface.get_editor_settings()
	$"%ConfigEditor".base_theme = ModToolStore.base_theme


func get_log_nodes() -> void:
	var editor_log := get_parent().get_child(0)
	log_richtext_label = editor_log.get_child(1)

	# The button hbox should be last, but here it is second from last for some reason
	var dock_tool_button_bar: HBoxContainer = get_parent().get_child(get_parent().get_child_count() -2)
	if not dock_tool_button_bar:
		# on project load it can happen that these nodes don't exist yet, wait for parent
		yield(get_parent(), "ready")
		dock_tool_button_bar = get_parent().get_child(get_parent().get_child_count() -2)
	log_output_dock_button = dock_tool_button_bar.get_child(0).get_child(0)

	$"%ConfigEditor".connect("discard_last_console_error", self, "discard_last_console_error")


# Removes the last error line from the output console as if nothing happened
# used in the json validation since the error is displayed right there and
# it causes a lot of clutter otherwise
func discard_last_console_error() -> void:
	# If the console is flooded anyway, ignore
	var line_count := log_richtext_label.get_line_count()
	if line_count > 1000:
		return

	# The last line is an empty line, remove the one before that
	log_richtext_label.remove_line(line_count -2)
	log_richtext_label.add_text("\n")

	# If there is an error in the console already, leave the circle on the tool button
	# All error lines have a space in the beginnig to separate from the circle image
	# Not the safest way to check, but it's the only one it seems
	for line in log_richtext_label.text.split("\n"):
		if (line as String).begins_with(" "):
			return

	# If there were no other error lines, remove the icon
	# Setting to null will crash the editor occasionally, this does not
	if log_output_dock_button:
		log_output_dock_button.icon = StreamTexture.new()


func _save_manifest() -> void:
	pass # todo


func _load_manifest() -> void:
	pass # todo


func _is_manifest_valid() -> bool:
	var mod_manifest: Script
	if ModLoaderUtils.file_exists("res://addons/mod_loader/mod_manifest.gd"):
		mod_manifest = load("res://addons/mod_loader/mod_manifest.gd")

	var is_valid: bool
	if not mod_manifest:
		return false

	var mod_name: String = $"%ModName".get_value()
	is_valid = $"%ModName".show_error_if_not(mod_manifest.is_name_or_namespace_valid(mod_name))

	# todo

	return is_valid


func _update_ui():
	mod_id.input_text = ModToolStore.name_mod_dir


func _is_mod_dir_valid() -> bool:
	# Check if Mod ID is given
	if ModToolStore.name_mod_dir == '':
		ModToolUtils.output_error("Please provide a Mod ID")
		return false

	# Check if mod dir exists
	if not ModLoaderUtils.dir_exists(ModToolStore.path_mod_dir):
		ModToolUtils.output_error("Mod folder %s does not exist" % ModToolStore.path_mod_dir)
		return false

	return true


func _on_export_pressed() -> void:
	if _is_mod_dir_valid():
		var zipper := ModToolZipBuilder.new()
		zipper.build_zip()


func _on_clear_output_pressed() -> void:
	label_output.clear()


func _on_copy_output_pressed() -> void:
	OS.clipboard = label_output.text


func _on_save_manifest_pressed() -> void:
	if _is_manifest_valid():
		_save_manifest()


func _on_save_config_pressed() -> void:
	pass # todo


func _on_export_settings_create_new_mod_pressed() -> void:
	popup.popup_centered()
	create_mod.clear_mod_id_input()


# replicates the behaviour for the debugger tab styles
# for the full setup of this, the TabContainer needs to be the child of a
# full rect Control and have a margin_left of -10 and a margin_right of 10
# this is to offset the 10px content margins that are still present in the
# BottomPanelDebuggerOverride stylebox for some reason. It's how Godot does it.
func _on_mod_tools_dock_visibility_changed() -> void:
	if not visible or not ModToolStore.base_theme or not tab_parent_bottom_panel:
		return

	# the panel style is overridden by godot after this method is called
	# make sure our override-override is applied after that
	yield(get_tree(), "idle_frame")

	var panel_box: StyleBoxFlat = ModToolStore.base_theme.get_stylebox("BottomPanelDebuggerOverride", "EditorStyles")
	tab_parent_bottom_panel.add_stylebox_override("panel", panel_box)


# Update the mod name in the ModToolStore
func _on_ModId_input_text_changed(new_text, input_node) -> void:
	ModToolStore.name_mod_dir = new_text
	input_node.show_error_if_not(ModToolUtils.validate_mod_dir_name(new_text))


func _on_CreateMod_mod_dir_created() -> void:
	popup.hide()
	_update_ui()
