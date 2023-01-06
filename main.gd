extends Control

const SAVE_PATH = 'user://save.json'

var data = {
	'runner_script_name': 'runner.cmd',
	'game_folder': '',
	'game_exe': '',
	'game_mod_folder': 'mods',
	'mod_parent_folder': 'mods-unpacked',
	'mod_folder': '',
	'mod_folder_name': '',
	'excluded_file_extensions': ['.translation', '.csv.import']
}

var mod_file_paths = []
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
	data = load_save()
	update_UI()

func _input(event):
	if event.is_action("start_game"):
		hide_error_message()
		start_game()

func start_game():
	if(!check_paths()):
		return
	
	mod_file_paths = Utils.get_flat_view_dict(data.mod_folder)
	remap_imports()
	zip_folder()
	OS.shell_open(str(data.game_folder, '/', data.runner_script_name))

func check_paths():
	# Game Folder selected
	if(data.game_folder == ''):
		show_error_message("Game Folder not defined - click the \"Game .exe\" Button.")
		return false
	# Mod Folder selected
	elif(data.mod_folder == ''):
		show_error_message("Mod Folder not defined - click the \"Mod Folder\" Button.")
		return false
	# Dev Mod Folder
	elif(!Utils.is_dir_there(data.mod_folder)):
		show_error_message("Mod Folder not found")
		return false
	# Game Mod Folder
	elif(!Utils.is_dir_there(data.game_folder.path_join(data.game_mod_folder))):
		show_error_message("Mod Folder in Game Directory not found")
		return false
	# Runner Script
	elif(!Utils.is_file_there(data.game_folder.path_join(data.runner_script_name))):
		show_error_message("Runner Script in Game Directory not found")
		return false
	else:
		return true
	
	
	

# TODO: Tag remapped files - or check in some way if there is a need to run this again.
func remap_imports():	
	# Find all .import files
	for file_path in mod_file_paths:
		if file_path.get_extension() == "import":
			# Open file
			var text = Utils.file_get_as_text(file_path)
			
			# Get the path to the imported file
			var path_imported_file_regex_results = Utils.get_regex_results(text, "res\\:\\/\\/\\.import.+?(?=\\\")")
			var path_imported_file
			if(path_imported_file_regex_results.size() > 0):
				path_imported_file = path_imported_file_regex_results[0]
				path_imported_file = str(data.mod_folder.replace(data.mod_folder_name, ''), path_imported_file.replace('res://', '')) 
			else:
				continue
			
			var path_mod_import_folder = str(data.mod_folder,"/_import")
			
			# Check if the _import folder doesn't exist
			if(!Utils.is_dir_there(path_mod_import_folder)):
				# Creat the _import folder
				DirAccess.make_dir_absolute(path_mod_import_folder)
			
			# Copy the imported file from .import into the mods _import folder
			Utils.file_copy(path_imported_file, path_mod_import_folder)
			
			# Change the "path" to point to the mod _import folder
			text = text.replace(".import", str(data.mod_folder_name, "/_import"))
			# Save the .import file
			Utils.file_save_as_text(text, file_path)

func zip_folder():
	# Create zip folder - in game mod folder - from source mod folder
	var game_mod_folder_path = data.game_folder.path_join(data.game_mod_folder).path_join(str(data.mod_folder_name,".zip"))
	Utils.zip_files(mod_file_paths, data.mod_parent_folder, game_mod_folder_path, data.excluded_file_extensions)


func update_UI():
	current_game_exe.text = str("Game .exe: ", data.game_exe)
	current_mod_folder.text = str("Mod Folder: ", data.mod_folder)
	line_edit.text = data.runner_script_name
	hide_error_message()
	
	line_edit_excluded_file_extensions.text = ", ".join(data.excluded_file_extensions)
	

func _on_btn_game_folder_pressed():
	if(data.game_folder != ''):
		file_dialog.current_dir = data.game_folder
	file_dialog.show()
	current_dialog = 'game'

func _on_btn_mod_folder_pressed():
	if(data.mod_folder != ''):
		file_dialog.current_dir = data.mod_folder
	file_dialog.show()
	current_dialog = 'mod'

func handle_file_dialog(dir):
	if(current_dialog == 'game'):
		data.game_exe = dir
		data.game_folder = dir.get_base_dir()
		current_game_exe.text = str("Game .exe: ", dir)
	elif(current_dialog == 'mod'):
		data.mod_folder = dir
		var mod_folder_split = dir.split("/")
		data.mod_folder_name = mod_folder_split[mod_folder_split.size() - 1]
		current_mod_folder.text = str("Mod Folder: ", dir)

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
	data.mod_parent_folder = new_text
	print(data.mod_parent_folder)

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
