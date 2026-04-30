class_name FileSystemContextActions
extends EditorContextMenuPlugin


var mod_tool_store: ModToolStore


class ContextActionOptions:
	extends Resource

	var icon: StringName
	var title: String
	var meta_key: StringName
	var tooltip: String
	var action: Callable

	func _init(_icon, _title, _meta_key, _tooltip, _action) -> void:
		icon = _icon
		title = _title
		meta_key = _meta_key
		tooltip = _tooltip
		action = _action


func _init(_mod_tool_store: ModToolStore) -> void:
	mod_tool_store = _mod_tool_store


func _popup_menu(paths: PackedStringArray) -> void:
	var file_paths: Array[String] = []
	file_paths.assign(paths)
	add_custom_context_actions(file_paths)


# Called every time the file system context actions pop up
# Since they are dynamic, they are cleared every time and need to be refilled
func add_custom_context_actions(file_paths: Array[String]) -> void:
	if file_paths.is_empty():
		return

	var script_paths: Array[String] = []
	var asset_override_paths: Array[String] = []
	for file_path in file_paths:
		if DirAccess.dir_exists_absolute(file_path):
			continue

		if FileAccess.file_exists(file_path):
			if file_path.ends_with(".gd"):
				script_paths.append(file_path)
				continue
			if file_path.ends_with(".tscn") or file_path.ends_with(".tres"):
				continue
			asset_override_paths.append(file_path)


	if script_paths.size() > 0:
		add_script_extension_context_action(script_paths)
		add_mod_hook_file_context_action(script_paths)

		var script_with_hook_count := ModToolUtils.check_for_hooked_script(script_paths, mod_tool_store)

		if script_with_hook_count == script_paths.size():
			add_restore_context_action(script_paths)
		elif script_with_hook_count > 0:
			add_restore_context_action(script_paths)
			add_hooks_context_action(script_paths)
		else:
			add_hooks_context_action(script_paths)

	if asset_override_paths.size() > 0:
		add_asset_override_context_action(asset_override_paths)


func create_script_extension(file_path: String) -> String:
	if not mod_tool_store.name_mod_dir:
		ModToolUtils.output_error("Select an existing mod or create a new one to create script overrides")
		return ""

	var file_directory := file_path.get_base_dir().trim_prefix("res://")
	var extension_directory: String = mod_tool_store.path_mod_dir.path_join("extensions").path_join(file_directory)
	ModToolUtils.make_dir_recursive(extension_directory)

	var extension_path := extension_directory.path_join(file_path.get_file())
	var file := FileAccess.open(extension_path, FileAccess.WRITE)
	if not FileAccess.file_exists(extension_path):
		file.store_line('extends "%s"' % file_path)
		file.close()
		ModToolUtils.output_info('Created script extension of "%s" at path %s' % [file_path.get_file(), extension_path])

	mod_tool_store.editor_file_system.scan()
	EditorInterface.get_file_system_dock().navigate_to_path(extension_path)
	# Load the new extension script
	var extension_script: Script = load(extension_path)
	# Open the new extension script in the script editor
	EditorInterface.edit_script(extension_script)

	return extension_path


func create_mod_hook_file(file_path: String) -> String:
	if not mod_tool_store.name_mod_dir:
		ModToolUtils.output_error("Select an existing mod or create a new one to create script overrides")
		return ""

	var file_directory := file_path.get_base_dir().trim_prefix("res://")
	var extension_directory: String = mod_tool_store.path_mod_dir.path_join("extensions").path_join(file_directory)
	ModToolUtils.make_dir_recursive(extension_directory)

	var hook_file_name := "%s.hooks.%s" % [file_path.get_file().get_basename(), file_path.get_extension()]
	var extension_path := extension_directory.path_join(hook_file_name)
	print(extension_path)
	var file := FileAccess.open(extension_path, FileAccess.WRITE)
	if not FileAccess.file_exists(extension_path):
		file.store_line('extends Object')
		file.close()
		ModToolUtils.output_info('Created mod hook file for "%s" at path %s' % [file_path.get_file(), extension_path])

	mod_tool_store.editor_file_system.scan()
	EditorInterface.get_file_system_dock().navigate_to_path(extension_path)
	# Load the new extension script
	var extension_script: Script = load(extension_path)
	# Open the new extension script in the script editor
	EditorInterface.edit_script(extension_script)

	return extension_path


func add_script_extension_to_mod_main(extension_path: String) -> void:
	var main_script_path: String = mod_tool_store.path_mod_dir.path_join("mod_main.gd")

	var file := FileAccess.open(main_script_path, FileAccess.READ_WRITE)
	if not file:
		ModToolUtils.output_error("Failed to open mod_main.gd with error \"%s\"" % error_string(FileAccess.get_open_error()))
	if not ModToolUtils.script_has_method(main_script_path, "install_script_extensions"):
		ModToolUtils.output_error('To automatically add new script extensions to "mod_main.gd", add "func install_script_extensions():" to it.')
		return

	var file_content := file.get_as_text()

	var index_find_from := file_content.find("func install_script_extensions")
	var mod_extensions_dir_path_index := file_content.find("extensions_dir_path", index_find_from)

	# Construct the line required to install the extension. If the standard way is used and a
	# variable "extensions_dir_path" is found, use that variable in combination with path_join
	var extension_install_line := "\tModLoaderMod.install_script_extension(%s)\n"
	if mod_extensions_dir_path_index == -1:
		extension_install_line = extension_install_line % ModToolUtils.quote_string(extension_path)
	else:
		extension_path = extension_path.trim_prefix(mod_tool_store.path_mod_dir.path_join("extensions/"))
		extension_install_line = extension_install_line % "extensions_dir_path.path_join(%s)" % ModToolUtils.quote_string(extension_path)

	# Check if that file was already used as script extension
	if extension_install_line.strip_edges() in file_content:
		return

	var last_install_line_index := file_content.rfind("ModLoaderMod.install_script_extension")
	if last_install_line_index == -1:
		# If there is no ModLoaderMod.install_script_extension yet, put it at the end of install_script_extensions
		var insertion_index := ModToolUtils.get_index_at_method_end("install_script_extensions", file_content)
		file_content = file_content.insert(insertion_index, "\n" + extension_install_line)
	else:
		var last_install_line_end_index := file_content.find("\n", last_install_line_index)
		file_content = file_content.insert(last_install_line_end_index +1, extension_install_line)

	file.store_string(file_content)

	file.close()

	ModToolUtils.output_info('Added script extension "%s" to mod "%s"' % [extension_path, main_script_path.get_base_dir().get_file()])


func add_hook_file_to_mod_main(vanilla_path: String, extension_path: String) -> void:
	var main_script_path: String = mod_tool_store.path_mod_dir.path_join("mod_main.gd")

	var file := FileAccess.open(main_script_path, FileAccess.READ_WRITE)
	if not file:
		ModToolUtils.output_error("Failed to open mod_main.gd with error \"%s\"" % error_string(FileAccess.get_open_error()))
	if not ModToolUtils.script_has_method(main_script_path, "install_script_hook_files"):
		ModToolUtils.output_error('To automatically add new script hook files to "mod_main.gd", add "func install_script_hook_files():" to it.')
		return

	var file_content := file.get_as_text()

	var index_find_from := file_content.find("func install_script_hook_files")
	var mod_extensions_dir_path_index := file_content.find("extensions_dir_path", index_find_from)

	# Construct the line required to install the extension. If the standard way is used and a
	# variable "extensions_dir_path" is found, use that variable in combination with path_join
	var extension_install_line := "\tModLoaderMod.install_script_hooks(" + ModToolUtils.quote_string(vanilla_path) + ", %s)\n"
	if mod_extensions_dir_path_index == -1:
		extension_install_line = extension_install_line % ModToolUtils.quote_string(extension_path)
	else:
		extension_path = extension_path.trim_prefix(mod_tool_store.path_mod_dir.path_join("extensions/"))
		extension_install_line = extension_install_line % "extensions_dir_path.path_join(%s)" % ModToolUtils.quote_string(extension_path)

	# Check if that file was already used as script extension
	if extension_install_line.strip_edges() in file_content:
		return

	var last_install_line_index := file_content.rfind("ModLoaderMod.install_script_hooks")
	if last_install_line_index == -1:
		# If there is no ModLoaderMod.install_script_hooks yet, put it at the end of install_script_hook_files
		var insertion_index := ModToolUtils.get_index_at_method_end("install_script_hook_files", file_content)
		file_content = file_content.insert(insertion_index, "\n" + extension_install_line)
	else:
		var last_install_line_end_index := file_content.find("\n", last_install_line_index)
		file_content = file_content.insert(last_install_line_end_index +1, extension_install_line)

	file.store_string(file_content)

	file.close()

	ModToolUtils.output_info('Added mod hooks file "%s" to mod "%s"' % [extension_path, main_script_path.get_base_dir().get_file()])


func create_overwrite_asset(file_path: String) -> String:
	if not mod_tool_store.name_mod_dir:
		ModToolUtils.output_error("Select an existing mod or create a new one to overwrite assets")
		return ""

	var file_directory := file_path.get_base_dir().trim_prefix("res://")
	var overwrite_directory: String = mod_tool_store.path_mod_dir.path_join("overwrites").path_join(file_directory)
	ModToolUtils.make_dir_recursive(overwrite_directory)

	var overwrite_path := overwrite_directory.path_join(file_path.get_file())
	if not FileAccess.file_exists(overwrite_path):
		DirAccess.copy_absolute(file_path, overwrite_path)
		ModToolUtils.output_info('Copied asset "%s" as overwrite to path %s' % [file_path.get_file(), overwrite_path])

	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.get_file_system_dock().navigate_to_path(overwrite_path)

	return overwrite_path


func add_asset_overwrite_to_overwrites(vanilla_asset_path: String, asset_path: String) -> void:
	var overwrites_script_path: String = mod_tool_store.path_mod_dir.path_join("overwrites.gd")
	var overwrites_script: GDScript
	var overwrites_script_new: Node
	var overwrites_script_syntax_tempalte := """extends Node


var vanilla_file_paths: Array[String] = {%VANILLA_FILE_PATHS%}
var overwrite_file_paths: Array[String] = {%OVERWRITE_FILE_PATHS%}

var overwrite_resources := []


func _init():
	for i in overwrite_file_paths.size():
		var vanilla_path := vanilla_file_paths[i]
		var overwrite_path := overwrite_file_paths[i]

		var overwrite_resource := load(overwrite_path)
		overwrite_resources.push_back(overwrite_resource)
		overwrite_resource.take_over_path(vanilla_path)
"""

	# overwrite.gd does not exist yet
	if not FileAccess.file_exists(overwrites_script_path):
		overwrites_script = GDScript.new()
		overwrites_script.source_code = overwrites_script_syntax_tempalte.format({
			"%VANILLA_FILE_PATHS%": "[]",
			"%OVERWRITE_FILE_PATHS%": "[]",
		})
		var success := ResourceSaver.save(overwrites_script, overwrites_script_path)
		if not success == OK:
			ModToolUtils.output_error("Failed to save overwrite.gd with error \"%s\"" % error_string(FileAccess.get_open_error()))

	overwrites_script = load(overwrites_script_path)
	overwrites_script_new = overwrites_script.new()

	# Check if the overwrites script has the neccessary props
	if (
		not ModToolUtils.script_has_method(overwrites_script_path, "vanilla_file_paths") or
		not ModToolUtils.script_has_method(overwrites_script_path, "overwrite_file_paths")
	):
		ModToolUtils.output_error("The 'overwrites.gd' file has an unexpected format. To proceed, please delete the existing 'overwrites.gd' file and allow the tool to regenerate it automatically.")
		return

	# Check if that asset is already being overwritten
	if asset_path in overwrites_script_new.overwrite_file_paths:
		return

	overwrites_script_new.vanilla_file_paths.push_back(vanilla_asset_path)
	overwrites_script_new.overwrite_file_paths.push_back(asset_path)

	overwrites_script.source_code = overwrites_script_syntax_tempalte.format({
		"%VANILLA_FILE_PATHS%": JSON.stringify(overwrites_script_new.vanilla_file_paths, "\t"),
		"%OVERWRITE_FILE_PATHS%": JSON.stringify(overwrites_script_new.overwrite_file_paths, "\t"),
	})

	ResourceSaver.save(overwrites_script)

	overwrites_script_new.free()

	# Open the overwrites script in the script editor
	EditorInterface.edit_script(overwrites_script)

	ModToolUtils.output_info('Added asset overwrite "%s" to mod "%s"' % [asset_path, overwrites_script_path.get_base_dir().get_file()])


func add_context_action(script_paths: Array[String], options: ContextActionOptions) -> void:
	add_context_menu_item(
		"ModTool: %s" % options.title + ("s (%s)" % script_paths.size() if script_paths.size() > 1 else ""),
		options.action,
		mod_tool_store.editor_base_control.get_theme_icon(options.icon, &"EditorIcons")
		)


func add_script_extension_context_action(script_paths: Array[String]) -> void:
	add_context_action(
		script_paths,
		ContextActionOptions.new(
			&"ScriptExtend",
			"Create Script Extension",
			&"mod_tool_script_paths",
			"Will add extensions for",
			handle_script_extension_creation,
		)
	)


func add_mod_hook_file_context_action(script_paths: Array[String]) -> void:
	add_context_action(
		script_paths,
		ContextActionOptions.new(
			&"ScriptExtend",
			"Create Mod Hook File",
			&"mod_tool_mod_hook_file_paths",
			"Will add mod hook files for",
			handle_mod_hook_file_creation,
		)
	)


func add_restore_context_action(script_paths: Array[String]) -> void:
	var script_paths_to_restore: Array[String] = script_paths.filter(
		func(script_path): return mod_tool_store.hooked_scripts.has(script_path)
	)

	add_context_action(
		script_paths_to_restore,
		ContextActionOptions.new(
			&"UndoRedo",
			"Restore script to unhooked version",
			&"mod_tool_restore_script_paths",
			"Will restore the non hooked script for",
			handle_mod_hook_restore,
		)
	)


func add_asset_override_context_action(script_paths: Array[String]) -> void:
	add_context_action(
		script_paths,
		ContextActionOptions.new(
			&"Override",
			"Create Asset Overwrite",
			&"mod_tool_override_paths",
			"Will overwrite assets",
			handle_override_creation,
		)
	)


func add_hooks_context_action(script_paths: Array[String]) -> void:
	var script_paths_to_add_hooks: Array[String] = script_paths.filter(
		func(script_path): return not mod_tool_store.hooked_scripts.has(script_path)
	)

	add_context_action(
		script_paths_to_add_hooks,
		ContextActionOptions.new(
			&"ShaderGlobalsOverride",
			"Convert script to hooked version",
			&"mod_tool_hook_script_paths",
			"Will add mod hooks for",
			handle_mod_hook_creation,
		)
	)


func handle_script_extension_creation(file_paths: Array[String]) -> void:
	var mod_main_path := mod_tool_store.path_mod_dir.path_join("mod_main.gd")

	for file_path in file_paths:
		var extension_path := create_script_extension(file_path)
		if extension_path:
			add_script_extension_to_mod_main(extension_path)

	# We navigate to the created script extension in `create_script_extension()`, so we should never
	# instantly refresh the mod main script here. If we call `ModToolUtils.reload_script()`
	# after this, it's possible that the `mod_main` content gets copied into the
	# newly created extension script. If that script is then saved, we
	# unintentionally overwrite the original script content.
	mod_tool_store.pending_reloads.push_back(mod_main_path)

	 #Switch to the script screen
	EditorInterface.set_main_screen_editor("Script")


func handle_mod_hook_file_creation(file_paths: Array[String]) -> void:
	var mod_main_path := mod_tool_store.path_mod_dir.path_join("mod_main.gd")

	for file_path in file_paths:
		var extension_path := create_mod_hook_file(file_path)
		if extension_path:
			add_hook_file_to_mod_main(file_path, extension_path)

	# We navigate to the created script extension in `create_script_extension()`, so we should never
	# instantly refresh the mod main script here. If we call `ModToolUtils.reload_script()`
	# after this, it's possible that the `mod_main` content gets copied into the
	# newly created extension script. If that script is then saved, we
	# unintentionally overwrite the original script content.
	mod_tool_store.pending_reloads.push_back(mod_main_path)

	 #Switch to the script screen
	EditorInterface.set_main_screen_editor("Script")


func handle_override_creation(file_paths: Array[String]) -> void:
	var current_script: GDScript
	var overwrites_path := mod_tool_store.path_mod_dir.path_join("overwrites.gd")

	for file_path in file_paths:
		var asset_path := create_overwrite_asset(file_path)
		if asset_path:
			add_asset_overwrite_to_overwrites(file_path, asset_path)

	current_script = EditorInterface.get_script_editor().get_current_script()

	mod_tool_store.pending_reloads.push_back(overwrites_path)

	if current_script.resource_path == overwrites_path:
		ModToolUtils.reload_script(current_script, mod_tool_store)

	#Switch to the script screen
	EditorInterface.set_main_screen_editor("Script")


func handle_mod_hook_creation(file_paths: Array[String]) -> void:
	var current_script: GDScript

	for file_path in file_paths:
		var error := ModToolHookGen.transform_one(file_path, mod_tool_store)

		if not error == OK:
			ModToolUtils.output_error("Error creating mod hooks for script at path: \"%s\" error: \"%s\" " % [file_path, error_string(error)])
			return

		mod_tool_store.pending_reloads.push_back(file_path)
		current_script = EditorInterface.get_script_editor().get_current_script()

		if current_script.resource_path == file_path:
			ModToolUtils.reload_script(current_script, mod_tool_store)

		ModToolUtils.output_info("Mod Hooks created for script at path: \"%s\"" % file_path)


func handle_mod_hook_restore(file_paths: Array[String]) -> void:
	var current_script: GDScript

	for file_path in file_paths:
		var error := ModToolHookGen.restore(file_path, mod_tool_store)

		if not error == OK:
			ModToolUtils.output_error("ERROR: Restoring script: \"%s\" with error: \"%s\"" % [file_path, error_string(error)])
			return

		mod_tool_store.pending_reloads.push_back(file_path)
		current_script = EditorInterface.get_script_editor().get_current_script()

		if current_script.resource_path == file_path:
			ModToolUtils.reload_script(current_script, mod_tool_store)
