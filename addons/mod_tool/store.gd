extends Node
class_name ModToolStore


# Global store for all Data the ModTool requires.

const PATH_SAVE_FILE := "user://mod-tool-plugin-save.json"

var base_theme: Theme setget set_base_theme
var error_color := ''

var name_mod_dir := "" setget set_name_mod_dir
var path_mod_dir := ""
var path_export_dir := ""
var path_temp_dir := ""
var path_global_export_dir := ""
var path_global_project_dir := ""
var path_global_temp_dir := ""
var path_global_addon_dir := ""
var path_global_seven_zip := ""
var path_global_final_zip := ""
var excluded_file_extensions: PoolStringArray = [".csv.import"]
var path_mod_files: Array = []

var label_output: RichTextLabel


func set_base_theme(new_base_theme: Theme) -> void:
	base_theme = new_base_theme
	error_color = "#" + base_theme.get_color("error_color", "Editor").to_html()


func set_name_mod_dir(new_name_mod_dir: String) -> void:
	update_paths(new_name_mod_dir)


func init(store: Dictionary) -> void:
	name_mod_dir = store.name_mod_dir
	path_mod_dir = "res://mods-unpacked/" + store.name_mod_dir
	path_export_dir = "res://zips/"
	path_global_export_dir = ProjectSettings.globalize_path(path_export_dir)
	path_global_project_dir = ProjectSettings.globalize_path(ModLoaderUtils.get_local_folder_dir())
	path_temp_dir = "user://temp/" + store.name_mod_dir
	path_global_temp_dir = ProjectSettings.globalize_path(path_temp_dir)
	path_global_addon_dir = path_global_project_dir + "addons/mod_tool/"
	path_global_seven_zip = path_global_addon_dir + "vendor/7zip/win/zip.exe"
	path_global_final_zip = path_global_export_dir + store.name_mod_dir + ".zip"
	excluded_file_extensions = [".csv.import"]


func update_paths(new_name_mod_dir: String) -> void:
	name_mod_dir = new_name_mod_dir
	path_mod_dir = "res://mods-unpacked/" + new_name_mod_dir
	path_temp_dir = "user://temp/" + new_name_mod_dir


func save_store() -> void:
	var save_data := {
		"name_mod_dir": name_mod_dir,
		"path_mod_dir": path_mod_dir,
		"path_export_dir": path_export_dir,
		"path_global_project_dir": path_global_project_dir,
		"path_temp_dir": path_temp_dir,
		"excluded_file_extensions": excluded_file_extensions
	}

	var file := File.new()
	var error := file.open(PATH_SAVE_FILE, File.WRITE)
	if error != OK:
		print(error)
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
