extends Node


const AUTHORNAME_MODNAME_DIR := "AuthorName-ModName"
const AUTHORNAME_MODNAME_LOG_NAME := "AuthorName-ModName:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""


func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().plus_file(AUTHORNAME_MODNAME_DIR)
	# Add extensions
	install_script_extensions()
	# Add translations
	add_translations()


func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.plus_file("extensions")


func add_translations() -> void:
	translations_dir_path = mod_dir_path.plus_file("translations")


func _ready() -> void:
	pass


