extends Node
class_name ModToolZipBuilder


func build_zip(mod_tool_store: ModToolStore) -> void:
	var writer := ZIPPacker.new()
	var err := writer.open(mod_tool_store.path_global_final_zip)
	if not err == OK:
		return

	# Get all file paths inside the mod folder
	mod_tool_store.path_mod_files = ModToolUtils.get_flat_view_dict(mod_tool_store.path_mod_dir)

	# Loop over each file path
	for i in mod_tool_store.path_mod_files.size():
		var path_mod_file := mod_tool_store.path_mod_files[i] as String
		# Check for excluded file extensions
		if ModToolUtils.is_file_extension(path_mod_file, mod_tool_store.excluded_file_extensions):
			# Dont add files with unwanted extensions to the zip
			mod_tool_store.path_mod_files.remove_at(i)
			continue

		# If it's a .import file
		if path_mod_file.get_extension() == "import":
			# Get the paths to the imported file
			var path_imported_files := _get_imported_file_paths(path_mod_file)
			# And add them to the mod file paths
			for path in path_imported_files:
				mod_tool_store.path_mod_files.append(path)

	# Add each file to the mod zip
	for i in mod_tool_store.path_mod_files.size():
		var path_mod_file: String = mod_tool_store.path_mod_files[i]
		var path_mod_file_data := FileAccess.open(path_mod_file, FileAccess.READ)
		var path_mod_file_length := path_mod_file_data.get_length()
		var path_mod_file_buffer := path_mod_file_data.get_buffer(path_mod_file_length)
		var path_zip_file: String = path_mod_file.trim_prefix("res://")

		writer.start_file(path_zip_file) # path inside the zip file
		writer.write_file(path_mod_file_buffer)
		writer.close_file()

	writer.close()

	# Open the export dir
	var file_manager_path: String = mod_tool_store.path_global_export_dir
	if OS.has_feature("macos"):
		file_manager_path = "file://" + file_manager_path
	OS.shell_open(file_manager_path)


func _get_imported_file_paths(import_file_path: String) -> Array[String]:
	var config := ConfigFile.new()

	# Open file
	var error := config.load(import_file_path)
	if error != OK:
		ModToolUtils.output_error("Failed to load import file -> " + str(error))

	# Get all paths to the imported file
	# Imported file example path:
	# res://.godot/imported/ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex
	var path_keys := Array(config.get_section_keys('remap')) \
		.filter(func(key): return key.begins_with('path.'))

	# Grab all paths that are not empty
	var valid_paths: Array[String] = []
	for key in path_keys + ['path']:
		var imported_file_path := config.get_value('remap', key, '') as String
		if imported_file_path != '':
			valid_paths.append(imported_file_path)

	if len(valid_paths) == 0:
		ModToolUtils.output_error("No remap paths found in import file")

	return valid_paths
