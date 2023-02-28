tool
extends EditorPlugin

var dock: Control


func _enter_tree() -> void:
	add_autoload_singleton('ModToolStore', "res://addons/mod_tool/store.gd")
	dock = preload("res://addons/mod_tool/dock.tscn").instance()
	dock.editor_interface = get_editor_interface()
	dock.editor_interface = get_editor_interface()
	add_control_to_bottom_panel(dock, 'Mod Tool')


func _exit_tree() -> void:
	remove_autoload_singleton('ModToolStore')
	remove_control_from_bottom_panel(dock)
	dock.free()
