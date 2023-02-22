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
				store.path_mod_files.append("res://" + path_imported_file)

	# Generate temp folder that get's zipped later
	for i in store.path_mod_files.size():
		var path_mod_file := store.path_mod_files[i] as String

		# copy mod_file to path_zip_file
		ModToolUtils.file_copy(path_mod_file, store.path_temp_dir + '/' + path_mod_file.trim_prefix("res://"))

	# Zip that folder with 7zip
	var path_addon_dir := ProjectSettings.globalize_path(store.path_project_dir + "addons/mod_tool/")
	var path_seven_zip := path_addon_dir + "vendor/7zip/win/zip.exe"
	var path_final_zip := path_addon_dir + "zips/" + store.name_mod_dir + ".zip"
	var path_global_temp_dir := ProjectSettings.globalize_path(store.path_temp_dir)
	var path_global_temp_dir_with_wildcard := path_global_temp_dir + "/*"

	var output := []
	var _exit_code := OS.execute(path_seven_zip, ["a", path_final_zip, path_global_temp_dir_with_wildcard], true, output)
	store.label_output.add_text(JSON.print(output, '   '))

	# Delete the temp folder
	ModToolUtils.remove_recursive(path_global_temp_dir)


# TODO: Rework this to use [ConfigFile]
# https://docs.godotengine.org/en/stable/classes/class_configfile.html
func _get_imported_file_path(store: ModToolStore, import_file_path: String) -> String:
	# Open file
	var text := ModToolUtils.file_get_as_text(import_file_path)

	# Get the path to the imported file
	var path_imported_file_regex_results := ModToolUtils.get_regex_results(text, "res\\:\\/\\/\\.import.+?(?=\\\")")
	if(path_imported_file_regex_results.size() == 0):
		print("ERROR: No path found inside .import file! import_file_path -> " + import_file_path)
		return ""

	# Grab the first path to the imported file
	# Imported file example path:
	# res://.import/ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex
	var imported_file_src_path_local := path_imported_file_regex_results[0] as String
	# remove the res://
	imported_file_src_path_local = imported_file_src_path_local.replace('res://', '')
	# Globalize the path:
	# C:\Path\to\GodotProject\.import\ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex
	var imported_file_src_path := str(store.path_project_dir, imported_file_src_path_local)

	# Get the imported file dst file - the dst path is local to the zip file
	# Imported file dst path example:
	# \.import\ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex

	# ['C:\Path\to\GodotProject\', '\ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex']
	var imported_file_src_path_split := imported_file_src_path.split('.import')
	var imported_file_local_path := imported_file_src_path_split[1]

	var imported_file_dst_path := str('.import', imported_file_local_path)

	return imported_file_dst_path
