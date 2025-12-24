tool
extends WindowDialog


signal start_upload_pressed

onready var mod_tool_store = get_node_or_null("/root/ModToolStore")

onready var input_export_path: HBoxContainer = $"%InputExportPath"
onready var input_workshop_id: HBoxContainer = $"%InputWorkshopID"
onready var button_open_workshop_page: Button = $"%ButtonOpenWorkshopPage"
onready var button_abort: Button = $"%ButtonAbort"
onready var button_start_upload: Button = $"%ButtonStartUpload"
onready var before_upload: VBoxContainer = $"%BeforeUpload"
onready var during_upload: MarginContainer = $"%DuringUpload"
onready var after_upload_success: VBoxContainer = $"%AfterUploadSuccess"
onready var after_upload_error: VBoxContainer = $"%AfterUploadError"
onready var timer_upload_progress: Timer = $"%TimerUploadProgress"
onready var label_upload_current_state: Label = $"%LabelUploadCurrentState"
onready var upload_progress_bar: ProgressBar = $"%UploadProgressBar"
onready var content: VBoxContainer = $"%Content"
onready var rich_label_after_upload_error_message: RichTextLabel = $"%RichLabelAfterUploadErrorMessage"

var update_status_messages := [
	"The item update handle was invalid, job might be finished, listen to item_updated.",
	"The item update is processing configuration data.",
	"The item update is reading and processing content files.",
	"The item update is uploading content changes to Steam.",
	"The item update is uploading new preview file image.",
	"The item update is committing all changes."
]

var upload_results := {
	2: "Operation completed successfully.",
	3: "Generic failure.",
	8: "Either the provided app ID is invalid / doesn't match the consumer app ID of the item, ISteamUGC for the provided app ID on the Steam Workshop Configuration App Admin page is not enabled or the preview file is smaller than 16 bytes.",
	9: "Either Failed to get the workshop info for the item, failed to read the preview file or provided content folder is not valid.",
	15: "The user doesn't own a license for the provided app ID.",
	25: "The preview image is too large, it must be less than 1 Megabyte; or there is not enough space available on the user's Steam Cloud.",
	33: "Failed to aquire UGC Lock.",
}


func init() -> void:
	change_visibility(before_upload) # Chust to make sure
	input_export_path.set_input_text(mod_tool_store.path_global_final_zip)
	input_workshop_id.set_input_text(str(mod_tool_store.steam_selected_file_id))
	rich_label_after_upload_error_message.clear()


func change_visibility(node: Node) -> void:
	for child in content.get_children():
		child.hide()

	node.show()


func upload_started(update_handle: int) -> void:
	change_visibility(during_upload)
	timer_upload_progress.start()
	timer_upload_progress.connect("timeout", self, "_on_timer_upload_progress_timeout", [update_handle])


func upload_completed() -> void:
	button_start_upload.disabled = false
	timer_upload_progress.stop()
	timer_upload_progress.disconnect("timeout", self, "_on_timer_upload_progress_timeout")
	change_visibility(after_upload_success)


func upload_failed(result: int, need_to_accept_tos: bool) -> void:
	button_start_upload.disabled = false
	timer_upload_progress.stop()
	timer_upload_progress.disconnect("timeout", self, "_on_timer_upload_progress_timeout")
	change_visibility(after_upload_error)
	if need_to_accept_tos:
		rich_label_after_upload_error_message.add_text("You have to accept the Steam Workshop TOS before you can continue.")
		OS.shell_open("https://steamcommunity.com/workshop/workshoplegalagreement/")
	else:
		rich_label_after_upload_error_message.add_text(upload_results[result])


func _on_timer_upload_progress_timeout(update_handle: int) -> void:
	var progress := Steam.getItemUpdateProgress(update_handle)
	label_upload_current_state.text = update_status_messages[progress.status]
	if progress.total > 0:
		upload_progress_bar.value = stepify(progress.processed / progress.total, 0.01)


func _on_ButtonOpenWorkshopPage_pressed() -> void:
	OS.shell_open("https://steamcommunity.com/sharedfiles/filedetails/?id=%s" % mod_tool_store.steam_selected_file_id)


func _on_ButtonAbort_pressed() -> void:
	hide()


func _on_ButtonStartUpload_pressed() -> void:
	emit_signal("start_upload_pressed")
	button_start_upload.disabled = true


func _on_ButtonUploadSuccess_pressed() -> void:
	hide()


func _on_ButtonAfterUploadError_pressed() -> void:
	hide()
