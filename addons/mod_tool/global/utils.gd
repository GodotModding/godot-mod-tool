@tool
extends Node
class_name ModToolUtils


# Utility functions used across the ModTool.


# Takes a file path and an array of file extensions [.txt, .tscn, ..]
static func is_file_extension(path: String, excluded_extensions: PackedStringArray) -> bool:
	var is_extension := false

	for extension in excluded_extensions:
		var file_name := path.get_file()
		if(extension in file_name):
			is_extension = true
			break
		else:
			is_extension = false

	return is_extension


# Returns the content of the file from the given path as a string.
static func file_get_as_text(path: String) -> String:
	var file_access := FileAccess.open(path, FileAccess.READ)
	var content := file_access.get_as_text()
	file_access.close()
	return content


# Copies a file from a given src to the specified dst path.
# src = path/to/file.extension
# dst = other/path/to/file.extension
static func file_copy(src: String, dst: String) -> void:
	var dst_dir := dst.get_base_dir()

	if not DirAccess.dir_exists_absolute(dst_dir):
		DirAccess.make_dir_recursive_absolute(dst_dir)

	DirAccess.copy_absolute(src, dst)


# Log error messages
static func output_error(message) -> void:
	printerr("ModTool Error: " + str(message))


static func output_info(message) -> void:
	print("ModTool: " + str(message))


static func save_to_manifest_json(manifest_data: ModManifest, path_manifest: String) -> bool:
	var is_success := _ModLoaderFile._save_string_to_file(
		manifest_data.JSON.new().stringify(),
		path_manifest
	)

	if is_success:
		output_info("Successfully saved manifest.json file!")

	return is_success


static func make_dir_recursive(dst_dir: String) -> bool:
	var dir := DirAccess.open(dst_dir)
	var error := dir.make_dir_recursive(dst_dir)
	if error != OK:
		output_error("Failed creating directory at %s with error code %s" % [dst_dir, error])
		return false
	return true


# Takes a directory path to get removed.
# https://www.davidepesce.com/2019/11/04/essential-guide-to-godot-filesystem-api/
static func remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)

	if not directory:
		print("Error removing " + path)
		return

	# List directory content
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if directory.current_is_dir():
			remove_recursive(path + "/" + file_name)
		else:
			directory.remove(file_name)
		file_name = directory.get_next()

	# Remove current path
	directory.remove(path)


# Slightly modified version of:
# https://gist.github.com/willnationsdev/00d97aa8339138fd7ef0d6bd42748f6e
# Removed .import from the extension filter.
# p_match is a string that filters the list of files.
# If p_match_is_regex is false, p_match is directly string-searched against the FILENAME.
# If it is true, a regex object compiles p_match and runs it against the FILEPATH.
static func get_flat_view_dict(p_dir := "res://", p_match := "", p_match_is_regex := false, include_empty_dirs := false) -> PackedStringArray:
	var data: PackedStringArray = []
	var regex: RegEx

	if p_match_is_regex:
		regex = RegEx.new()
		var _compile_error: int = regex.compile(p_match)
		if not regex.is_valid():
			return data

	var dirs := [p_dir]
	var first := true
	while not dirs.is_empty():
		var dir_name : String = dirs.back()
		var dir := DirAccess.open(dir_name)
		dirs.pop_back()

		if dir:
			var _dirlist_error: int = dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			var file_name := dir.get_next()
			if include_empty_dirs and not dir_name == p_dir:
				data.append(dir_name)
			while file_name != "":
				if not dir_name == "res://":
					first = false
				# ignore hidden, temporary, or system content
				if not file_name.begins_with(".") and not file_name.get_extension() in ["tmp"]:
					# If a directory, then add to list of directories to visit
					if dir.current_is_dir():
						dirs.push_back(dir.get_current_dir() + "/" + file_name)
					# If a file, check if we already have a record for the same name
					else:
						var path := dir.get_current_dir() + ("/" if not first else "") + file_name
						# grab all
						if not p_match:
							data.append(path)
						# grab matching strings
						elif not p_match_is_regex and file_name.find(p_match, 0) != -1:
							data.append(path)
						# grab matching regex
						else:
							var regex_match := regex.search(path)
							if regex_match != null:
								data.append(path)
				# Move on to the next file in this directory
				file_name = dir.get_next()
			# We've exhausted all files in this directory. Close the iterator.
			dir.list_dir_end()
	return data
