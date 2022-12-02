extends Control

const SAVE_PATH = 'user://save.json'

var data = {
	'game_folder': '',
	'game_exe': '',
	'game_start_params': '',
	'mod_folder': '',
	'mod_folder_name': '',
}

var current_dialog : String

@onready var file_dialog = $MarginContainer/FileDialog
@onready var current_game_exe = $MarginContainer/VBoxContainer/VBoxContainer/current_game_exe
@onready var current_mod_folder = $MarginContainer/VBoxContainer/VBoxContainer/current_mod_folder
@onready var btn_start_game_key = $MarginContainer/VBoxContainer/Btn_StartGameKey
@onready var line_edit = $MarginContainer/VBoxContainer/LineEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	data = load_save()
	update_UI()

func _input(event):
	if event.is_action("start_game"):
		start_game()
		
func start_game():
	copy_folder()
#	OS.shell_open("C:\\Program Files (x86)\\Steam\\steamapps\\common\\Brotato\\ModLoader.cmd")
#	OS.execute(data.game_exe, data.game_start_params.split(' '))

	# TODO: Lets try to run it in a seperate thread and display the ouput in a windows
	# If this is to muche hassle - maybe just run a seperate script with OS.shell_open()
	var output = []
	OS.execute("CMD.exe", ["/C", "cd C:/Program Files (x86)/Steam/steamapps/common/Brotato/ && Brotato.exe --enable-mods --main-pack ModLoader.pck --script run.gd && pause"], output, true, true)
	print(output)

func copy_folder():
	if(data.game_folder != '' && data.mod_folder != ''):
		Utils.copy_directory_recursively(data.mod_folder, str(data.game_folder,'/',data.mod_folder_name))
	else:
		print(str('ERROR: missing mod / game folder'))

func update_UI():
	current_game_exe.text = str("Game Folder: ", data.game_exe)
	current_mod_folder.text = str("Mod Folder: ", data.mod_folder)
	line_edit.text = data.game_start_params

func write_zip_file():
	var writer := ZIPPacker.new()
	var err := writer.open("user://archive.zip")
	if err != OK:
		return err
	writer.start_file("hello.txt")
	writer.write_file("Hello World".to_utf8_buffer())
	writer.close_file()

	writer.close()
	return OK

func _on_btn_game_folder_pressed():
	file_dialog.show()
	current_dialog = 'game'


func _on_btn_mod_folder_pressed():
	file_dialog.show()
	current_dialog = 'mod'

func handle_file_dialog(dir):
	print(dir)
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
	data.game_start_params = new_text

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
		


