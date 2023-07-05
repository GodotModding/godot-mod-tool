tool
class_name ModToolDirSelectButton
extends Button


signal dir_selected(path)

var path: String


func _on_BtnDirectory_pressed() -> void:
	emit_signal("dir_selected", path)
