tool
class_name ModToolsPanel
extends Control


# passed from the EditorPlugin
var mod_tool_store: ModToolStore
var editor_plugin: EditorPlugin setget set_editor_plugin
var context_actions: FileSystemContextActions

var tab_parent_bottom_panel: PanelContainer
var log_richtext_label: RichTextLabel
var log_dock_button: ToolButton

onready var mod_tool_store_node: ModToolStore = get_node_or_null("/root/ModToolStore")
onready var tab_container := $"%TabContainer"
onready var create_mod := $"%CreateMod"
onready var select_mod := $"%SelectMod"
onready var label_output := $"%Output"
onready var mod_id := $"%ModId"
onready var manifest_editor := $"%Manifest Editor"
onready var export_path := $"%ExportPath"
onready var file_dialog_export := $"%FileDialogExport"
onready var file_dialog_link_mod := $"%FileDialogLinkMod"
onready var export_status: Label = $"%ExportStatus"
onready var export_button: Button = $"%Export"
onready var update_archive_module: Button = $"%UpdateArchiveModule"
onready var update_archive_module_info: Button = $"%UpdateArchiveModuleInfo"

onready var zip_builder: ModToolZipBuilder = ModToolZipBuilder.new()


func _ready() -> void:
	tab_parent_bottom_panel = get_parent().get_parent() as PanelContainer

	get_log_nodes()

	# Load manifest.json file
	if mod_tool_store and _ModLoaderFile.file_exists(mod_tool_store.path_manifest):
		manifest_editor.load_manifest()
		manifest_editor.update_ui()

	# Check powershell archive module version if on windows
	if OS.has_feature("Windows") and not zip_builder.is_win_archive_module_fixed():
		export_status.text = "Export Status: PowerShell Archive Module Update required!"
		export_button.disabled =  true
		update_archive_module.show()
		update_archive_module_info.show()
	else:
		# Make sure to reset everything to default, don't rely on what is set in the scene file.
		# It's easy to accidentally manipulate that in the editor.
		export_status.text = "Export Status: OK"
		export_button.disabled =  false
		update_archive_module.hide()
		update_archive_module_info.hide()

	_update_ui()


func set_editor_plugin(plugin: EditorPlugin) -> void:
	editor_plugin = plugin

	mod_tool_store.editor_plugin = editor_plugin
	mod_tool_store.base_theme = editor_plugin.get_editor_interface().get_base_control().theme
	mod_tool_store.editor_file_system = editor_plugin.get_editor_interface().get_resource_filesystem()

	context_actions = FileSystemContextActions.new(
		mod_tool_store,
		editor_plugin.get_editor_interface().get_file_system_dock(),
		editor_plugin.get_editor_interface().get_base_control().theme
	)


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


func _update_ui() -> void:
	if not mod_tool_store:
		return
	mod_id.input_text = mod_tool_store.name_mod_dir
	export_path.input_text = mod_tool_store.path_export_dir


func _is_mod_dir_valid() -> bool:
	# Check if Mod ID is given
	if mod_tool_store.name_mod_dir == '':
		ModToolUtils.output_error("Please provide a Mod ID")
		return false

	# Check if mod dir exists
	if not _ModLoaderFile.dir_exists(mod_tool_store.path_mod_dir):
		ModToolUtils.output_error("Mod folder %s does not exist" % mod_tool_store.path_mod_dir)
		return false

	return true


func load_mod(name_mod_dir: String) -> void:
	# Set the dir name
	mod_tool_store.name_mod_dir = name_mod_dir

	# Load Manifest
	manifest_editor.load_manifest()
	manifest_editor.update_ui()

	# TODO: Load Mod Config if existing

	ModToolUtils.output_info("Mod \"%s\" loaded." % name_mod_dir)


func wait_for_win_archive_module_update(update_archive_module_shell_pids: Array, timeout_counter := 0) -> void:
	yield(get_tree().create_timer(0.15), "timeout")

	var processes_completed := 0

	for pid in update_archive_module_shell_pids:
		if not OS.is_process_running(pid):
			processes_completed += 1

	if processes_completed < 2:
		if timeout_counter > 100:
			ModToolUtils.output_error("Error Updating Archive Module: Timeout.")
			return
		ModToolUtils.output_info("Updating Archive Module")
		wait_for_win_archive_module_update(update_archive_module_shell_pids, timeout_counter + 1)
		return

	if zip_builder.is_win_archive_module_fixed():
		ModToolUtils.output_info("Successfully updated archive module to: %s" % zip_builder.get_win_archive_module_version_string())
		export_status.text = "Export Status: OK"
		export_button.disabled = false
		update_archive_module.hide()
		update_archive_module_info.hide()
	else:
		ModToolUtils.output_error("Something went wrong updating the archive module.")


func _on_export_pressed() -> void:
	if _is_mod_dir_valid():
		zip_builder.build_zip(mod_tool_store)


func _on_clear_output_pressed() -> void:
	label_output.clear()


func _on_copy_output_pressed() -> void:
	OS.clipboard = label_output.text


func _on_save_manifest_pressed() -> void:
	manifest_editor.save_manifest()


func _on_export_settings_create_new_mod_pressed() -> void:
	create_mod.popup_centered()
	create_mod.clear_mod_id_input()


func _on_CreateMod_mod_dir_created() -> void:
	create_mod.hide()
	_update_ui()
	manifest_editor.load_manifest()
	manifest_editor.update_ui()


func _on_ConnectMod_pressed() -> void:
	# Opens a popup that displays the mod directory names in the mods-unpacked directory
	select_mod.generate_dir_buttons(ModLoaderMod.get_unpacked_dir())
	select_mod.popup_centered()


func _on_SelectMod_dir_selected(dir_path: String) -> void:
	var mod_dir_name := dir_path.split("/")[-1]
	load_mod(mod_dir_name)
	select_mod.hide()
	_update_ui()


func _on_ButtonExportPath_pressed() -> void:
	file_dialog_export.current_path = mod_tool_store.path_export_dir
	file_dialog_export.popup_centered()


func _on_FileDialogExport_dir_selected(dir: String) -> void:
	mod_tool_store.path_export_dir = dir
	export_path.input_text = dir

	file_dialog_export.hide()


func _on_FileDialogLinkMod_dir_selected(dir: String) -> void:
	# Check if unpacked-mods dir exists
	if not _ModLoaderFile.dir_exists(ModLoaderMod.get_unpacked_dir()):
		# If not - create it
		var success := ModToolUtils.make_dir_recursive(ModLoaderMod.get_unpacked_dir())
		if not success:
			return

	# Create the Symlink
	var mods_unpacked_path := ModLoaderMod.get_unpacked_dir().plus_file(dir.get_file())
	ModToolUtils.output_info("Linking Path -> %s" % dir.get_file())
	FileSystemLink.mk_soft_dir(dir, mods_unpacked_path.get_base_dir())

	# Store the linked path
	mod_tool_store.path_last_linked_mod = dir

	file_dialog_link_mod.hide()


func _on_LinkMod_pressed() -> void:
	var current_path := ""
	if not mod_tool_store.path_last_linked_mod == "":
		current_path = mod_tool_store.path_last_linked_mod
	else:
		current_path = mod_tool_store.path_global_project_dir

	file_dialog_link_mod.current_path = current_path
	file_dialog_link_mod.popup_centered()


func _on_UpdateArchiveModule_pressed() -> void:
	var update_archive_module_shell_pids := zip_builder.update_win_archive_module()
	wait_for_win_archive_module_update(update_archive_module_shell_pids)


func _on_UpdateArchiveModuleInfo_pressed() -> void:
	OS.shell_open("https://github.com/GodotModding/godot-mod-tool/issues/127")
