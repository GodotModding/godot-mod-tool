@tool
class_name ModToolInterfaceHookGen
extends Window


@onready var mod_tool_store: ModToolStore = get_node_or_null("/root/ModToolStore")
@onready var info_output: RichTextLabel = %InfoOutput
@onready var restart: Window = %Restart
@onready var button_gen_start: Button = %ButtonGenStart


func generate_hooks() -> void:
	# Get all script not in addons or mods-unpacked
	var all_script_file_paths := ModToolUtils.get_flat_view_dict("res://", "", [&"gd"], false, false, [&"addons", &"mods-unpacked"])
	var mod_hook_preprocessor = _ModLoaderModHookPreProcessor.new()

	# Create a backup of the vanilla script files
	var project_dir_name := ProjectSettings.globalize_path("res://").get_base_dir().rsplit("/", true, 1)[1]
	var parent_project_dir_path := ProjectSettings.globalize_path("res://").rsplit("/", true, 2)[0]
	var backup_dir_path := "%s/%s" % [parent_project_dir_path, "%s-scripts_backup" % project_dir_name]
	DirAccess.make_dir_recursive_absolute(backup_dir_path)

	for script_file_path in all_script_file_paths:
		var script_file_name := script_file_path.get_file()
		ModToolUtils.file_copy(script_file_path, "%s/%s" % [backup_dir_path, script_file_name])

	info_output.add_text("Script backup created at %s\n" % backup_dir_path)

	# -- Start Mod Hook Generation --
	mod_hook_preprocessor.process_begin()
	info_output.add_text("Starting Mod Hook Generation..\n")

	for script_file_path in all_script_file_paths:
		var source_code := mod_hook_preprocessor.process_script(script_file_path)

		var file := FileAccess.open(script_file_path, FileAccess.WRITE)

		if not file:
			info_output.add_text("ERROR: ACCESSING FILE: %s\n" % script_file_path)
			return

		# Clear existing file
		file.resize(0)
		# Write processed source_code to file
		file.store_string(source_code)
		file.close()

	mod_tool_store.is_hook_generation_done = true
	info_output.add_text("Mod Hook generation completed successfully!\n")

	restart.show()


func _on_button_pressed() -> void:
	button_gen_start.disabled = true
	generate_hooks()


func _on_close_requested() -> void:
	hide()


func _on_button_restart_now_pressed() -> void:
	EditorInterface.restart_editor()


func _on_button_restart_later_pressed() -> void:
	restart.hide()
	hide()


func _on_restart_close_requested() -> void:
	restart.hide()


func _on_button_hooks_exist_pressed() -> void:
	mod_tool_store.is_hook_generation_done = true
	hide()
