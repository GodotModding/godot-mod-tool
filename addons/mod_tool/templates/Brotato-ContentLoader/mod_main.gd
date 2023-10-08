extends Node

# !!! Make sure to add Content Loader and all its dependencies to your "mods-unpacked" directory !!!
# Required:
# Darkly77-ContentLoader: 		https://github.com/BrotatoMods/Brotato-ContentLoader
# Darkly77-Brotils: 			https://github.com/BrotatoMods/Brotato-Brotils
#
# Optional:
# Darkly77-ExpandedChallenges: 	https://github.com/BrotatoMods/Darkly77-ExpandedChallenges
# Darkly77-BFX: 				https://github.com/BrotatoMods/Brotato-BFX

# For detailed documentation visit -> https://github.com/BrotatoMods/Brotato-ContentLoader#toc
#
# Got stuck? Don't hesitate to ask for help in #modding-dev -> https://discord.gg/j39jE6k

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
	# Get the ContentLoader Class
	# https://github.com/BrotatoMods/Brotato-ContentLoader#adding-content
	var ContentLoader := get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	var content_dir = mod_dir_path.plus_file("content_data")

	# Add content. These .tres files are ContentData resources
	# https://github.com/BrotatoMods/Brotato-ContentLoader#contentdata-resources
	ContentLoader.load_data(content_dir.plus_file("my_custom_content.tres"), AUTHORNAME_MODNAME_LOG_NAME)


