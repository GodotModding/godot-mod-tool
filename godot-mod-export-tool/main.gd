extends Control

const SAVE_PATH = 'user://save.json'

var cmd_args = {
	'--run': build,
	'--build': only_build,
	'--?': print_help,
}

var cmd_args_description = {
	'--run': 'Run the game with current settings',
	'--build': 'Export zip with current settings, but don\'t run the game',
	'--?': 'Show possible commands',
}

var cmd_args_passed
var data = {
	'runner_script_name': 'runner.cmd',
	'game_folder_path': '',
	'game_exe_path': '',
	'game_mod_folder_name': 'mods',
	'mod_parent_folder_name': 'mods-unpacked',
	'project_folder_path': '',
	'mod_folder_path': '',
	'mod_folder_name': '',
	'excluded_file_extensions': ['.csv.import']
}

# array of file_data's
var mod_file_paths: Array[FileData] = []

var current_dialog : String

@onready var file_dialog = $MarginContainer/FileDialog
@onready var current_game_exe = $MarginContainer/VBoxContainer/VBoxContainer/current_game_exe
@onready var current_mod_folder = $MarginContainer/VBoxContainer/VBoxContainer/current_mod_folder
@onready var btn_start_game_key = $MarginContainer/VBoxContainer/Btn_StartGameKey
@onready var line_edit = $MarginContainer/VBoxContainer/LineEdit
@onready var line_edit_excluded_file_extensions = $MarginContainer/VBoxContainer/LineEdit_ExcludedFileExtensions
@onready var error_message = $MarginContainer/VBoxContainer/Error_Message


# Called when the node enters the scene tree for the first time.
func _ready():
	# Load save file stored at SAVE_PATH
	data = load_save()
	
	# Get all cmd line arguments
	# --run -> Run the game with current settings
	# --export -> Export zip with current settings but don't run the game
	# --? --> Show possible commands
	cmd_args_passed = get_cmd_args()

	handle_cmd_args(cmd_args_passed)
	
	update_UI()

func _input(event):
	if event.is_action("start_game"):
		hide_error_message()
		build()

func get_cmd_args():
	var arguments = []
	for argument in OS.get_cmdline_args():
		if(argument.begins_with('--')):
			arguments.append(argument)
	
	return arguments

func handle_cmd_args(cmd_args_passed):
	# If no argument continue with UI Mode
	if(cmd_args_passed.size() == 0):
		return
	
	# Check if only one command
	if(cmd_args_passed.size() > 1):
		print("ERROR: Please provide only one argument")
		return
	
	# Grab the the one cmd arg
	var cmd_arg = cmd_args_passed[0]
	
	# Call the corresponding function of the command is known
	if(cmd_args.has(cmd_arg)):
		cmd_args[cmd_arg].call()
	else:
		print(str("ERROR: unknown command ", cmd_arg, " , try --? for help."))
	
	get_tree().quit()

func print_help():
	print(JSON.stringify(cmd_args_description, '   '))

func only_build():
	build(false)
	print(str('SUCCESS: Build completed export path -> ', str(data.game_folder_path, '/', data.game_mod_folder_name, '/', data.mod_folder_name, '.zip')))

func build(run_game = true):
	if(!check_paths()):
		return
	
	# Get all mod file src paths
	var mod_file_src_paths = Utils.get_flat_view_dict(data.mod_folder_path)	
	
	for mod_file_src_path in mod_file_src_paths:
		
		# handle excluded file extension
		if(Utils.is_file_extension(mod_file_src_path, data.excluded_file_extensions)):
			# skip if file extension is excluded
			continue
		
		# add mod files src and dst paths to mod_file_paths
		handle_mod_files(mod_file_src_path)

		# add imported files src and dst paths to mod_file_paths
		if mod_file_src_path.get_extension() == "import" && Utils.is_file_there(mod_file_src_path):
			handle_import_files(mod_file_src_path)

	# Create the zip file
	var zip_file_dst_path = str(data.game_folder_path, '/', data.game_mod_folder_name, '/', data.mod_folder_name, '.zip')
	zip_folder(zip_file_dst_path, mod_file_paths)

	# Start the game with the specified runner script ( can also just be the game .exe )
	if(run_game):
		OS.shell_open(str(data.game_folder_path, '/', data.runner_script_name))

func check_paths():
	# Game Folder selected
	if(data.game_folder_path == ''):
		show_error_message("Game Folder not defined - click the \"Game .exe\" Button.")
		return false
	# Mod Folder selected
	elif(data.mod_folder_path == ''):
		show_error_message("Mod Folder not defined - click the \"Mod Folder\" Button.")
		return false
	# Dev Mod Folder
	elif(!Utils.is_dir_there(data.mod_folder_path)):
		show_error_message("Mod Folder not found")
		return false
	# Game Mod Folder
	elif(!Utils.is_dir_there(data.game_folder_path.path_join(data.game_mod_folder_name))):
		show_error_message("Mod Folder in Game Directory not found")
		return false
	# Runner Script
	elif(!Utils.is_file_there(data.game_folder_path.path_join(data.runner_script_name))):
		show_error_message("Runner Script in Game Directory not found")
		return false
	else:
		return true

func handle_mod_files(mod_file_src_path):
	var file_data = FileData.new()
	
	# Get mod file destination path - the dst path is local to the zip file
	# Mod file src path example:
	# C:\Godot_Project_Folder\mod_parent_folder\ModAuthor-ModName\ModMain.gd
	# Mod file dst path example:
	# \mod_parent_folder\ModAuthor-ModName\ModMain.gd
	
	# ['C:\Godot_Project_Folder\mod_parent_folder\', '\ModMain.gd']
	var mod_file_src_path_split = mod_file_src_path.split(data.mod_folder_name)
	# \ModMain.gd
	var mod_folder_local_path = mod_file_src_path_split[1]
	# \mod_parent_folder\ModAuthor-ModName\ModMain.gd
	var mod_file_dst_path = str(data.mod_parent_folder_name, '/', data.mod_folder_name, mod_folder_local_path)

	file_data.add_data(mod_file_src_path, mod_file_dst_path)

	mod_file_paths.append(file_data)


func handle_import_files(import_file_src_path):
	var file_data = FileData.new()
	
	# Open file
	var text = Utils.file_get_as_text(import_file_src_path)
	
	# Get the path to the imported file
	var path_imported_file_regex_results = Utils.get_regex_results(text, "res\\:\\/\\/\\.import.+?(?=\\\")")
	if(path_imported_file_regex_results.size() == 0):
		print("ERROR: No path found inside .import file!")
		return 
	
	# Grab the first path to the imported file
	# Imported file example path:
	# res://.import/ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex
	var imported_file_src_path_local = path_imported_file_regex_results[0]
	# remove the res://
	imported_file_src_path_local = imported_file_src_path_local.replace('res://', '')
	# Globalize the path:
	# C:\Path\to\GodotProject\.import\ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex
	var imported_file_src_path = str(data.project_folder_path, imported_file_src_path_local)
	
	# Get the imported file dst file - the dst path is local to the zip file
	# Imported file dst path example:
	# \.import\ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex
	
	# ['C:\Path\to\GodotProject\', '\ImportedPNG.png-eddc81c8e2d2fc90950be5862656c2b5.stex']
	var imported_file_src_path_split = imported_file_src_path.split('.import')
	var imported_file_local_path = imported_file_src_path_split[1]
	
	var imported_file_dst_path = str('.import', imported_file_local_path)
	
	file_data.add_data(imported_file_src_path, imported_file_dst_path)
	
	mod_file_paths.append(file_data)

# Creates the zip folder at zip_file_dst_path and adds all mod_files
# zip_file_dst_path example:
# C:\Path\to\Game\mods\ModAuthor-ModName.zip
func zip_folder(zip_file_dst_path:String, mod_file_paths:Array[FileData]):
	# Create zip writer
	var writer = Utils.create_writer(zip_file_dst_path)
	# Add each mod_file to the zip
	for mod_file_path in mod_file_paths:
		Utils.zip(writer, mod_file_path.src, mod_file_path.dst)
	
	# Close zip writer
	Utils.close_writer(writer)

func update_UI():
	current_game_exe.text = str("Game .exe: ", data.game_exe_path)
	current_mod_folder.text = str("Mod Folder: ", data.mod_folder_path)
	line_edit.text = data.runner_script_name
	hide_error_message()
	
	line_edit_excluded_file_extensions.text = ", ".join(data.excluded_file_extensions)
	

func _on_btn_game_folder_pressed():
	if(data.game_folder_path != ''):
		file_dialog.current_dir = data.game_folder_path
	file_dialog.show()
	current_dialog = 'game'

func _on_btn_mod_folder_pressed():
	if(data.mod_folder_path != ''):
		file_dialog.current_dir = data.mod_folder_path
	file_dialog.show()
	current_dialog = 'mod'

func handle_file_dialog(dir):
	if(current_dialog == 'game'):
		data.game_exe_path = dir
		data.game_folder_path = dir.get_base_dir()
		current_game_exe.text = str("Game .exe: ", dir)
	elif(current_dialog == 'mod'):
		data.mod_folder_path = dir
		var mod_folder_split = dir.split("/")
		data.mod_folder_name = mod_folder_split[mod_folder_split.size() - 1]
		current_mod_folder.text = str("Mod Folder: ", dir)
		# TODO: Can be an issue if there is no mod parent folder,
		# in that case the parent folder is probably the project folder.
		# And if the Mod folder is inside a subfolder this also doesn't work.
		# TLDR: This will only work with this very specific file structure
		# godot_project_folder/mod_parent_folder/mod_folder/
		# Just adding another button to select The Godot Project folder is probably a better idea.
		data.project_folder_path = dir.get_slice(data.mod_parent_folder_name, 0)

func show_error_message(message: String):
	print(str("ERROR: ", message))
	error_message.text = str("ERROR: ", message)

func hide_error_message():
	error_message.text = ''

func _on_file_dialog_dir_selected(dir):
	handle_file_dialog(dir)

func _on_file_dialog_file_selected(path):
	handle_file_dialog(path)

func _on_line_edit_text_changed(new_text):
	data.runner_script_name = new_text

func _on_line_edit_excluded_file_extensions_text_changed(new_text):
	data.excluded_file_extensions = Utils.get_entries(new_text)

func _on_line_edit_parent_folder_name_text_changed(new_text):
	data.mod_parent_folder_name = new_text

func _notification(what):
	if(what == NOTIFICATION_WM_CLOSE_REQUEST):
		# save data
		save()
		# exit
		get_tree().quit()

func save():
	Utils.file_save(data, SAVE_PATH)

func load_save():
	if(FileAccess.file_exists(SAVE_PATH)):
		return Utils.file_load(SAVE_PATH)
	else:
		return data
