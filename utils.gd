extends Node

func zip_folder(src_path, dst_path):
	# src_path = C:\Users\Kai\Documents\godot\godot-samples\Brotato\ModLoader\ModLoader\KANAMultiRes
	# dst_path = C:\Program Files (x86)\Steam\steamapps\common\Brotato\mods\KANAMultiRes.zip
	var zip_name = dst_path.get_file().get_slice('.', 0)
	var src_path_split = src_path.split(zip_name, true, 1)
	var zip_path = str(zip_name, src_path_split[1])
	
	var writer := ZIPPacker.new()

	var err := writer.open(dst_path) # global path to the zip file
	
	var directory = DirAccess.open(src_path)
	if(DirAccess.get_open_error() == OK):
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while (file_name != "" && file_name != "." && file_name != ".."):
			if(directory.current_is_dir()):
				zip_folder(src_path.path_join(file_name), dst_path)
			else:
				var current_src_file_path = str(src_path, '/', file_name)
				print("current src_path -> ", current_src_file_path)
				var current_zip_file_path = str(zip_path, '/', file_name)
				print("writing to .zip -> ", current_zip_file_path)
				writer.start_file(current_zip_file_path) # path inside the zip file
				var file = FileAccess.open(current_src_file_path, FileAccess.READ)
				var file_content = file.get_as_text()
				writer.write_file(file_content.to_utf8_buffer())
				
				writer.close_file()
			file_name = directory.get_next()
	
	writer.close()

func write_zip_file():
	var writer := ZIPPacker.new()
	var err := writer.open("data.game_folder.path_join(data.game_mod_folder)")
	if err != OK:
		return err
	
	writer.start_file("hello.txt")
	writer.write_file("Hello World".to_utf8_buffer())
	writer.close_file()

	writer.close()
	return OK

# func by https://www.reddit.com/user/Rubonnek/ - https://www.reddit.com/r/godot/comments/qtre01/comment/hklrc64/?utm_source=share&utm_medium=web2x&context=3
func copy_directory_recursively(p_from : String, p_to : String) -> void:
	if not DirAccess.dir_exists_absolute(p_to):
		DirAccess.make_dir_recursive_absolute(p_to)
	var directory = DirAccess.open(p_from)
	if DirAccess.get_open_error() == OK:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while (file_name != "" && file_name != "." && file_name != ".."):
			if directory.current_is_dir():
				copy_directory_recursively(p_from + "/" + file_name, p_to + "/" + file_name)
			else:
				directory.copy(p_from + "/" + file_name, p_to + "/" + file_name)
			file_name = directory.get_next()
	else:
		push_warning("Error copying " + p_from + " to " + p_to)

func file_save(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(content))

func file_load(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return JSON.parse_string(content)
