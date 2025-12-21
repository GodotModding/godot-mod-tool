tool
extends PanelContainer


signal steam_inited
signal steam_preview_image_button_pressed
signal local_mod_selection_changed(name_mod_dir)
signal linked_mod

onready var mod_tool_store = get_node_or_null("/root/ModToolStore")

onready var input_steam_app_id: HBoxContainer = $"%SteamAppID"
onready var input_title: HBoxContainer = $"%Title"
onready var input_description: HBoxContainer = $"%Description"
onready var link_mod: HBoxContainer = $"%LinkMod"
onready var steam_state: CheckButton = $"%SteamState"
onready var preview_image: HBoxContainer = $"%PreviewImage"
onready var preview_image_preview: TextureRect = $"%PreviewImagePreview"
onready var button_open_workshop_page: Button = $"%ButtonOpenWorkshopPage"
onready var tags: HBoxContainer = $"%Tags"


var steam = Engine.get_singleton("Steam")
var query_handle: int
var workshop_mods := {}
var preview_image_placeholder = preload("res://addons/mod_tool/interface/steam_workshop_editor/preview_image.png")


func _ready() -> void:
	input_steam_app_id.set_input_text(str(mod_tool_store.steam_app_id))
	link_mod.set_input_options_left(PoolStringArray(["steam not initialized"]))
	link_mod.set_input_disabled_left(true)
	link_mod.set_button_disabled(true)
	update_local_mods()
	button_open_workshop_page.disabled = true
	init_mod_loader_tags()


func update_local_mods() -> void:
	link_mod.set_input_options_right(ModToolUtils.get_mod_dir_names())
	link_mod.select_right(mod_tool_store.name_mod_dir)


func get_published_mods() -> void:
	Steam.connect("ugc_query_completed", self, "_on_ugc_query_completed")

	query_handle = Steam.createQueryUserUGCRequest(
		Steam.getSteamID(),
		Steam.USER_UGC_LIST_PUBLISHED,
		Steam.WORKSHOP_FILE_TYPE_COMMUNITY,
		Steam.USER_UGC_LIST_SORT_ORDER_LAST_UPDATED_DESC,
		Steam.getAppID(),
		Steam.getAppID(),
		1
	)
	print("Send UGC Request!")
	Steam.setReturnLongDescription(query_handle, true)
	Steam.sendQueryUGCRequest(query_handle)


func download_image(url: String, file_id: int) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_request_completed", [url, http_request, file_id])

	var error = http_request.request(url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func copy_manifest_data() -> void:
	print("copy_manifest_data")
	input_title.set_input_text(mod_tool_store.manifest_data.get_mod_id())
	if mod_tool_store.manifest_data.description_rich.empty():
		input_description.set_input_text(mod_tool_store.manifest_data.description)
	else:
		input_description.set_input_text(mod_tool_store.manifest_data.description_rich)


func set_preview_image_path(path: String) -> void:
	preview_image.set_input_text(path)


# TODO: To automatically select the right local mod based on the workshop item
# we need to check each manifest, currently we only load the manifest of the active mod.
# Maybe something we can add later.
func update_link_mod() -> void:
	if not mod_tool_store.steam_initialized:
		return

	if mod_tool_store.manifest_data.steam_workshop_id == -1:
		link_mod.select_left("new item")
	else:
		# If there is a workshop id, set the left side to the mod with that id
		for i in link_mod.input_options_left.size():
			var workshop_item = link_mod.input_options_left[i]
			if int(workshop_item.split("-")[-1]) == mod_tool_store.manifest_data.steam_workshop_id:
				link_mod.select_left(workshop_item)


# I would like to init steam to get the published mods
# Then shut it down while it's not needed.
# But it keeps crashing if I shut it after the UGC query is freed.
func init_steam() -> void:
	if steam:
		var steam_init_result = Steam.steamInit(true, mod_tool_store.steam_app_id, true)
		ModToolUtils.output_info("steam_init_result: %s" % steam_init_result)

		if steam_init_result.status == 1:
			mod_tool_store.steam_initialized = true
			steam_state.pressed = true
			input_steam_app_id.set_input_text(str(Steam.getAppID()))
			get_published_mods()
			emit_signal("steam_inited")


func init_mod_loader_tags() -> void:
	var mod_loader_options: ModLoaderCurrentOptions = load("res://addons/mod_loader/options/options.tres")
	var mod_loader_options_profile: ModLoaderOptionsProfile
	if mod_loader_options.feature_override_options.has("editor"):
		mod_loader_options_profile = mod_loader_options.feature_override_options.editor
	else:
		mod_loader_options_profile = mod_loader_options.current_options
	tags.input_options = mod_loader_options_profile.steam_workshop_tags
	tags.disable_all()


func update_selected_tags() -> void:
	for tag in tags.input_options:
		if mod_tool_store.steam_mod_data.tags.has(tag):
			tags.set_check_box_state(tag, true)
		else:
			tags.set_check_box_state(tag, false)


func _on_SteamGameID_value_changed(new_value, input_node) -> void:
	mod_tool_store.steam_app_id = new_value # TODO: Validate


func _on_Title_value_changed(new_value, input_node) -> void:
	if mod_tool_store.steam_mod_data:
		print("Updated Title: %s" % new_value)
		mod_tool_store.steam_mod_data.title = new_value # TODO: Validate


func _on_Description_value_changed(new_value, input_node) -> void:
	if mod_tool_store.steam_mod_data:
		print("Updated Description: %s" % new_value)
		mod_tool_store.steam_mod_data.description = new_value


func _on_InitSteam_pressed() -> void:
	init_steam()


func _on_ugc_query_completed(
	_query_handle: int,
	_result: int,
	_results_returned: int,
	_total_matching: int,
	_cached: bool
) -> void:

	if not _query_handle == query_handle:
		return

	if not _result == Steam.RESULT_OK:
		push_error("UGC QUERY FAILED !!!")
		return

	print("!!! UGC QUERY COMPLETED !!!")

	for i in _results_returned:
		var result = Steam.getQueryUGCResult(_query_handle, i)
		var preview_url = Steam.getQueryUGCPreviewURL(_query_handle, i)
		workshop_mods[result.file_id] = {}
		workshop_mods[result.file_id].title = result.title
		workshop_mods[result.file_id].description = result.description
		workshop_mods[result.file_id].preview_url = preview_url
		workshop_mods[result.file_id].tags = result.tags

	var select_workshop_mods_selection := ["new item"]

	for file_id in workshop_mods.keys():
		var mod = workshop_mods[file_id]
		select_workshop_mods_selection.push_back("%s - %s" % [mod.title, file_id])

	link_mod.set_input_options_left(PoolStringArray(select_workshop_mods_selection))
	update_link_mod()
	link_mod.set_input_disabled_left(false)
	tags.enable_all()

	Steam.releaseQueryUGCRequest(_query_handle)


func _on_PreviewImage_value_changed(new_value, input_node) -> void:
	var file: = File.new()

	file.open(new_value, File.READ)
	var data := file.get_buffer(file.get_len())

	var image := Image.new()
	image.load_png_from_buffer(data)

	var image_texture := ImageTexture.new()
	image_texture.create_from_image(image)

	preview_image_preview.texture = image_texture
	mod_tool_store.steam_mod_data.preview = image_texture
	mod_tool_store.steam_mod_data.preview_file_path = new_value


func _on_PreviewImage_button_pressed() -> void:
	emit_signal("steam_preview_image_button_pressed")


func _on_Tags_value_changed(new_value, input_node) -> void:
	mod_tool_store.steam_mod_data.tags = PoolStringArray(new_value)


func _http_request_completed(result, response_code, headers, body, url: String, http_request: HTTPRequest, file_id: int):
	var image = Image.new()
	var error = OK
	if headers.has("Content-Type: image/png"):
		error = image.load_png_from_buffer(body)
	if headers.has("Content-Type: image/jpeg"):
		error = image.load_jpg_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")

	var texture = ImageTexture.new()
	texture.create_from_image(image)

	if mod_tool_store.steam_mod_data.file_id == file_id:
		mod_tool_store.steam_mod_data.preview = texture
		preview_image_preview.texture = texture

	http_request.queue_free()


func _on_LinkMod_button_pressed() -> void:
	mod_tool_store.manifest_data.steam_workshop_id = mod_tool_store.steam_selected_file_id
	emit_signal("linked_mod")


func _on_LinkMod_left_value_changed(new_value, input_node) -> void:
	if new_value.empty():
		return

	preview_image_preview.texture = preview_image_placeholder

	if new_value == "new item":
		mod_tool_store.steam_mod_data = ModToolSteamWorkshopData.new(-1, "", "")
		input_title.set_input_text("")
		input_description.set_input_text("")
		link_mod.set_button_disabled(true)
		copy_manifest_data()
		button_open_workshop_page.disabled = true
		update_selected_tags()
		return

	var file_id = int(new_value.split("-")[-1].strip_edges())
	mod_tool_store.steam_selected_file_id = file_id
	mod_tool_store.steam_mod_data = ModToolSteamWorkshopData.new(
		file_id,
		workshop_mods[file_id].title,
		workshop_mods[file_id].description
	)
	mod_tool_store.steam_mod_data.tags = PoolStringArray(workshop_mods[file_id].tags.split(","))
	if not workshop_mods[file_id].preview_url.empty():
		download_image(workshop_mods[file_id].preview_url, file_id)
	input_title.set_input_text(mod_tool_store.steam_mod_data.title)
	input_description.set_input_text(mod_tool_store.steam_mod_data.description)
	button_open_workshop_page.disabled = false
	update_selected_tags()


	if file_id == mod_tool_store.manifest_data.steam_workshop_id:
		link_mod.set_button_disabled(true)
	else:
		link_mod.set_button_disabled(false)


func _on_LinkMod_right_value_changed(new_value, input_node) -> void:
	preview_image_preview.texture = preview_image_placeholder
	emit_signal("local_mod_selection_changed", new_value)
	# update_link_mod() is called after the manifest is loaded in tools_panel.gd


func _on_ButtonOpenWorkshopPage_pressed() -> void:
	OS.shell_open("https://steamcommunity.com/sharedfiles/filedetails/?id=%s" % mod_tool_store.steam_selected_file_id)
