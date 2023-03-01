extends PanelContainer


onready var input_mod_name := $"%ModName"


func load_manifest() -> void:
	pass
	# load manifest.json from mod directory


func save_manifest() -> void:
	pass
	# save manifest dict to manifest.json in mod directory


func is_manifest_valid() -> bool:
	var mod_manifest: Script
	if ModLoaderUtils.file_exists("res://addons/mod_loader/mod_manifest.gd"):
		mod_manifest = load("res://addons/mod_loader/mod_manifest.gd")

	var is_valid: bool
	if not mod_manifest:
		return false

	var mod_name: String = ModToolStore.name_mod_dir
	is_valid = input_mod_name.show_error_if_not(mod_manifest.is_name_or_namespace_valid(mod_name))

	#todo

	return is_valid


func update_ui() -> void:
	pass
