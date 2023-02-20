extends Node
class_name ModToolStore


const PATH_SAVE_FILE = "user://mod-tool-plugin-save.json"

var name_mod_dir := ""
var path_mod_dir := ""
var path_export_dir := ""
var path_project_dir := ""
var path_temp_dir := ""
var excluded_file_extensions : PoolStringArray = [".csv.import"]
var path_mod_files : PoolStringArray = []

var label_output : RichTextLabel


func init(store: Dictionary):
	name_mod_dir = store.name_mod_dir
	path_mod_dir = "res://mods-unpacked/" + store.name_mod_dir
	path_export_dir = "res://zips"
	path_project_dir = ModToolUtils.get_local_folder_dir()
	path_temp_dir = "user://temp/" + store.name_mod_dir
	excluded_file_extensions = [".csv.import"]


func save_store():
	var save_data = {
		"name_mod_dir": name_mod_dir,
		"path_mod_dir": path_mod_dir,
		"path_export_dir": path_export_dir,
		"path_project_dir": path_project_dir,
		"path_temp_dir": path_temp_dir,
		"excluded_file_extensions": excluded_file_extensions
	}

	var file = File.new()
	var error = file.open(PATH_SAVE_FILE, File.WRITE)
	if error != OK:
		print(error)
	file.store_string(JSON.print(save_data))
	file.close()


func load_store():
	var file = File.new()
	file.open(PATH_SAVE_FILE, File.READ)
	var content = file.get_as_text()

	init(JSON.parse(content).result)