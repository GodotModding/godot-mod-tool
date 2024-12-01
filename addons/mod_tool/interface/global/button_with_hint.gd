tool
class_name ModToolInterfaceButtonWithHint
extends Button


export(String, MULTILINE) var hint_text setget set_hint_text


func set_hint_text(new_text: String) -> void:
	hint_text = new_text
	hint_tooltip = new_text
