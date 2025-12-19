class_name ModToolSteamWorkshopUploader
extends Reference


signal created(result, file_id, need_to_accept_tos)
signal updated(result, need_to_accept_tos)

var steam = Engine.get_singleton("Steam")
var mod_tool_store: ModToolStore


func _init(_mod_tool_store: ModToolStore) -> void:
	mod_tool_store = _mod_tool_store
	Steam.connect("item_updated", self, "_on_item_updated")
	Steam.connect("item_created", self, "_on_item_created")


func update() -> int:
	ModToolUtils.output_info("Starting update process for workshop item %s" % mod_tool_store.steam_selected_file_id)
	var update_handle := Steam.startItemUpdate(mod_tool_store.steam_app_id, mod_tool_store.steam_selected_file_id)
	Steam.setItemTitle(update_handle, mod_tool_store.steam_mod_data.title)
	Steam.setItemDescription(update_handle, mod_tool_store.steam_mod_data.description)

	if mod_tool_store.steam_mod_data.preview_file_path:
		Steam.setItemPreview(update_handle, mod_tool_store.steam_mod_data.preview_file_path)

	Steam.setItemContent(update_handle, mod_tool_store.path_global_final_zip)
	Steam.submitItemUpdate(update_handle, "")

	return update_handle


func create() -> void:
		Steam.createItem(mod_tool_store.steam_app_id, Steam.WORKSHOP_FILE_TYPE_COMMUNITY)


func _on_item_updated(result: int, need_to_accept_tos: bool) -> void:
		emit_signal("updated", result, need_to_accept_tos)


func _on_item_created(result: int, file_id: int, accept_tos: bool) -> void:
	if result == Steam.RESULT_OK:
		mod_tool_store.steam_selected_file_id = file_id
		mod_tool_store.manifest_data.steam_workshop_id = file_id
		emit_signal("created", result, file_id, accept_tos)
		update()
	else:
		emit_signal("created", result, file_id, accept_tos)
