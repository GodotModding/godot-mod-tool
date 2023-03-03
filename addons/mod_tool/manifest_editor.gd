tool
extends PanelContainer


var manifest_data: ModManifest
var manifest_data_dict: Dictionary
var input_fields := []

onready var v_box = $ScrollContainer/VBox
onready var input_name = $"%ModName"


func _ready():
	# Setup input fields
	for node in v_box.get_children():
		if node is InputString:
			input_fields.append(node)
			# Set up warning icons to show if a field is invalid
			node.set_error_icon(ModToolStore.base_theme.get_icon("NodeWarning", "EditorIcons"))


func load_manifest() -> void:
	var manifest_path := ModToolStore.path_mod_dir + "/manifest.json"

	manifest_data_dict = ModLoaderUtils.get_json_as_dict(manifest_path)
	manifest_data = ModManifest.new(manifest_data_dict)


func save_manifest() -> void:
	pass
	# TODO: Save manifest dict to manifest.json in mod directory


func is_manifest_valid() -> bool:
	var mod_manifest: Script
	if ModLoaderUtils.file_exists("res://addons/mod_loader/mod_manifest.gd"):
		mod_manifest = load("res://addons/mod_loader/mod_manifest.gd")

	var is_valid: bool
	if not mod_manifest:
		return false

	var mod_name: String = ModToolStore.name_mod_dir
	is_valid = input_name.show_error_if_not(mod_manifest.is_name_or_namespace_valid(mod_name))

	#todo

	return is_valid


func update_ui() -> void:
	var manifest_data_dict := manifest_data.get_as_dict()

	for input in input_fields:
		if manifest_data_dict.has(input.key):
			input.input_text = str(manifest_data_dict[input.key])
