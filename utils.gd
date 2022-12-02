extends Node

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
