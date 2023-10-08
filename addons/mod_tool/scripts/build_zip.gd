extends Node
class_name ModToolZipBuilder


func build_zip(mod_tool_store: ModToolStore) -> void:
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
			# Get the path to the imported file
			var path_imported_file := _get_imported_file_path(path_mod_file)
			# And add it to the mod file paths
			if not path_imported_file == "":
				mod_tool_store.path_mod_files.append(path_imported_file)

	# Generate temp folder that get's zipped later
	for i in mod_tool_store.path_mod_files.size():
		var path_mod_file: String = mod_tool_store.path_mod_files[i]
		var path_zip_file: String = mod_tool_store.path_temp_dir + '/' + path_mod_file.trim_prefix("res://")

		# Copy mod_file to temp folder
		ModToolUtils.file_copy(path_mod_file, path_zip_file)

	# Zip that folder with 7zip
	var path_global_temp_dir_with_wildcard: String = mod_tool_store.path_global_temp_dir + "/*"

	var output := []
	var _exit_code := OS.execute(mod_tool_store.path_global_seven_zip, ["a", mod_tool_store.path_global_final_zip, path_global_temp_dir_with_wildcard], output)
	# Output the 7zip cli info
	ModToolUtils.output_info(output[0])

	# Delete the temp folder
	ModToolUtils.remove_recursive(mod_tool_store.path_global_temp_dir)

	# Open the export dir
	var file_manager_path: String = mod_tool_store.path_global_export_dir
	if OS.has_feature("OSX"):
		file_manager_path = "file://" + file_manager_path
	OS.shell_open(file_manager_path)


func _get_imported_file_path(import_file_path: String) -> String:
	var config := ConfigFile.new()

	# Open file
	var error := config.load(import_file_path)
	if error != OK:
		ModToolUtils.output_error("Failed to load import file -> " + str(error))

	# Get the path to the imported file
	# Imported file example path:
	# res://.import/ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex
	var imported_file_path := config.get_value('remap', 'path', '') as String

	if imported_file_path == '':
		ModToolUtils.output_error("No remap path found in import file -> " + import_file_path)
		return ''

	return imported_file_path
