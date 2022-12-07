extends Control

const SAVE_PATH = 'user://save.json'

var data = {
	'runner_script_name': 'runner.cmd',
	'game_folder': '',
	'game_exe': '',
	'game_mod_folder': 'mods',
	'mod_folder': '',
	'mod_folder_name': '',
	'exluded_file_extensions': ['.translation', '.csv.import']
}

var current_dialog : String

@onready var file_dialog = $MarginContainer/FileDialog
@onready var current_game_exe = $MarginContainer/VBoxContainer/VBoxContainer/current_game_exe
@onready var current_mod_folder = $MarginContainer/VBoxContainer/VBoxContainer/current_mod_folder
@onready var btn_start_game_key = $MarginContainer/VBoxContainer/Btn_StartGameKey
@onready var line_edit = $MarginContainer/VBoxContainer/LineEdit
@onready var line_edit_excluded_file_extensions = $MarginContainer/VBoxContainer/LineEdit_ExcludedFileExtensions


# Called when the node enters the scene tree for the first time.
func _ready():
	data = load_save()
	update_UI()

func _input(event):
	if event.is_action("start_game"):
		start_game()
		
func start_game():
	zip_folder()
	OS.shell_open(str(data.game_folder, '/', data.runner_script_name))

func zip_folder():
	if(data.game_folder != '' && data.mod_folder != ''):
		# Create zip folder - in game mod folder - from source mod folder
		var game_mod_folder_path = data.game_folder.path_join(data.game_mod_folder).path_join(str(data.mod_folder_name,".zip"))
		Utils.zip_folder(data.mod_folder, game_mod_folder_path, data.exluded_file_extensions)
	else:
		print(str('ERROR: missing mod / game folder'))

func update_UI():
	current_game_exe.text = str("Game .exe: ", data.game_exe)
	current_mod_folder.text = str("Mod Folder: ", data.mod_folder)
	line_edit.text = data.runner_script_name
	
	line_edit_excluded_file_extensions.text = ", ".join(data.exluded_file_extensions)
	

func _on_btn_game_folder_pressed():
	file_dialog.show()
	current_dialog = 'game'

func _on_btn_mod_folder_pressed():
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

func _on_file_dialog_dir_selected(dir):
	handle_file_dialog(dir)

func _on_file_dialog_file_selected(path):
	handle_file_dialog(path)

func _on_line_edit_text_changed(new_text):
	data.runner_script_name = new_text

func _on_line_edit_excluded_file_extensions_text_changed(new_text):
	data.exluded_file_extensions = Utils.get_entries(new_text)

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
