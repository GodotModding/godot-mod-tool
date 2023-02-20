extends Node
class_name ModToolStore


var name_mod_dir := 'damiBenro-Junker'
var path_mod_dir := 'res://mods-unpacked/damiBenro-Junker/'
var path_export_dir := "res://zips"
var path_project_dir := ModToolUtils.get_local_folder_dir()
var path_temp_dir := 'user://temp/damiBenro-Junker/'
var path_mod_files : PoolStringArray = []
var excluded_file_extensions : PoolStringArray = [".csv.import"]

var label_output : RichTextLabel


func _init():
	pass
	# Check for saved data

	# Load saved data
