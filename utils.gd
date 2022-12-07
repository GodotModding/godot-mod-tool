extends Node

func zip_folder(src_path, dst_path):
	var writer = create_writer(dst_path)
	zip(writer, src_path, dst_path)
	close_writer(writer)

func create_writer(dst_path):
	var writer := ZIPPacker.new()
	writer.open(dst_path) # global path to the zip file
	
	return writer

func close_writer(writer):
	return writer.close()

func zip(writer, src_path, dst_path):
	var zip_name = dst_path.get_file().get_slice('.', 0)
	var src_path_split = src_path.split(zip_name, true, 1)
	var zip_path = str(zip_name, src_path_split[1])
	
	var directory = DirAccess.open(src_path)
	if(DirAccess.get_open_error() == OK):
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while (file_name != "" && file_name != "." && file_name != ".."):
			if(directory.current_is_dir()):
				zip(writer, src_path.path_join(file_name), dst_path)
			else:
				var current_src_file_path = str(src_path, '/', file_name)	
				var file = FileAccess.open(current_src_file_path, FileAccess.READ)
				var file_length = file.get_length()
				var file_content = file.get_buffer(file_length)
				
				
				var current_zip_file_path = str(zip_path, '/', file_name)
				writer.start_file(current_zip_file_path) # path inside the zip file
				writer.write_file(file_content)
				writer.close_file()
				
			file_name = directory.get_next()

func file_save(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(content))

func file_load(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return JSON.parse_string(content)
