tool
extends Node


# Global store for all Data the ModTool requires.

signal store_loaded

const PATH_SAVE_FILE := "user://mod-tool-plugin-save.json"
const PATH_TEMPLATES_DIR := "res://addons/mod_tool/templates/"

var editor_plugin: EditorPlugin
var base_theme: Theme setget set_base_theme
var editor_file_system: EditorFileSystem
var error_color := ""

var name_mod_dir := "" setget set_name_mod_dir
var path_mod_dir := ""
var path_current_template_dir := "res://addons/mod_tool/templates/default/"
var path_export_dir := ""
var path_temp_dir := ""
var path_manifest := ""
var path_global_export_dir := ""
var path_global_project_dir := ""
var path_global_temp_dir := ""
var path_addon_dir := "res://addons/mod_tool/"
var path_global_addon_dir := ""
var path_global_seven_zip := ""
var path_global_final_zip := ""
var excluded_file_extensions: PoolStringArray = [".csv.import"]
var path_mod_files := []

# ModManifest instance
var manifest_data : ModManifest


func _ready() -> void:
	load_store()


func _exit_tree() -> void:
	if not name_mod_dir == "":
		save_store()


func set_base_theme(new_base_theme: Theme) -> void:
	base_theme = new_base_theme
	error_color = "#" + base_theme.get_color("error_color", "Editor").to_html()


func set_name_mod_dir(new_name_mod_dir: String) -> void:
	update_paths(new_name_mod_dir)


func init(store: Dictionary) -> void:
	path_global_project_dir = ProjectSettings.globalize_path(_ModLoaderPath.get_local_folder_dir())
	path_global_addon_dir = path_global_project_dir + "addons/mod_tool/"
	if OS.has_feature("Windows"):
		path_global_seven_zip = path_global_addon_dir + "vendor/7zip/windows/7z.exe"
	elif OS.has_feature("OSX"):
		path_global_seven_zip = path_global_addon_dir + "vendor/7zip/mac/7zz"
	elif OS.has_feature("X11"):
		path_global_seven_zip = path_global_addon_dir + "vendor/7zip/linux/7zz"
	else:
		ModToolUtils.output_error("OS currently not supported to export zips via mod tool. Please open an issue on GitHub")

	if not File.new().file_exists(path_global_seven_zip):
		ModToolUtils.output_error("7zip installation not found at path %s. Please install if at that location." % path_global_seven_zip)
		ModToolUtils.output_error("Download: https://7-zip.org/download.html")

	name_mod_dir = store.name_mod_dir
	path_mod_dir = "res://mods-unpacked/" + store.name_mod_dir
	path_current_template_dir = store.path_current_template_dir
	path_export_dir = store.path_export_dir
	path_global_export_dir = ProjectSettings.globalize_path(path_export_dir)
	path_temp_dir = "user://temp/" + store.name_mod_dir
	path_manifest = path_mod_dir + "/manifest.json"
	path_global_temp_dir = ProjectSettings.globalize_path(path_temp_dir)

	path_global_final_zip = path_global_export_dir + store.name_mod_dir + ".zip"
	excluded_file_extensions = [".csv.import"]


func update_paths(new_name_mod_dir: String) -> void:
	name_mod_dir = new_name_mod_dir
	path_mod_dir = "res://mods-unpacked/" + new_name_mod_dir
	path_temp_dir = "user://temp/" + new_name_mod_dir
	path_global_temp_dir = ProjectSettings.globalize_path(path_temp_dir)
	path_manifest = path_mod_dir + "/manifest.json"


func save_store() -> void:
	var save_data := {
		"name_mod_dir": name_mod_dir,
		"path_mod_dir": path_mod_dir,
		"path_current_template_dir": path_current_template_dir,
		"path_export_dir": path_export_dir,
		"path_global_project_dir": path_global_project_dir,
		"path_temp_dir": path_temp_dir,
		"excluded_file_extensions": excluded_file_extensions
	}

	var file := File.new()
	var error := file.open(PATH_SAVE_FILE, File.WRITE)
	if error != OK:
		ModToolUtils.output_error(str(error))
	file.store_string(JSON.print(save_data))
	file.close()


func load_store() -> void:
	var dir := Directory.new()
	if not dir.file_exists(PATH_SAVE_FILE):
		return

	var file := File.new()
	file.open(PATH_SAVE_FILE, File.READ)
	var content := file.get_as_text()

	init(JSON.parse(content).result)

	emit_signal("store_loaded")
