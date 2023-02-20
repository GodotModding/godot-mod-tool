extends Node
class_name ModToolUtils


# Takes a file path and an array of file extensions [.txt, .tscn, ..]
static func is_file_extension(path, excluded_extensions):
	var is_extension = false

	for extension in excluded_extensions:
		var file_name = path.get_file()
		if(extension in file_name):
			is_extension = true
			break
		else:
			is_extension = false


	return is_extension


static func file_get_as_text(path):
	var file_access = File.new()
	file_access.open(path, file_access.READ)
	var content = file_access.get_as_text()
	file_access.close()
	return content


static func get_regex_results(string, regex_exp: String):
	var regex = RegEx.new()
	regex.compile(regex_exp)
	var results = []
	for result in regex.search_all(string):
		results.push_back(result.get_string())
	return results


# Get the path to a local folder. Primarily used to get the  (packed) mods
# folder, ie "res://mods" or the OS's equivalent, as well as the configs path
static func get_local_folder_dir(subfolder: String = "") -> String:
	var game_install_directory := OS.get_executable_path().get_base_dir()

	if OS.get_name() == "OSX":
		game_install_directory = game_install_directory.get_base_dir().get_base_dir()

	# Fix for running the game through the Godot editor (as the EXE path would be
	# the editor's own EXE, which won't have any mod ZIPs)
	# if OS.is_debug_build():
	if OS.has_feature("editor"):
		game_install_directory = "res://"

	return game_install_directory.plus_file(subfolder)


static func file_copy(src: String, dst: String) -> void:
	var file := File.new()
	var dir := Directory.new()
	var dst_dir = dst.get_base_dir()


	file.open(src, File.READ)
	var file_length = file.get_len()
	var file_content = file.get_buffer(file_length)
	file.close()

	if not dir.dir_exists(dst_dir):
		dir.make_dir_recursive(dst_dir)


	file.open(dst, File.WRITE)
	file.store_buffer(file_content)
	file.close()


# https://www.davidepesce.com/2019/11/04/essential-guide-to-godot-filesystem-api/
static func remove_recursive(path):
	var directory = Directory.new()

	# Open directory
	var error = directory.open(path)
	if error == OK:
		# List directory content
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				remove_recursive(path + "/" + file_name)
			else:
				directory.remove(file_name)
			file_name = directory.get_next()

		# Remove current path
		directory.remove(path)
	else:
		print("Error removing " + path)


# https://gist.github.com/willnationsdev/00d97aa8339138fd7ef0d6bd42748f6e
# p_match is a string that filters the list of files.
# If p_match_is_regex is false, p_match is directly string-searched against the FILENAME.
# If it is true, a regex object compiles p_match and runs it against the FILEPATH.
static func get_flat_view_dict(p_dir = "res://", p_match = "", p_match_is_regex = false):
	var regex = null
	if p_match_is_regex:
		regex = RegEx.new()
		regex.compile(p_match)
		if not regex.is_valid():
			print("regex failed to compile")
			return []

	var dirs = [p_dir]
	var first = true
	var data = []
	while not dirs.empty():
		var dir = Directory.new()
		var dir_name = dirs.back()
		dirs.pop_back()

		if dir.open(dir_name) == OK:
			dir.list_dir_begin()
			var file_name = dir.get_next()
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
						var path = dir.get_current_dir() + ("/" if not first else "") + file_name
						# grab all
						if not p_match:
							data.append(path)
						# grab matching strings
						elif not p_match_is_regex and file_name.find(p_match, 0) != -1:
							data.append(path)
						# grab matching regex
						else:
							var regex_match = regex.search(path)
							if regex_match != null:
								data.append(path)
				# Move on to the next file in this directory
				file_name = dir.get_next()
			# We've exhausted all files in this directory. Close the iterator.
			dir.list_dir_end()
	return data
