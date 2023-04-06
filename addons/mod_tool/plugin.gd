tool
extends EditorPlugin

var tools_panel: Control


func _enter_tree() -> void:
	add_autoload_singleton('ModToolStore', "res://addons/mod_tool/global/store.gd")

	tools_panel = preload("res://addons/mod_tool/interface/panel/tools_panel.tscn").instance()
	tools_panel.editor_plugin = self
	get_editor_interface().get_editor_viewport().add_child(tools_panel)
	make_visible(false)


func _exit_tree() -> void:
	if tools_panel:
		tools_panel.context_actions.free()
		tools_panel.free()

	remove_autoload_singleton('ModToolStore')


func make_visible(visible):
	if tools_panel:
		tools_panel.visible = visible


func has_main_screen():
	return true


func get_plugin_name():
	return "Mod Tool"


func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("Tools", "EditorIcons")

