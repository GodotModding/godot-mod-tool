tool
extends EditorPlugin

var dock: Control


func _enter_tree() -> void:
	dock = preload("res://addons/mod_tool/dock.tscn").instance()
	dock.editor_interface = get_editor_interface()
	dock.editor_interface = get_editor_interface()
	dock.store.load_store()
	add_control_to_bottom_panel(dock, 'Mod Tool')


func _exit_tree() -> void:
	dock.store.save_store()
	remove_control_from_bottom_panel(dock)
	dock.free()
