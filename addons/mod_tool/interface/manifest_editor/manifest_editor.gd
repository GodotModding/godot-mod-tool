tool
extends PanelContainer


var input_fields := []

onready var manifest_input_vbox := $"%InputVBox"
onready var incompatibilities: ModToolInterfaceInputString = $"%Incompatibilities"
onready var dependencies: ModToolInterfaceInputString = $"%Dependencies"
onready var optional_dependencies: ModToolInterfaceInputString = $"%OptionalDependencies"


func _ready() -> void:
	$VBox/Panel.add_stylebox_override("panel", ModToolStore.base_theme.get_stylebox("bg", "ItemList"))
	# Setup input fields
	for node in manifest_input_vbox.get_children():
		if node is ModToolInterfaceInputString:
			input_fields.append(node)


func load_manifest() -> void:
	var manifest_dict_json := _ModLoaderFile.get_json_as_dict(ModToolStore.path_manifest)
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
		# Check if the key used in the ModToolInterfaceInputString instance is in the data_dict.
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


func _update_manifest_value(input: ModToolInterfaceInputString, new_value) -> void:
	if ModToolStore.manifest_data:
		ModToolStore.manifest_data.set(input.key, new_value)


func _on_SaveManifest_pressed() -> void:
	save_manifest()


# Validated StringInputs
# =============================================================================


func _on_ModName_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	if input_node.validate(ModManifest.is_name_or_namespace_valid(new_text, true)):
		_update_manifest_value(input_node, new_text)


func _on_Namespace_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	if input_node.validate(ModManifest.is_name_or_namespace_valid(new_text, true)):
		_update_manifest_value(input_node, new_text)


func _on_Version_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	if input_node.validate(ModManifest.is_semver_valid("", new_text, "version", true)):
		_update_manifest_value(input_node, new_text)


func _on_Dependencies_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var dependencies := input_node.get_input_as_array_from_comma_separated_string()
	var is_id_array_valid := ModManifest.is_mod_id_array_valid(ModToolStore.name_mod_dir, dependencies, "dependencies", true)
	var is_distinct_mod_id_incompatibilities := ModManifest.validate_distinct_mod_ids_in_arrays(
			ModToolStore.name_mod_dir,
			dependencies,
			ModToolStore.manifest_data.incompatibilities,
			["dependencies", "incompatibilities"],
			"",
			true
		)
	var is_distinct_mod_id_optional_dependencies := ModManifest.validate_distinct_mod_ids_in_arrays(
			ModToolStore.name_mod_dir,
			dependencies,
			ModToolStore.manifest_data.optional_dependencies,
			["dependencies", "optional_dependencies"],
			"",
			true
		)

	if not is_distinct_mod_id_incompatibilities:
		# Set incompatibilities and dependencies to invalid if distinct_mod_id validation fails
		incompatibilities.validate(false)
		input_node.validate(false)

	if not is_distinct_mod_id_optional_dependencies:
		# Set optional_dependencies and dependencies to invalid if distinct_mod_id validation fails
		optional_dependencies.validate(false)
		input_node.validate(false)

	if input_node.validate(
		is_id_array_valid and
		is_distinct_mod_id_incompatibilities and
		is_distinct_mod_id_optional_dependencies
	):
		# Re validate icompatibilities and optional_dependencies if validation passes
		if not incompatibilities.is_valid:
			incompatibilities.emit_value_changed()
		if not optional_dependencies.is_valid:
			optional_dependencies.emit_value_changed()

		_update_manifest_value(input_node, dependencies)


func _on_OptionalDependencies_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var optional_dependencies := input_node.get_input_as_array_from_comma_separated_string()
	var is_id_array_valid := ModManifest.is_mod_id_array_valid(ModToolStore.name_mod_dir, optional_dependencies, "optional_dependencies", true)
	var is_distinct_mod_id_incompatibilities := ModManifest.validate_distinct_mod_ids_in_arrays(
			ModToolStore.name_mod_dir,
			optional_dependencies,
			ModToolStore.manifest_data.incompatibilities,
			["optional_dependencies", "incompatibilities"],
			"",
			true
		)
	var is_distinct_mod_id_dependencies := ModManifest.validate_distinct_mod_ids_in_arrays(
			ModToolStore.name_mod_dir,
			optional_dependencies,
			ModToolStore.manifest_data.dependencies,
			["optional_dependencies", "dependencies"],
			"",
			true
		)

	if not is_distinct_mod_id_incompatibilities:
		# Set incompatibilities and optional_dependencies to invalid if distinct_mod_id validation fails
		incompatibilities.validate(false)
		input_node.validate(false)

	if not is_distinct_mod_id_dependencies:
		# Set dependencies and optional_dependencies to invalid if distinct_mod_id validation fails
		dependencies.validate(false)
		input_node.validate(false)

	if input_node.validate(
		is_id_array_valid and
		is_distinct_mod_id_incompatibilities and
		is_distinct_mod_id_dependencies
	):
		# Re validate icompatibilities and dependencies if validation passes
		if not incompatibilities.is_valid:
			incompatibilities.emit_value_changed()
		if not dependencies.is_valid:
			dependencies.emit_value_changed()

		_update_manifest_value(input_node, optional_dependencies)


func _on_CompatibleModLoaderVersions_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var compatible_modloader_versions := input_node.get_input_as_array_from_comma_separated_string()
	if input_node.validate(ModManifest.is_semver_version_array_valid(ModToolStore.name_mod_dir, compatible_modloader_versions, "Compatible ModLoader Versions", true)):
		_update_manifest_value(input_node, compatible_modloader_versions)


func _on_Incompatibilities_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var incompatibilities := input_node.get_input_as_array_from_comma_separated_string()
	var is_mod_id_array_valid := ModManifest.is_mod_id_array_valid(ModToolStore.name_mod_dir, incompatibilities, "incompatibilities", true)
	var is_distinct_mod_id_dependencies := ModManifest.validate_distinct_mod_ids_in_arrays(
			ModToolStore.name_mod_dir,
			ModToolStore.manifest_data.dependencies,
			incompatibilities,
			["dependencies", "incompatibilities"],
			"",
			true
		)
	var is_distinct_mod_id_optional_dependencies := ModManifest.validate_distinct_mod_ids_in_arrays(
			ModToolStore.name_mod_dir,
			ModToolStore.manifest_data.optional_dependencies,
			incompatibilities,
			["optional_dependencies", "incompatibilities"],
			"",
			true
		)

	if not is_distinct_mod_id_dependencies:
		dependencies.validate(false)
		input_node.validate(false)

	if not is_distinct_mod_id_optional_dependencies:
		optional_dependencies.validate(false)
		input_node.validate(false)

	if input_node.validate(
		is_mod_id_array_valid and
		is_distinct_mod_id_dependencies and
		is_distinct_mod_id_optional_dependencies
	):
		# Re validate dependencies and optional_dependencies if incompatibilities are valid
		if not dependencies.is_valid:
			dependencies.emit_value_changed()
		if not optional_dependencies.is_valid:
			optional_dependencies.emit_value_changed()

		_update_manifest_value(input_node, incompatibilities)


func _on_LoadBefore_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var load_before := input_node.get_input_as_array_from_comma_separated_string()
	var is_mod_id_array_valid := ModManifest.is_mod_id_array_valid(ModToolStore.name_mod_dir, load_before, "load_before", true)
	var is_distinct_mod_id_dependencies := ModManifest.validate_distinct_mod_ids_in_arrays(
			ModToolStore.name_mod_dir,
			load_before,
			ModToolStore.manifest_data.dependencies,
			["load_before", "dependencies"],
			"\"load_before\" should be handled as optional dependency adding it to \"dependencies\" will cancel out the desired effect.",
			true
		)
	var is_distinct_mod_id_optional_dependencies := ModManifest.validate_distinct_mod_ids_in_arrays(
			ModToolStore.name_mod_dir,
			load_before,
			ModToolStore.manifest_data.optional_dependencies,
			["load_before", "optional_dependencies"],
			"\"load_before\" can be viewed as optional dependency, please remove the duplicate mod-id.",
			true
		)

	if not is_distinct_mod_id_dependencies:
		dependencies.validate(false)
		input_node.validate(false)

	if not is_distinct_mod_id_optional_dependencies:
		optional_dependencies.validate(false)
		input_node.validate(false)

	if input_node.validate(
		is_mod_id_array_valid and
		is_distinct_mod_id_dependencies and
		is_distinct_mod_id_optional_dependencies
	):
		# Re validate dependencies and optional_dependencies if validation passes
		if not dependencies.is_valid:
			dependencies.emit_value_changed()
		if not optional_dependencies.is_valid:
			optional_dependencies.emit_value_changed()

		_update_manifest_value(input_node, load_before)


# Non Validated StringInputs
# =============================================================================


func _on_WebsiteUrl_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	_update_manifest_value(input_node, new_text)


func _on_Description_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	_update_manifest_value(input_node, new_text)


func _on_Authors_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	_update_manifest_value(input_node, new_text)


func _on_CompatibleGameVersions_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var authors := input_node.get_input_as_array_from_comma_separated_string()
	_update_manifest_value(input_node, authors)


func _on_Tags_value_changed(new_text: String, input_node: ModToolInterfaceInputString) -> void:
	var tags := input_node.get_input_as_array_from_comma_separated_string()
	_update_manifest_value(input_node, tags)
