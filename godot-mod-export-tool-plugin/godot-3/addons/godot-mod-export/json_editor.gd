tool
extends TextEdit

var base_theme: Theme setget set_base_theme
var editor_settings: EditorSettings setget set_editor_settings
var last_text: String

var highlight_settings: PoolStringArray = [
	"string_color", "background_color", "line_number_color",
	"text_selected_color", "selection_color", "brace_mismatch_color",
	"current_line_color", "word_highlighted_color", "number_color",
	"code_folding_color", "symbol_color"
]

var autobrace_pairs := {
	"(": ")",
	"{": "}",
	"[": "]",
	'"': '"',
	":": ",",
}


func _ready() -> void:
	last_text = text
	$"%ShouldValidate".connect("pressed", self, "validate")
	validate()


func set_base_theme(p_base_theme: Theme) -> void:
	base_theme = p_base_theme
	add_font_override("font", base_theme.get_font("source", "EditorFonts"))


func set_editor_settings(p_editor_settings: EditorSettings) -> void:
	editor_settings = p_editor_settings

	syntax_highlighting = get_setting_bool("text_editor/highlighting/syntax_highlighting")
	highlight_all_occurrences = get_setting_bool("text_editor/highlighting/highlight_all_occurrences")
	highlight_current_line = get_setting_bool("text_editor/highlighting/highlight_current_line")

	draw_tabs = get_setting_bool("text_editor/indent/draw_tabs")
	draw_spaces = get_setting_bool("text_editor/indent/draw_spaces")

	$ValidationDelay.wait_time = editor_settings.get_setting("text_editor/completion/idle_parse_delay")

	# highlights
	add_color_region('"', '"', get_highlight_color("string_color"))
	for highlight in highlight_settings:
		add_color_override(highlight, get_highlight_color(highlight))


func get_highlight_color(name: String) -> Color:
	var color = editor_settings.get_setting("text_editor/highlighting/" + name)
	return color if color is Color else null


func get_setting_bool(setting: String) -> bool:
	var is_set = editor_settings.get_setting(setting)
	return is_set if is_set is bool else false


func validate() -> void:
	if not $"%ShouldValidate".pressed:
		$"%ErrorLabel".text = "Validation off"
		return

	var parsed := JSON.parse(text)
	if not parsed.error == OK:
		$"%ErrorLabel".text = "Line %s: %s" % [parsed.error_line +1, parsed.error_string]
		return
	$"%ErrorLabel".text = "JSON is valid"


func _on_text_changed() -> void:
	$ValidationDelay.stop()
	$ValidationDelay.start()

	if cursor_get_column() < 1:
		return
	if get_setting_bool("text_editor/completion/auto_brace_complete"):
		autobrace()

	last_text = text


func autobrace() -> void:
	var line := get_line(cursor_get_line())
	var char_before_cursor := line[cursor_get_column()-1]
	var char_after_cursor: String
	if cursor_get_column() < line.length():
		char_after_cursor = line[cursor_get_column()]

	# when deleting, also delete the autobraced character
	if Input.is_key_pressed(KEY_BACKSPACE) and not char_after_cursor == null:
		if char_after_cursor in autobrace_pairs.values():
			var deleted_character := first_different_character(text, last_text)
			if autobrace_pairs.has(deleted_character) and autobrace_pairs[deleted_character] == char_after_cursor:
				delete_character_after_cursor()

	# if we encounter a closing brace, "skip" over it
	# since the character is written already, just delete the next one
	elif is_closing_brace(char_before_cursor, char_after_cursor):
		delete_character_after_cursor()

	# if a character is in the autoclose dict, close it
	elif char_before_cursor in autobrace_pairs.keys():
		var closing_char: String = autobrace_pairs[char_before_cursor]
		var prev_column := cursor_get_column()
		insert_text_at_cursor(closing_char)
		cursor_set_column(prev_column)


func is_closing_brace(new_character: String, char_after_cursor: String) -> bool:
	if not new_character == char_after_cursor:
		return false

	# case where opening and closing brace are the same -> ""
	if char_after_cursor in autobrace_pairs.keys():
		return true

	# case where opening and closing brace are the different -> ()
	if new_character in autobrace_pairs.values():
		return true

	return false


func delete_character_after_cursor() -> void:
	var line_text := get_line(cursor_get_line())
	var cursor_col := cursor_get_column() +1
	var text_length := len(line_text)
	if cursor_col < 1 or cursor_col > text_length:
		return
	var left_text := line_text.substr(0, cursor_col - 1)
	var right_text := line_text.substr(cursor_col, text_length - cursor_col)
	set_line(cursor_get_line(), left_text + right_text)
	cursor_set_column(cursor_col - 1)


func first_different_character(str1: String, str2: String) -> String:
	var diff: String = ""
	var len1: int = str1.length()
	var len2: int = str2.length()
	for i in min(len1, len2):
		if not str1[i] == str2[i]:
			return str2[i]
	return ""


func _on_ValidationDelay_timeout() -> void:
	validate()

