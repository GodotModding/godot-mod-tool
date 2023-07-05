tool
class_name ModToolsPanel
extends Control


# passed from the EditorPlugin
var editor_plugin: EditorPlugin setget set_editor_plugin
var context_actions: FileSystemContextActions

var tab_parent_bottom_panel: PanelContainer
var log_richtext_label: RichTextLabel
var log_dock_button: ToolButton

onready var tab_container := $"%TabContainer"
onready var create_mod := $"%CreateMod"
onready var select_mod: WindowDialog = $"%SelectMod"
onready var select_mod_template: WindowDialog = $"%SelectModTemplate"
onready var file_dialog = $FileDialog
onready var label_output := $"%Output"
onready var mod_id := $"%ModId"
onready var manifest_editor = $"%Manifest Editor"
onready var config_editor = $"%ConfigEditor"


func _ready() -> void:
	tab_parent_bottom_panel = get_parent().get_parent() as PanelContainer

	_update_ui()

	get_log_nodes()

	# Connect signals
	ModToolStore.connect("store_loaded", self, "_on_store_loaded")


func set_editor_plugin(plugin: EditorPlugin) -> void:
	editor_plugin = plugin

	ModToolStore.editor_plugin = plugin
	ModToolStore.base_theme = plugin.get_editor_interface().get_base_control().theme
	ModToolStore.editor_file_system = plugin.get_editor_interface().get_resource_filesystem()

	context_actions = FileSystemContextActions.new(
		plugin.get_editor_interface().get_file_system_dock(),
		plugin.get_editor_interface().get_base_control().theme
	)

	$"%ConfigEditor".editor_settings = plugin.get_editor_interface().get_editor_settings()
	$"%ConfigEditor".base_theme = ModToolStore.base_theme


func get_log_nodes() -> void:
	var editor_log := get_parent().get_child(0)
	log_richtext_label = editor_log.get_child(1) as RichTextLabel
	if not log_richtext_label:
		# on project load it can happen that these nodes don't exist yet, wait for parent
		yield(get_parent(), "ready")
		log_richtext_label = editor_log.get_child(1) as RichTextLabel

	# The button hbox should be last, but here it is second from last for some reason
	var dock_tool_button_bar: HBoxContainer = get_parent().get_child(get_parent().get_child_count() -2)
	log_dock_button = dock_tool_button_bar.get_child(0).get_child(0)

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
	if log_dock_button:
		log_dock_button.icon = StreamTexture.new()


func show_manifest_editor() -> void:
	tab_container.current_tab = 0


func show_config_editor() -> void:
	tab_container.current_tab = 1


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
	manifest_editor.save_manifest()


func _on_save_config_pressed() -> void:
	var config_defaults_json := config_editor.text as String
	ModToolStore.manifest_data.config_defaults = JSON.parse(config_defaults_json).result
	var _is_success := ModToolUtils.save_to_manifest_json()


func _on_export_settings_create_new_mod_pressed() -> void:
	create_mod.popup_centered()
	create_mod.clear_mod_id_input()


# Update the mod name in the ModToolStore
func _on_ModId_value_changed(new_text: String, input_node: ModToolInterfaceInput) -> void:
	ModToolStore.name_mod_dir = new_text
	input_node.show_error_if_not(ModManifest.is_mod_id_valid(new_text, new_text, '', true))


func _on_CreateMod_mod_dir_created() -> void:
	create_mod.hide()
	_update_ui()
	manifest_editor.load_manifest()
	manifest_editor.update_ui()


func _on_store_loaded() -> void:
	# Load manifest.json file
	if ModLoaderUtils.file_exists(ModToolStore.path_manifest):
		manifest_editor.load_manifest()
		manifest_editor.update_ui()


func _on_SelectTemplate_pressed():
	select_mod_template.generate_dir_buttons(ModToolStore.PATH_TEMPLATES_DIR)
	select_mod_template.popup_centered()


func _on_SelectModTemplate_dir_selected(dir_path: String) -> void:
	ModToolUtils.output_info("New template with the path \"%s\" selected." % dir_path)
	ModToolStore.path_current_template_dir = dir_path
	select_mod_template.hide()


func _on_ConnectMod_pressed() -> void:
	# Opens a popup that displays the mod directory names in the mods-unpacked directory
	select_mod.generate_dir_buttons(ModLoaderMod.get_unpacked_dir())
	select_mod.popup_centered()



