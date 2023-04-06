tool
extends PanelContainer


var input_fields := []

onready var manifest_input_vbox := $"%InputVBox"


func _ready() -> void:
	$VBox/Panel.add_stylebox_override("panel", ModToolStore.base_theme.get_stylebox("bg", "ItemList"))
	# Setup input fields
	for node in manifest_input_vbox.get_children():
		if node is InputString:
			input_fields.append(node)


func load_manifest() -> void:
	var manifest_dict_json := ModLoaderUtils.get_json_as_dict(ModToolStore.path_manifest)
	ModToolStore.manifest_data = ModManifest.new(manifest_dict_json)
	ModToolUtils.output_info("Loaded manifest from " + ModToolStore.path_manifest)


func save_manifest() -> void:
	var invalid_inputs := get_invalid()

	if invalid_inputs.size() == 0:
		var _is_success := ModToolUtils.save_to_manifest_json()
	else:
		ModToolUtils.output_error('Invalid Manifest - Manifest not saved! Please check your inputs in the following fields -> ' + ", ".join(invalid_inputs))


func update_ui() -> void:
	# For each input field
	for input in input_fields:
		# Check if the key used in the InputString instance is in the data_dict.
		if ModToolStore.manifest_data.get(input.key):
			var value = ModToolStore.manifest_data.get(input.key)

			# If the value is an Array create a comma separated list
			if value is PoolStringArray:
				input.input_text = ", ".join(value)
			# Else convert the value to a string
			else:
				input.input_text = str(value)


# Returns an array of invalid fields
func get_invalid() -> Array:
	var invalid_fields := []

	for input in input_fields:
		if not input.is_valid:
			invalid_fields.append(input.label_text)

	return invalid_fields


func _update_manifest_value(input: InputString, new_value) -> void:
	ModToolStore.manifest_data.set(input.key, new_value)


# Validated StringInputs
# =============================================================================
func _on_ModName_input_text_changed(new_text: String, node: Node) -> void:
	if node.validate(ModManifest.is_name_or_namespace_valid(new_text, true)):
		_update_manifest_value(node, new_text)


func _on_Namespace_input_text_changed(new_text: String, node: InputString) -> void:
	if node.validate(ModManifest.is_name_or_namespace_valid(new_text, true)):
		_update_manifest_value(node, new_text)


func _on_Version_input_text_changed(new_text: String, node: InputString) -> void:
	if node.validate(ModManifest.is_semver_valid("", new_text, "version", true)):
		_update_manifest_value(node, new_text)


func _on_Dependencies_input_text_changed(new_text: String, node: InputString) -> void:
	var dependencies := node.get_array_from_comma_separated_string()
	if node.validate(ModManifest.validate_dependencies(ModToolStore.name_mod_dir, dependencies, true)):
		_update_manifest_value(node, dependencies)


func _on_Incompatibilities_input_text_changed(new_text: String, node: InputString) -> void:
	var incompatibilities := node.get_array_from_comma_separated_string()
	if node.validate(ModManifest.validate_incompatibilities(ModToolStore.name_mod_dir, incompatibilities, true)):
		_update_manifest_value(node, incompatibilities)


func _on_CompatibleModLoaderVersions_input_text_changed(new_text: String, node: InputString) -> void:
	var compatible_modloader_versions := node.get_array_from_comma_separated_string()
	if node.validate(ModManifest.is_semver_version_array_valid("", compatible_modloader_versions, "CompatibleModLoaderVersions", true)):
		_update_manifest_value(node, compatible_modloader_versions)


# Non Validated StringInputs
# =============================================================================
func _on_WebsiteUrl_input_text_changed(new_text: String, node: InputString) -> void:
	_update_manifest_value(node, new_text)


func _on_Description_input_text_changed(new_text: String, node: InputString) -> void:
	_update_manifest_value(node, new_text)


func _on_Authors_input_text_changed(new_text: String, node: InputString) -> void:
	var authors := node.get_array_from_comma_separated_string()
	_update_manifest_value(node, authors)


func _on_CompatibleGameVersions_input_text_changed(new_text: String, node: InputString) -> void:
	var compatible_game_versions := node.get_array_from_comma_separated_string()
	_update_manifest_value(node, compatible_game_versions)


func _on_Tags_input_text_changed(new_text: String, node: InputString) -> void:
	var tags := node.get_array_from_comma_separated_string()
	_update_manifest_value(node, tags)


func _on_SaveManifest_pressed() -> void:
	save_manifest()
