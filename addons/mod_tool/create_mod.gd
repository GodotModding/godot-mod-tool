tool
extends MarginContainer


signal mod_dir_created

onready var mod_id := $Settings/Scroll/VBox/ModId


func _ready() -> void:
	mod_id.set_error_icon(ModToolStore.base_theme.get_icon("NodeWarning", "EditorIcons"))
	mod_id.show_error_if_not(false)


func add_mod() -> void:
	# Validate mod-id
	if not ModManifest.is_mod_id_valid(ModToolStore.name_mod_dir, ModToolStore.name_mod_dir, "", true):
		ModToolUtils.output_error('Invalid name or namespace: "%s". You may only use letters, numbers, underscores and at least 3 characters for each.' % ModToolStore.name_mod_dir)
		return

	# Check if mods-unpacked dir exists
	if not ModLoaderUtils.dir_exists("res://mods-unpacked"):
		# If not create it
		var success := ModToolUtils.make_dir_recursive("res://mods-unpacked")
		if not success:
			return

	# Check if mod dir exists
	if not ModLoaderUtils.dir_exists(ModToolStore.path_mod_dir):
		# If not - create it
		var success := ModToolUtils.make_dir_recursive(ModToolStore.path_mod_dir)
		if not success:
			return

		# Create mod_main.gd
		ModToolUtils.file_copy(ModToolStore.PATH_TEMPLATES_DIR + "mod_main.gd", ModToolStore.path_mod_dir + "/mod_main.gd")

		# Create manifest.json
		ModToolUtils.file_copy(ModToolStore.PATH_TEMPLATES_DIR + "manifest.json", ModToolStore.path_mod_dir + "/manifest.json")

		# Update FileSystem
		ModToolStore.editor_file_system.scan()

		# Output info
		ModToolUtils.output_info("Added base mod files to " + ModToolStore.path_mod_dir)
	else:
		# If so - show error and ask if user wants to connect with the mod instead
		ModToolUtils.output_error("Mod directory at %s already exists." % ModToolStore.path_mod_dir)
		# TODO: Ask user to connect with the mod instead
		return


func clear_mod_id_input() -> void:
	mod_id.input_text = ""


func _on_btn_create_mod_pressed() -> void:
	add_mod()
	emit_signal("mod_dir_created")

