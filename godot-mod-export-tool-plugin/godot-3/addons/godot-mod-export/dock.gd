tool
extends Control

onready var label_output = $"%Output"


var base_theme: Theme 	# passed from the EditorPlugin
onready var tab_parent_bottom_panel: PanelContainer


func _ready() -> void:
	tab_parent_bottom_panel = get_parent().get_parent() as PanelContainer
	if base_theme:
		$TabContainer.add_stylebox_override("panel", base_theme.get_stylebox("DebuggerPanel", "EditorStyles"))


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


# replicates the behaviour for the debugger tab styles
# for the full setup of this, the TabContainer needs to be the child of a
# full rect Control and have a margin_left of -10 and a margin_right of 10
# this is to offset the 10px content margins that are still present in the
# BottomPanelDebuggerOverride stylebox for some reason. It's how Godot does it.
func _on_ModToolsDock_visibility_changed() -> void:
	if not visible or not base_theme or not tab_parent_bottom_panel:
		return

	# the panel style is overridden by godot after this method is called
	# make sure our override-override is applied after that
	yield(get_tree(), "idle_frame")

	var panel_box: StyleBoxFlat = base_theme.get_stylebox("BottomPanelDebuggerOverride", "EditorStyles")
	tab_parent_bottom_panel.add_stylebox_override("panel", panel_box)


