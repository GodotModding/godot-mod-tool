extends Node

func zip_folder(src_path, dst_path, extensions_excluded):
	var writer = create_writer(dst_path)
	zip(writer, src_path, dst_path, extensions_excluded)
	close_writer(writer)

func create_writer(dst_path):
	var writer := ZIPPacker.new()
	writer.open(dst_path) # global path to the zip file
	
	return writer

func close_writer(writer):
	return writer.close()

func zip(writer, src_path, dst_path, extensions_excluded = []):
	var zip_name = dst_path.get_file().get_slice('.', 0)
	var src_path_split = src_path.split(zip_name, true, 1)
	var zip_path = str(zip_name, src_path_split[1])
	
	var directory = DirAccess.open(src_path)
	if(DirAccess.get_open_error() == OK):
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while (file_name != "" && file_name != "." && file_name != ".."):
			# If it is a directory - call the function again with the current directory name as src_path
			if(directory.current_is_dir()):
				zip(writer, src_path.path_join(file_name), dst_path, extensions_excluded)
			# If it is a file - add it to the zip archive
			else:
				var current_src_file_path = str(src_path, '/', file_name)
				# check for excluded extensions
				if(is_file_extension(current_src_file_path, extensions_excluded)):
					file_name = directory.get_next()
					continue
				
				var file = FileAccess.open(current_src_file_path, FileAccess.READ)
				var file_length = file.get_length()
				var file_content = file.get_buffer(file_length)
				
				
				var current_zip_file_path = str(zip_path, '/', file_name)
				writer.start_file(current_zip_file_path) # path inside the zip file
				writer.write_file(file_content)
				writer.close_file()
				
			file_name = directory.get_next()

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

func get_entries(string) -> Array:
	var regex = RegEx.new()
	# https://stackoverflow.com/a/5001626
	regex.compile("[^,\\s][^\\,]*[^,\\s]*")
	var results = []
	for result in regex.search_all(string):
		results.push_back(result.get_string())
	return results

func file_save(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(content))

func file_load(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return JSON.parse_string(content)
