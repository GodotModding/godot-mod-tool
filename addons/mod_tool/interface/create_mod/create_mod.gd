tool
extends MarginContainer


signal mod_dir_created

onready var mod_id := $Settings/Scroll/VBox/ModId


func _ready() -> void:
	mod_id.set_error_icon(ModToolStore.base_theme.get_icon("NodeWarning", "EditorIcons"))
	mod_id.show_error_if_not(false)


func add_mod() -> void:
	# Validate mod-id
	if not ModManifest.is_mod_id_valid(ModToolStore.name_mod_dir, ModToolStore.name_mod_dir, "", true):
		ModToolUtils.output_error('Invalid name or namespace: "%s". You may only use letters, numbers, underscores and at least 3 characters for each.' % ModToolStore.name_mod_dir)
		return

	# Check if mod dir exists
	if not ModLoaderUtils.dir_exists(ModToolStore.path_mod_dir):
		# If not - create it
		var success := ModToolUtils.make_dir_recursive(ModToolStore.path_mod_dir)
		if not success:
			return

		# Get Template files
		var template_paths := ModToolUtils.get_flat_view_dict(ModToolStore.path_current_template_dir, "", false, true)

		# Copy current selected template dir files and folders to res://mods-unpacked
		for path in template_paths:
			var template_local_path := path.trim_prefix(ModToolStore.path_current_template_dir) as String
			if ModLoaderUtils.file_exists(path):
				ModToolUtils.file_copy(path, ModToolStore.path_mod_dir.plus_file(template_local_path))
			else:
				ModToolUtils.make_dir_recursive(ModToolStore.path_mod_dir.plus_file(template_local_path))

		# Update FileSystem
		ModToolStore.editor_file_system.scan()
		# Wait for the scan to finish
		yield(ModToolStore.editor_file_system, "filesystem_changed")

		# Navigate to the new mod dir in the FileSystem pannel
		ModToolStore.editor_plugin.get_editor_interface().get_file_system_dock().navigate_to_path(ModToolStore.path_mod_dir.plus_file("mod_main.gd"))

		# Output info
		ModToolUtils.output_info("Added base mod files to " + ModToolStore.path_mod_dir)

		# Open mod_main.gd in the code editor
		var mod_main_script := load(ModToolStore.path_mod_dir.plus_file("mod_main.gd"))
		ModToolStore.editor_plugin.get_editor_interface().edit_script(mod_main_script)
		ModToolStore.editor_plugin.get_editor_interface().set_main_screen_editor("Script")

		# Split the new mod id
		var name_mod_dir_split := ModToolStore.name_mod_dir.split("-")

		# Update the namespace in the manifest
		ModToolStore.manifest_data.namespace = name_mod_dir_split[0]

		# Update the mod name in the manifest
		ModToolStore.manifest_data.name = name_mod_dir_split[1]

		# Update manifest editor ui
		ModToolStore.editor_plugin.tools_panel.manifest_editor.update_ui()

		# Open manifest editor
		ModToolStore.editor_plugin.tools_panel.show_manifest_editor()

		# Save the manifest
		ModToolStore.editor_plugin.tools_panel.manifest_editor.save_manifest()

	else:
		# If so - show error and ask if user wants to connect with the mod instead
		ModToolUtils.output_error("Mod directory at %s already exists." % ModToolStore.path_mod_dir)
		# TODO: Ask user to connect with the mod instead
		return


func clear_mod_id_input() -> void:
	mod_id.input_text = ""


func _on_btn_create_mod_pressed() -> void:
	add_mod()
	emit_signal("mod_dir_created")

