extends Node

const MOD_NAME = "otDan-GodotExplorer"

var scene_navigator

func _init(modLoader = ModLoader):
	modLoader.mod_log("Init Godot Explorer.", MOD_NAME)
	
func _ready():
	ModLoader.mod_log("Readying Godot Explorer.", MOD_NAME)
	# Atache display to root
	var scene_navigator_instance = load("res://mods-unpacked/otDan-GodotExplorerV1/SceneNavigator.tscn").instance()
	get_tree().root.call_deferred("add_child", scene_navigator_instance)

	ModLoader.mod_log("Attached scene viewer to root", MOD_NAME)
