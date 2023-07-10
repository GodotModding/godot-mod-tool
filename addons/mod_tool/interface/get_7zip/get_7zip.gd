tool
extends Control


signal installed

const BASE_DOWNLOAD_LINK = "https://7-zip.org/a/"
const WIN_DOWNLOAD_LINK = "7z2301-x64.exe"
const MAC_DOWNLOAD_LINK = "7z2301-mac.tar.xz"
const LINUX_DOWNLOAD_LINK = "7z2301-linux-x64.tar.xz"

var current_download_link: String
var current_download_suffix: String

onready var mod_tool_store = get_node_or_null("/root/ModToolStore")
onready var http_request: HTTPRequest = $"%HTTPRequest"
onready var download: Button = $"%Download"


func install(download_file_path: String) -> void:
	if mod_tool_store.current_os == "windows":
		# Run the setup
		var _exit_code := OS.execute("cmd.exe", ["/c", "%s /S /D=\"%s\"" % [download_file_path, mod_tool_store.path_global_seven_zip_base_dir]], true)
	else:
		# Unpack install files
		var _exit_code := OS.execute('bash',["-c", "tar -xf %s -C %s" % [download_file_path, mod_tool_store.path_global_seven_zip_base_dir]], true)

	# Delete the downloaded installer
	Directory.new().remove(download_file_path)

	# If the setup was successfull log success and emit the installed signal
	if _ModLoaderFile.file_exists(mod_tool_store.path_global_seven_zip):
		ModToolUtils.output_info("Successfully installed 7zip at \"%s\"" % mod_tool_store.path_global_seven_zip_base_dir)
		emit_signal("installed")
	else:
		ModToolUtils.output_error("Something went wrong during the installation of 7zip.")


func _on_Download_pressed() -> void:
	match mod_tool_store.current_os:
		"windows":
			current_download_link = BASE_DOWNLOAD_LINK + WIN_DOWNLOAD_LINK
			current_download_suffix = WIN_DOWNLOAD_LINK
		"osx":
			current_download_link = BASE_DOWNLOAD_LINK + MAC_DOWNLOAD_LINK
			current_download_suffix = MAC_DOWNLOAD_LINK
		"x11":
			current_download_link = BASE_DOWNLOAD_LINK + LINUX_DOWNLOAD_LINK
			current_download_suffix = LINUX_DOWNLOAD_LINK

	var error = http_request.request(current_download_link)

	if error != OK:
		ModToolUtils.output_error("An error occurred in the HTTP request. Error code: \"%s\"." % error)


func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
	if not response_code == 200:
		ModToolUtils.output_error("An error occurred in the HTTP request - response code: %s." % response_code)
		return

	var path_global_seven_zip_download_file: String = mod_tool_store.path_global_seven_zip_base_dir + current_download_suffix

	if not _ModLoaderFile.dir_exists(mod_tool_store.path_global_seven_zip_base_dir):
		ModToolUtils.make_dir_recursive(mod_tool_store.path_global_seven_zip_base_dir)

	var file := File.new()
	var error := file.open(path_global_seven_zip_download_file, File.WRITE)
	if error != OK:
		ModToolUtils.output_error("Failed to write downloaded file. Error code: \"%s\"." % error)
	file.store_buffer(body)
	file.close()

	install(path_global_seven_zip_download_file)

	var file_manager_path: String = mod_tool_store.path_global_seven_zip_base_dir
	if OS.has_feature("OSX"):
		file_manager_path = "file://" + file_manager_path
	OS.shell_open(file_manager_path)
