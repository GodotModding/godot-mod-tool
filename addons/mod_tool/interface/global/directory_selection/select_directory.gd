tool
extends WindowDialog


signal dir_selected(dir_path)

export(PackedScene) var btn_dir_scene

onready var directory_list: VBoxContainer = $"%DirectoryList"


func generate_dir_buttons(dir_path: String) -> void:
	clear_directory_list()
	var dir_paths := _ModLoaderPath.get_dir_paths_in_dir(dir_path)

	for dir_path in dir_paths:
		var dir_name: String = dir_path.split('/')[-1]

		var dir_btn: ModToolDirSelectButton = btn_dir_scene.instance()
		dir_btn.text = dir_name
		dir_btn.path = dir_path

		directory_list.add_child(dir_btn)
		dir_btn.connect("dir_selected", self, "_on_dir_btn_dir_selected")


func clear_directory_list() -> void:
	for child in directory_list.get_children():
		directory_list.remove_child(child)
		child.queue_free()


func _on_dir_btn_dir_selected(path: String) -> void:
	emit_signal("dir_selected", path)
