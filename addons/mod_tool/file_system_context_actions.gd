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
		file_paths = metadata.mod_tool_script_paths
		for file_path in file_paths:
			create_script_override(file_path)


static func create_script_override(file_path: String) -> void:
	if not ModToolStore.name_mod_dir:
		ModToolUtils.output_error("Select an existing mod or create a new one to create script overrides")
		return

	var file_directory := file_path.get_base_dir().trim_prefix("res://")
	var override_directory: String = ModToolStore.path_mod_dir.plus_file(file_directory)
	ModToolUtils.make_dir_recursive(override_directory)

	var file := File.new()
	var override_path := override_directory.plus_file(file_path.get_file())
	if not file.file_exists(override_path):
		file.open(override_path, File.WRITE)
		file.store_line('extends "%s"' % file_path)
		file.close()

	ModToolStore.editor_file_system.scan()
	ModToolStore.editor_plugin.get_editor_interface().get_file_system_dock().navigate_to_path(override_path)




