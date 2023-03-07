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
	var manifest_data_json := ModLoaderUtils.get_json_as_dict(manifest_path)

	manifest_data = ModManifest.new(manifest_data_json)
	manifest_data_dict = manifest_data.get_as_dict()


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
	for input in input_fields:
		if manifest_data_dict.has(input.key):
			var value = manifest_data_dict[input.key]

			if value is PoolStringArray:
				input.input_text = ", ".join(value)
			else:
				input.input_text = str(value)


func _handle_validation(input_node: InputString, condition: bool) -> void:
	# Check if input is optional and the field is empty
	if not input_node.is_required and input_node.get_value() == '':
		return

	var _condition := input_node.show_error_if_not(condition)


func _on_ModName_input_text_changed(new_text: String, node: Node) -> void:
	_handle_validation(node, ModManifest.is_name_or_namespace_valid(new_text, true))


func _on_Namespace_input_text_changed(new_text: String, node: Node) -> void:
	_handle_validation(node, ModManifest.is_name_or_namespace_valid(new_text, true))


func _on_Version_input_text_changed(new_text: String, node: Node) -> void:
	_handle_validation(node, ModManifest.is_semver_valid(new_text, true))


func _on_Dependencies_input_text_changed(new_text: String, node: Node) -> void:
	var dependencies := ModToolUtils.get_array_from_comma_separated_string(new_text)
	_handle_validation(node, ModManifest.validate_dependencies(ModToolStore.name_mod_dir, dependencies, true))


func _on_Incompatibilities_input_text_changed(new_text: String, node: Node) -> void:
	var incompatibilities := ModToolUtils.get_array_from_comma_separated_string(new_text)
	_handle_validation(node, ModManifest.validate_incompatibilities(ModToolStore.name_mod_dir, incompatibilities, true))


func _on_CompatibleModLoaderVersions_input_text_changed(new_text: String, node: Node) -> void:
	var compatible_modloader_versions := ModToolUtils.get_array_from_comma_separated_string(new_text)
	_handle_validation(node, ModManifest.is_semver_version_array_valid(compatible_modloader_versions, true))
