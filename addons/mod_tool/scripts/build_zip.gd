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
			mod_tool_store.path_mod_files.remove(i)
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

	# Delete the zip if it already exists
	if _ModLoaderFile.file_exists(mod_tool_store.path_global_final_zip):
		_ModLoaderFile.remove_file(mod_tool_store.path_global_final_zip)

	# Zip that folder
	var output: String
	if OS.has_feature("Windows"):
		output = zip_win(mod_tool_store)
	if OS.has_feature("OSX"):
		output = zip_linux(mod_tool_store)
	if OS.has_feature("X11"):
		output = zip_linux(mod_tool_store)

	# Output the cli info
	ModToolUtils.output_info(output)

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


func version_to_int(major: int, minor: int, patch: int) -> int:
	return (major << 16) | (minor << 8) | patch


func get_win_archive_module_version_string() -> String:
	var output_archive_module_version := []
	var command_archive_module_version := "(Get-InstalledModule -Name Microsoft.PowerShell.Archive).Version.toString()"
	OS.execute("powershell.exe", ["-command", command_archive_module_version], true, output_archive_module_version)

	if output_archive_module_version.empty():
		ModToolUtils.output_error("Failed to retrieve PowerShell Archive module version.")
		return ""

	return "".join(output_archive_module_version)


func get_win_archive_module_version_array() -> PoolStringArray:
	var archive_module_version := get_win_archive_module_version_string()
	if archive_module_version.empty():
		return PoolStringArray([])

	var archive_module_version_array := archive_module_version.split(".")

	if archive_module_version_array.size() < 3:
		ModToolUtils.output_error("Invalid version format: %s" % archive_module_version)
		return PoolStringArray([])

	return archive_module_version_array


func get_win_archive_module_version_hex() -> int:
	var archive_module_version := get_win_archive_module_version_array()

	if archive_module_version.size() < 3:
		return -1

	return version_to_int(
		int(archive_module_version[0]),
		int(archive_module_version[1]),
		int(archive_module_version[2])
	)


# The powershell archive module needs to be at least version 1.2.5
# See https://github.com/PowerShell/Microsoft.PowerShell.Archive/pull/62
func is_win_archive_module_fixed() -> bool:
	if get_win_archive_module_version_hex() < 0x010205:
		return false

	return true


func update_win_archive_module() -> Array:
	var output_update_nuGet := []
	var command_update_nuGet := "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser"
	var pid_0 := OS.execute("powershell.exe", ["-command", command_update_nuGet], false, output_update_nuGet)

	var output_update_archive_module := []
	var command_update_archive_module := "Install-module -Name Microsoft.PowerShell.Archive -Scope CurrentUser -Force"
	var pid_1 := OS.execute("powershell.exe", ["-command", command_update_archive_module], false, output_update_archive_module)

	return [pid_0, pid_1]


func zip_win(mod_tool_store: ModToolStore) -> String:
	var output := []
	var command := "Compress-Archive -Path '%s/*' -DestinationPath '%s'" % [mod_tool_store.path_global_temp_dir, mod_tool_store.path_global_final_zip]
	OS.execute("powershell.exe", ["-command", command], true, output)
	return "".join(output)


func zip_linux(mod_tool_store: ModToolStore) -> String:
	var output := []
	var command := "(cd '%s' && zip -r '%s' .)" % [mod_tool_store.path_global_temp_dir, mod_tool_store.path_global_final_zip]
	OS.execute("$SHELL", ["-c", command], true, output)
	return "".join(output)
