extends Node
class_name ModToolZipBuilder


func build_zip(store: ModToolStore) -> void:
	# Get all file paths inside the mod folder
	store.path_mod_files = ModToolUtils.get_flat_view_dict(store.path_mod_dir)
	store.label_output.add_text(JSON.print(store.path_mod_files, '   '))

	# Loop over each file path
	for i in store.path_mod_files.size():
		var path_mod_file := store.path_mod_files[i] as String
		# Check for excluded file extensions
		if ModToolUtils.is_file_extension(path_mod_file, store.excluded_file_extensions):
			# Dont add files with unwanted extensions to the zip
			store.path_mod_files.remove(i)
			continue

		# If it's a .import file
		if path_mod_file.get_extension() == "import":
			# Get the path to the imported file
			var path_imported_file := _get_imported_file_path(store, path_mod_file)
			# And add it to the mod file paths
			if not path_imported_file == "":
				store.path_mod_files.append(path_imported_file)

	# Generate temp folder that get's zipped later
	for i in store.path_mod_files.size():
		var path_mod_file := store.path_mod_files[i] as String
		var path_zip_file := store.path_temp_dir + '/' + path_mod_file.trim_prefix("res://")

		# Copy mod_file to temp folder
		ModToolUtils.file_copy(path_mod_file, path_zip_file)

	# Zip that folder with 7zip
	var path_global_temp_dir_with_wildcard: String = store.path_global_temp_dir + "/*"

	var output := []
	var _exit_code := OS.execute(store.path_global_seven_zip, ["a", store.path_global_final_zip, path_global_temp_dir_with_wildcard], true, output)
	store.label_output.add_text(JSON.print(output, '   '))

	# Delete the temp folder
	ModToolUtils.remove_recursive(store.path_global_temp_dir)


func _get_imported_file_path(store: ModToolStore, import_file_path: String) -> String:
	var config := ConfigFile.new()

	# Open file
	var error := config.load(import_file_path)
	if error != OK:
		ModToolUtils.output_error(store, "Failed to load import file -> " + str(error))

	# Get the path to the imported file
	# Imported file example path:
	# res://.import/ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex
	var imported_file_path := config.get_value('remap', 'path', '') as String

	if imported_file_path == '':
		ModToolUtils.output_error(store, "No remap path found in import file -> " + import_file_path)
		return ''

	return imported_file_path
