tool
extends Control

onready var label_output = $"%Output"




func _run_command(command: String, is_ui_visible = false):
	label_output.text = ''

	var output = []
	var global_path = ProjectSettings.globalize_path("res://addons/godot-mod-export/ModDevTool.exe")
	var exit_code = OS.execute(global_path, ['--headless' if !is_ui_visible else '', command], true, output)
	for text in output:
		label_output.text = str(label_output.text, '\n', text)


func _on_btn_run_game_pressed():
	_run_command("--run")


func _on_btn_build_pressed():
	_run_command("--build")


func _on_btn_ui_pressed():
	_run_command("", true)
