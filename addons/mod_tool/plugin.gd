tool
extends EditorPlugin

var dock: Control


func _enter_tree() -> void:
	add_autoload_singleton('ModToolStore', "res://addons/mod_tool/global/store.gd")

	dock = preload("res://addons/mod_tool/interface/dock/dock.tscn").instance()
	dock.editor_plugin = self
	add_control_to_bottom_panel(dock, 'Mod Tool')


func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.context_actions.free()
	dock.free()
	remove_autoload_singleton('ModToolStore')
