tool
extends MarginContainer


var store: ModToolStore setget set_store

onready var mod_id = $"%ModId"


func set_store(_store):
	store = _store
	if store.base_theme:
		mod_id.set_error_icon(store.base_theme.get_icon("NodeWarning", "EditorIcons"))
		mod_id.show_error_if_not(false)


func add_mod() -> void:
	# Validate mod-id
	if not ModToolUtils.validate_mod_dir_name(store.name_mod_dir):
		ModToolUtils.output_error(store, 'Invalid name or namespace: "%s". You may only use letters, numbers, underscores and at least 3 characters for each.' % store.name_mod_dir)

	# Add mod dir to mods-unpacked
		# Check if mods-unpacked dir exists
		# If not create it

		# Check if mod dir exists
			# If not - create it
			# If so - show error and ask if user wants to connect with the mod instead

	# Create mod_main.gd

	# Create manifest.json


func _on_btn_create_mod_pressed():
	add_mod()
