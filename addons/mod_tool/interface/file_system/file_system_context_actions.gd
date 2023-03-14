class_name FileSystemContextActions
extends Object

var base_theme: Theme


func _init(file_system_dock: FileSystemDock, p_base_theme: Theme) -> void:
	base_theme = p_base_theme
	connect_file_system_context_actions(file_system_dock)


func connect_file_system_context_actions(file_system_dock: FileSystemDock) -> void:
	# There are two file systems: one is a Tree, the second is an ItemList.
	# Both need to be handled. Toggle the button with two bars at the top to see both
	var file_tree: Tree
	var file_list: ItemList
	for node in file_system_dock.get_children():
		# Only the parent of the file tree and file list is a VSplit
		if node is VSplitContainer:
			file_tree = node.get_child(0)
			file_list = node.get_child(1).get_child(1)
			break


	for node in file_system_dock.get_children():
		var context_menu: PopupMenu = node as PopupMenu
		if not context_menu: continue

		context_menu.connect("id_pressed", self, "file_system_context_menu_pressed", [context_menu])

		# The order of the menus isn't always the same, but we can use their
		# signal connections to find out if they belong to the list or the tree
		var signals: Array = context_menu.get_signal_connection_list("id_pressed")
		if not signals.empty():
			match signals[0]["method"]:
				"_tree_rmb_option":
					context_menu.connect("about_to_show", self, "_on_file_tree_context_actions_about_to_show", [context_menu, file_tree])
				"_file_list_rmb_option":
					context_menu.connect("about_to_show", self, "_on_file_list_context_actions_about_to_show", [context_menu, file_list])


func _on_file_tree_context_actions_about_to_show(context_menu: PopupMenu, tree: Tree) -> void:
	var selected := tree.get_next_selected(null)
	if not selected:		# Empty space was clicked
		return

	# multiselection
	var file_paths := []
	while selected:
		var file_path = selected.get_metadata(0)
		if file_path is String:
			file_paths.append(file_path)
		selected = tree.get_next_selected(selected)

	add_custom_context_actions(context_menu, file_paths)


func _on_file_list_context_actions_about_to_show(context_menu: PopupMenu, list: ItemList) -> void:
	if not list.get_selected_items().size() > 0:		# Empty space was clicked
		return

	var file_paths := []
	for item_index in list.get_selected_items():
		var file_path = list.get_item_metadata(item_index)
		if file_path is String:
			file_paths.append(file_path)

	add_custom_context_actions(context_menu, file_paths)


# Called every time the file system context actions pop up
# Since they are dynamic, they are cleared every time and need to be refilled
func add_custom_context_actions(context_menu: PopupMenu, file_paths: PoolStringArray) -> void:
	var dir := Directory.new()

	if file_paths.empty():
		return

	var script_paths := []
	for file_path in file_paths:
		if dir.dir_exists(file_path):
			continue

		if dir.file_exists(file_path):
			if file_path.ends_with(".gd"):
				script_paths.append(file_path)

	if script_paths.size()	> 0:
		context_menu.add_separator()
		context_menu.add_icon_item(
			base_theme.get_icon("Override", "EditorIcons"),
			"ModTool: Create Script Extension" + ("s (%s)" % script_paths.size() if script_paths.size() > 1 else "")
		)
		context_menu.set_item_metadata(
			context_menu.get_item_count() -1,
			{ "mod_tool_script_paths": script_paths }
		)
		context_menu.set_item_tooltip(
			context_menu.get_item_count() -1,
			"Will add overrides for: \n%s" %
			str(script_paths).trim_prefix("[").trim_suffix("]").replace(", ", "\n")
		)


func file_system_context_menu_pressed(id: int, context_menu: PopupMenu) -> void:
	var file_paths: PoolStringArray
	var metadata = context_menu.get_item_metadata(id)

	# Ensure that the metadata is actually set by the ModTool
	# Since id and index of the item can always change
	if metadata is Dictionary and metadata.has("mod_tool_script_paths"):
		var file := File.new()

		file_paths = metadata.mod_tool_script_paths
		for file_path in file_paths:
			var extension_path := create_script_extension(file_path)
			if extension_path:
				add_script_extension_to_mod_main(file, extension_path)
		file.close()
		ModToolStore.editor_plugin.get_editor_interface().get_script_editor().reload_scripts()


static func create_script_extension(file_path: String) -> String:
	if not ModToolStore.name_mod_dir:
		ModToolUtils.output_error("Select an existing mod or create a new one to create script overrides")
		return ""

	var file_directory := file_path.get_base_dir().trim_prefix("res://")
	var extension_directory: String = ModToolStore.path_mod_dir.plus_file("extensions").plus_file(file_directory)
	ModToolUtils.make_dir_recursive(extension_directory)

	var file := File.new()
	var extension_path := extension_directory.plus_file(file_path.get_file())
	if not file.file_exists(extension_path):
		file.open(extension_path, File.WRITE)
		file.store_line('extends "%s"' % file_path)
		file.close()
		ModToolUtils.output_info('Created script extension of "%s" at path %s' % [file_path.get_file(), extension_path])

	ModToolStore.editor_file_system.scan()
	ModToolStore.editor_plugin.get_editor_interface().get_file_system_dock().navigate_to_path(extension_path)

	return extension_path


static func add_script_extension_to_mod_main(file: File, extension_path: String):
	var main_script_path := ModToolStore.path_mod_dir.plus_file("mod_main.gd")
	if not mod_has_install_script_extensions_method(main_script_path):
		return

	file.open(main_script_path, File.READ)
	var file_content := file.get_as_text()
	file.close()

	var index_find_from := file_content.find("func install_script_extensions")
	var mod_extensions_dir_path_index := file_content.find("extensions_dir_path", index_find_from)

	# Construct the line required to install the extension. If the standard way is used and a
	# variable "extensions_dir_path" is found, use that variable in combination with plus_file
	var extension_install_line := "\tmodLoader.install_script_extension(%s)\n"
	if mod_extensions_dir_path_index == -1:
		extension_install_line = extension_install_line % quote_string(extension_path)
	else:
		extension_path = extension_path.trim_prefix(ModToolStore.path_mod_dir.plus_file("extensions/"))
		extension_install_line = extension_install_line % "extensions_dir_path.plus_file(%s)" % quote_string(extension_path)

	# Check if that file was already used as script extension
	if extension_install_line.strip_edges() in file_content:
		return

	var last_install_line_index := file_content.find_last("modLoader.install_script_extension")
	if last_install_line_index == -1:
		# If there is no modLoader.install_script_extension yet, put it at the end of install_script_extensions
		var insertion_index := get_index_at_method_end("install_script_extensions", file_content)
		file_content = file_content.insert(insertion_index, "\n" + extension_install_line)
	else:
		var last_install_line_end_index := file_content.find("\n", last_install_line_index)
		file_content = file_content.insert(last_install_line_end_index +1, extension_install_line)

	file.open(main_script_path, File.WRITE)
	file.store_string(file_content)
	file.close()
	ModToolUtils.output_info('Added script extension "%s" to mod "%s"' % [extension_path, main_script_path.get_base_dir().get_file()])


static func get_index_at_method_end(method_name: String, text: String) -> int:
	var starting_index := text.find_last(method_name)

	# Find the end of the method
	var next_method_line_index := text.find("func ", starting_index)
	var method_end := -1

	if next_method_line_index == -1:
		# Backtrack empty lines from the end of the file
		method_end = text.length() -1
	else:
		# Get the line before the next function line
		method_end = text.rfind("\n", next_method_line_index)

	# Backtrack to the last non-empty line
	var last_non_empty_line_index := method_end
	while last_non_empty_line_index > starting_index:
		last_non_empty_line_index -= 1
		# Remove spaces, tabs and newlines (whitespace) to check if the line really is empty
		if text[last_non_empty_line_index].rstrip("\t\n "):
			break # encountered a filled line

	return last_non_empty_line_index +1


static func quote_string(string: String) -> String:
	var settings := ModToolStore.editor_plugin.get_editor_interface().get_editor_settings()
	if settings.get_setting("text_editor/completion/use_single_quotes"):
		return "'%s'" % string
	return "\"%s\"" % string


static func mod_has_install_script_extensions_method(main_script_path: String) -> bool:
	var main_script: Script = load(main_script_path)

	for method in main_script.get_script_method_list():
		if method.name == "install_script_extensions":
			return true

	ModToolUtils.output_error('To automatically add new script extensions to "mod_main.gd", add the method "install_script_extensions" to it.')
	return false

