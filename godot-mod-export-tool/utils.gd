extends Node
	
func create_writer(dst_path):
	var writer := ZIPPacker.new()
	writer.open(dst_path) # global path to the zip file
	
	return writer

func close_writer(writer):
	return writer.close()

func zip(writer, src_path, dst_path):
	var file = FileAccess.open(src_path, FileAccess.READ)
	var file_length = file.get_length()
	var file_content = file.get_buffer(file_length)
	
	writer.start_file(dst_path) # path inside the zip file
	writer.write_file(file_content)
	writer.close_file()

func is_file_extension(path, extensions):
	var is_extension = false
	
	for extension in extensions:
		var file_name = path.get_file()
		if(file_name.contains(extension)):
			is_extension = true
			break
		else:
			is_extension = false
			
	
	return is_extension

func is_file_there(path):
	return FileAccess.file_exists(path)

func is_dir_there(path):
	return DirAccess.dir_exists_absolute(path)

func get_entries(string) -> Array:
	var regex = RegEx.new()
	# https://stackoverflow.com/a/5001626
	regex.compile("[^,\\s][^\\,]*[^,\\s]*")
	var results = []
	for result in regex.search_all(string):
		results.push_back(result.get_string())
	return results

func get_regex_results(string, regex_exp: String):
	var regex = RegEx.new()
	regex.compile(regex_exp)
	var results = []
	for result in regex.search_all(string):
		results.push_back(result.get_string())
	return results

func file_copy(src, dst):
	# src -> path to some file
	# dst -> path to some dir
	
	var file_name = src.get_file()
	
	var file = FileAccess.open(src, FileAccess.READ)
	var file_length = file.get_length()
	var file_content = file.get_buffer(file_length)
	
	var dst_file_path = str(dst, "/", file_name)
	var file_new = FileAccess.open(dst_file_path, FileAccess.WRITE)
	file_new.store_buffer(file_content)

func file_save(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(content))

func file_load(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return JSON.parse_string(content)

func file_get_as_text(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return content

func file_save_as_text(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)

# https://gist.github.com/willnationsdev/00d97aa8339138fd7ef0d6bd42748f6e
# p_match is a string that filters the list of files.
# If p_match_is_regex is false, p_match is directly string-searched against the FILENAME.
# If it is true, a regex object compiles p_match and runs it against the FILEPATH.
func get_flat_view_dict(p_dir = "res://", p_match = "", p_match_is_regex = false):
	var regex = null
	if p_match_is_regex:
		regex = RegEx.new()
		regex.compile(p_match)
		if not regex.is_valid():
			return []

	var dirs = [p_dir]
	var first = true
	var data = []
	while not dirs.is_empty():
		var dir_name = dirs.back()
		dirs.pop_back()

		var dir = DirAccess.open(dir_name)
		if(DirAccess.get_open_error() == OK):
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir_name == "res://":
					first = false
				# If a directory, then add to list of directories to visit
				if dir.current_is_dir():
					dirs.push_back(dir.get_current_dir() + "/" + file_name)
				# If a file, check if we already have a record for the same name
				else:
					var path = dir.get_current_dir() + ("/" if not first else "") + file_name
					# grab all
					if p_match == "":
						data.append(path)
					# grab matching strings
					elif p_match_is_regex == false && file_name.find(p_match, 0) != -1:
						data.append(path)
					# grab matching regex
					elif p_match_is_regex == true:
						var regex_match = regex.search(path)
						if regex_match != null:
							data.append(path)
				# Move on to the next file in this directory
				file_name = dir.get_next()
			# We've exhausted all files in this directory. Close the iterator.
			dir.list_dir_end()
	return data
