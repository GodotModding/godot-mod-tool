tool
extends PanelContainer


var input_fields := []

onready var v_box := $ScrollContainer/VBox
onready var input_name := $"%ModName"


func _ready():
	# Setup input fields
	for node in v_box.get_children():
		if node is InputString:
			input_fields.append(node)
			# Set up warning icons to show if a field is invalid
			node.set_error_icon(ModToolStore.base_theme.get_icon("NodeWarning", "EditorIcons"))


func load_manifest() -> void:
	ModToolStore.manifest_dict_json = ModLoaderUtils.get_json_as_dict(ModToolStore.path_manifest)
	ModToolStore.manifest_data = ModManifest.new(ModToolStore.manifest_dict_json)
	ModToolStore.manifest_dict = ModToolStore.manifest_data.get_as_dict()
	ModToolUtils.output_info("Loaded manifest from " + ModToolStore.path_manifest)


func save_manifest() -> void:
	var _is_success := ModToolUtils.save_to_manifest_json()


func update_ui() -> void:
	# For each input field
	for input in input_fields:
		# Check if the key used in the InputString instance is in the data_dict.
		if ModToolStore.manifest_dict.has(input.key):
			var value = ModToolStore.manifest_dict[input.key]

			# If the value is an Array create a comma separated list
			if value is PoolStringArray:
				input.input_text = ", ".join(value)
			# Else convert the value to a string
			else:
				input.input_text = str(value)


func _handle_validation(input_node: InputString, condition: bool) -> bool:
	# Check if input is optional and the field is empty
	if not input_node.is_required and input_node.get_value() == '':
		return true

	# Just returns the condition
	return input_node.show_error_if_not(condition)


func _update_manifest_value(input: InputString, new_value) -> void:
	ModToolStore.manifest_data.set(input.key, new_value)


# Validated StringInputs
# =============================================================================
func _on_ModName_input_text_changed(new_text: String, node: Node) -> void:
	if _handle_validation(node, ModManifest.is_name_or_namespace_valid(new_text, true)):
		_update_manifest_value(node, new_text)


func _on_Namespace_input_text_changed(new_text: String, node: Node) -> void:
	if _handle_validation(node, ModManifest.is_name_or_namespace_valid(new_text, true)):
		_update_manifest_value(node, new_text)

func _on_Version_input_text_changed(new_text: String, node: Node) -> void:
	if _handle_validation(node, ModManifest.is_semver_valid(new_text, true)):
		_update_manifest_value(node, new_text)


func _on_Dependencies_input_text_changed(new_text: String, node: Node) -> void:
	var dependencies := ModToolUtils.get_array_from_comma_separated_string(new_text)
	if _handle_validation(node, ModManifest.validate_dependencies(ModToolStore.name_mod_dir, dependencies, true)):
		_update_manifest_value(node, dependencies)


func _on_Incompatibilities_input_text_changed(new_text: String, node: Node) -> void:
	var incompatibilities := ModToolUtils.get_array_from_comma_separated_string(new_text)
	if _handle_validation(node, ModManifest.validate_incompatibilities(ModToolStore.name_mod_dir, incompatibilities, true)):
		_update_manifest_value(node, incompatibilities)


func _on_CompatibleModLoaderVersions_input_text_changed(new_text: String, node: Node) -> void:
	var compatible_modloader_versions := ModToolUtils.get_array_from_comma_separated_string(new_text)
	if _handle_validation(node, ModManifest.is_semver_version_array_valid(compatible_modloader_versions, true)):
		_update_manifest_value(node, compatible_modloader_versions)


# Non Validated StringInputs
# =============================================================================
func _on_WebsiteUrl_input_text_changed(new_text: String, node: Node):
	_update_manifest_value(node, new_text)


func _on_Description_input_text_changed(new_text: String, node: Node):
	_update_manifest_value(node, new_text)


func _on_Authors_input_text_changed(new_text: String, node: Node):
	var authors := ModToolUtils.get_array_from_comma_separated_string(new_text)
	_update_manifest_value(node, authors)


func _on_CompatibleGameVersions_input_text_changed(new_text: String, node: Node):
	var compatible_game_versions := ModToolUtils.get_array_from_comma_separated_string(new_text)
	_update_manifest_value(node, compatible_game_versions)


func _on_Tags_input_text_changed(new_text: String, node: Node):
	var tags := ModToolUtils.get_array_from_comma_separated_string(new_text)
	_update_manifest_value(node, tags)


func _on_SaveManifest_pressed():
	save_manifest()
