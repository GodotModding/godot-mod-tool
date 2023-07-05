tool
extends WindowDialog


signal mod_dir_created

onready var namespace: ModToolInterfaceInputString = $"%Namespace"
onready var mod_name: ModToolInterfaceInputString = $"%ModName"
onready var mod_id: ModToolInterfaceInputString = $"%ModId"
onready var mod_template: ModToolInterfaceInputOptions = $"%ModTemplate"


func _ready() -> void:
	namespace.show_error_if_not(false)
	mod_name.show_error_if_not(false)
	mod_id.show_error_if_not(false)


func add_mod() -> void:
	# Validate mod-id
	if not ModManifest.is_mod_id_valid(ModToolStore.name_mod_dir, ModToolStore.name_mod_dir, "", true):
		ModToolUtils.output_error('Invalid name or namespace: "%s". You may only use letters, numbers, underscores and at least 3 characters for each.' % ModToolStore.name_mod_dir)
		return

	# Check if mod dir exists
	if not _ModLoaderFile.dir_exists(ModToolStore.path_mod_dir):
		# If not - create it
		var success := ModToolUtils.make_dir_recursive(ModToolStore.path_mod_dir)
		if not success:
			return

		# Get Template files
		var template_paths := ModToolUtils.get_flat_view_dict(ModToolStore.path_current_template_dir, "", false, true)

		# Copy current selected template dir files and folders to res://mods-unpacked
		for path in template_paths:
			var template_local_path := path.trim_prefix(ModToolStore.path_current_template_dir) as String
			if _ModLoaderFile.file_exists(path):
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


func get_template_options() -> PoolStringArray:
	var mod_template_options := []

	var template_dirs := _ModLoaderPath.get_dir_paths_in_dir(ModToolStore.PATH_TEMPLATES_DIR)

	for template_dir in template_dirs:
		mod_template_options.push_back(template_dir.split("/")[-1])

	return mod_template_options as PoolStringArray


func _on_Namespace_value_changed(new_value: String, input_node: ModToolInterfaceInputString) -> void:
	input_node.validate(ModManifest.is_name_or_namespace_valid(new_value, true))
	mod_id.input_text = "%s-%s" % [namespace.get_input_value(), mod_name.get_input_value()]


func _on_ModName_value_changed(new_value: String, input_node: ModToolInterfaceInputString) -> void:
	input_node.validate(ModManifest.is_name_or_namespace_valid(new_value, true))
	mod_id.input_text = "%s-%s" % [namespace.get_input_value(), mod_name.get_input_value()]


func _on_ModId_value_changed(new_value: String, input_node: ModToolInterfaceInputString) -> void:
	input_node.validate(ModManifest.is_mod_id_valid(new_value, new_value, "", true))
	ModToolStore.name_mod_dir = new_value


func _on_btn_create_mod_pressed() -> void:
	add_mod()
	emit_signal("mod_dir_created")


func _on_CreateMod_about_to_show() -> void:
	# Reset Inputs
	namespace.input_text = ""
	mod_name.input_text = ""
	# Reset Template
	ModToolStore.path_current_template_dir = ModToolStore.PATH_TEMPLATES_DIR + "default"

	# Get all Template options
	mod_template.input_options = get_template_options()


func _on_ModTemplate_value_changed(new_value: String, input_node: ModToolInterfaceInputOptions) -> void:
	ModToolStore.path_current_template_dir = ModToolStore.PATH_TEMPLATES_DIR + new_value
