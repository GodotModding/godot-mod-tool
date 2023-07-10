tool
extends EditorPlugin

var mod_tool_store
var tools_panel

func _enter_tree() -> void:
	mod_tool_store = preload("res://addons/mod_tool/global/store.gd").new() as ModToolStore
	mod_tool_store.name = "ModToolStore"
	get_tree().root.call_deferred("add_child", mod_tool_store, true)


	tools_panel = preload("res://addons/mod_tool/interface/panel/tools_panel.tscn").instance() as ModToolsPanel
	tools_panel.mod_tool_store = mod_tool_store
	tools_panel.editor_plugin = self
	get_editor_interface().get_editor_viewport().call_deferred("add_child", tools_panel, true)
	make_visible(false)


func _exit_tree() -> void:
	if mod_tool_store:
		mod_tool_store.queue_free()

	if tools_panel:
		tools_panel.free()


func make_visible(visible):
	if tools_panel:
		tools_panel.visible = visible


func has_main_screen():
	return true


func get_plugin_name():
	return "Mod Tool"


func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("Tools", "EditorIcons")

