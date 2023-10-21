extends Node
class_name ModToolAPIGenerator

# - This will be executed in the mod creation dialog,
#   from the "generate Mod API Mod" Button.
# - Creates all script extensions
# - Generates the mod_main.gd file
# - Gemerates the manifest.json file

var mod_tool_store: ModToolStore
var mod_namespace: String
var mod_name: String
# Get all vanilla scripts in the game
var all_script_paths: PackedStringArray
var callable_stack: Dictionary
#{
#	"script_path": ["do_stuff"]
#}
var script_needs_regex: Dictionary


func init(_mod_tool_store: ModToolStore) -> void:
	mod_tool_store = _mod_tool_store
	mod_namespace = mod_tool_store.manifest_data.mod_namespace
	mod_name = mod_tool_store.manifest_data.name
	all_script_paths = ModToolUtils.get_flat_view_dict(
		"res://", "", false, "gd", ["res://addons/", "res://mods-unpacked/"]
	)
	callable_stack = get_callable_stack()

	print("script_needs_regex - %s" % JSON.stringify(script_needs_regex, "\t"))

	for script_path in script_needs_regex.keys():
		get_func_args(script_path, script_needs_regex[script_path])

	print("callable_stack -> %s" % JSON.stringify(callable_stack, "\t"))


func create_mod_main() -> void:
	var mod_main_path := mod_tool_store.path_mod_dir.path_join("mod_main.gd")

	# Delete the existing mod_main.gd
	DirAccess.remove_absolute(mod_main_path)
	# Generate the new mod_main.gd
	var mod_main_content := template_mod_main()

	var file := FileAccess.open(mod_main_path, FileAccess.WRITE)
	file.store_string(mod_main_content)
	file.close()


func create_script_extensions() -> void:
	for script_path in callable_stack.keys():
		# Generate extension content
		var extension_content := template_extension(script_path, callable_stack[script_path].keys())

		# Add Extension Directory
		var file_directory: String = script_path.get_base_dir().trim_prefix("res://")
		var extension_directory: String = mod_tool_store.path_mod_dir.path_join("extensions").path_join(file_directory)
		ModToolUtils.make_dir_recursive(extension_directory)

		# Save extension content to extension script file
		var extension_path := extension_directory.path_join(script_path.get_file())
		var file := FileAccess.open(extension_path, FileAccess.WRITE)
		file.store_string(extension_content)
		file.close()


func remove_type_declarations(input_string: String) -> String:
	# translation_key: String, format_string_values: Array = [], format_string_value_signs := []
	var split_1 := input_string.split(":")
	var new_string_array := []
#	[
#	"translation_key",
#	" String, format_string_values",
#	" Array = [], format_string_value_signs",
#	"= []"
#	]
	for result in split_1:
		var new_string := result.strip_edges()
		if not new_string.begins_with("="):
			# Serch for =
			var index := new_string.find("=")
			# If = was found
			if not index == -1:
				# Delete everything before it
				new_string = new_string.erase(0, index)
			else:
				var indexx := new_string.find(",")
				# If , was found
				if not indexx == -1:
					# Delete everything before it
					new_string = new_string.erase(0, indexx)

		new_string_array.push_back(new_string)

	#	[
#	"translation_key",
#	", format_string_values",
#	"= [], format_string_value_signs",
#	"= []"
#	]

#	"translation_key, format_string_values= [], format_string_value_signs= []"
	var joined := "".join(new_string_array)

	return joined


func remove_defaults(input_string: String) -> String:
	# focus_prop, node= null, node_path= ""
#			[
#				"focus_prop, node",
#				"null, node_path",
#				"""" <- if no comma on last index delete index
#			]
	var split_1 := input_string.split('=')

	# focus_prop, node null, node_path ""
	var join_1 := "".join(split_1)

#	[
#		"focus_prop",
#		"node null",
#		"node_path """,
#	]
	var split_2 := join_1.split(",")

	for result in split_2:
		var new_string := result.strip_edges()
		var split_3 := new_string.split(" ")
		new_string = split_3[0]

	return ""

func get_func_args(script_path: String, method_names: Array) -> void:
	var file := FileAccess.open(script_path, FileAccess.READ)
	var script_text := file.get_as_text()

	var regex := RegEx.new()
	regex.compile("func\\s*(\\w+)\\(([^()]*(\\([^)]*\\)[^()]*)*)\\)(?:\\s*->\\s*(\\w+))?")
	var script_text_matches := regex.search_all(script_text)

	for script_text_match in script_text_matches:
		var full := script_text_match.get_string(0)
		var func_name := script_text_match.get_string(1)
		var args := script_text_match.get_string(2)
		var possible_parentheses := script_text_match.get_string(3)
		var return_type := script_text_match.get_string(4)

		if func_name in method_names:
			print("args: %s " % args)
			# translation_key: String, format_string_values: Array = [], format_string_value_signs := []
			# Strip types - types can be `arg_name: type` or `arg_name := value`
				# Remove all `:`
				# If there is no `=` right after the `:` remove the following word
			var new_args_with_defaults := remove_type_declarations(args)
			print("removed_types -> %s" % new_args_with_defaults)

			# translation_key, format_string_values = [], format_string_value_signs = []
			# Get arg_name
			# Get arg_default_value
			callable_stack[script_path][func_name].args_with_defaults = args


func get_arg_names(args: Array) -> Array:
	var arg_names := []
	for arg in args:
		arg_names.push_back(arg.name)
	return arg_names


func generate_args_dict(script_path: String, script_method: Dictionary) -> Array:
	var args := []

	# Check if there are any default_args for this method
	# If there are no default_args
	if not script_method.default_args.is_empty():
		# If there are default_args - save the script_path for later
		if not script_needs_regex.has(script_path):
			script_needs_regex[script_path] = []
		script_needs_regex[script_path].push_back(script_method.name)

	# Grab the names
	args = get_arg_names(script_method.args)

	return args


# Construct something like this:
#	{
#		"res://ui/menus/title_screen/title_screen.gd": {
#			"_ready": {
#				"args": [{name: "do_stuff"}, {name: "do_more_stuff", default: "null"}],
#				"before": [],
#				"after": [],
#			},
#		},
#	}
func get_callable_stack() -> Dictionary:
	var callable_stack := {}

	# For each script
	for script_path in all_script_paths:
		# For each method
		var script: Object = load(script_path)
		# This will ony give the methods existing in the script,
		# so we might want to add methods that mods want to use manually.
		# ( Something like _init() or _ready() or other virtual methods !?)
		var existing_script_methods: Array[Dictionary] = script.get_script_method_list()

		for script_method in existing_script_methods:
			# Set functions are add with @var_name
			if script_method.name.begins_with("@"):
				continue

			if not callable_stack.has(script_path):
				callable_stack[script_path] = {}
			if not callable_stack[script_path].has(script_method.name):
				callable_stack[script_path][script_method.name] = {}
			callable_stack[script_path][script_method.name].is_static = script_method.flags == 33
			callable_stack[script_path][script_method.name].args_no_defaults = generate_args_dict(script_path, script_method)
			callable_stack[script_path][script_method.name].args_with_defaults = ""
			callable_stack[script_path][script_method.name].before = []
			callable_stack[script_path][script_method.name].after = []

	return callable_stack


func template_mod_main() -> String:
	var template_mod_main := """
extends Node


# --- This file is automatically generated by the Mod Tool ---


const {%NAMESPACE_UPPERCASE%}_{%MODNAME_UPPERCASE%}_DIR := "{%NAMESPACE%}-{%MODNAME%}"
const {%NAMESPACE_UPPERCASE%}_{%MODNAME_UPPERCASE%}_LOG_NAME := "{%NAMESPACE%}-{%MODNAME%}:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""


func _init() -> void:
	ModLoaderMod.set_callable_stack(
		{%CALLABLE_STACK%}
	)

	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join({%NAMESPACE_UPPERCASE%}_{%MODNAME_UPPERCASE%}_DIR)
	# Add extensions
	install_script_extensions()


func install_script_extensions() -> void:
	{%INSTALL_SCRIPT_EXTENSIONS%}
	""".format({
		"%NAMESPACE_UPPERCASE%": mod_namespace.to_upper(),
		"%MODNAME_UPPERCASE%": mod_name.to_upper(),
		"%NAMESPACE%": mod_namespace,
		"%MODNAME%": mod_name,
		"%CALLABLE_STACK%": JSON.stringify(callable_stack, "\t"),
		"%INSTALL_SCRIPT_EXTENSIONS%": tempalte_script_extensions(),
	})

	return template_mod_main


func tempalte_script_extensions() -> String:
	var add_script_extensions_template := ""

	var script_extension_template := "ModLoaderMod.install_script_extension(\"%s\")"

	for script_path in all_script_paths:
		add_script_extensions_template = "%s\n\t%s" % [add_script_extensions_template, script_extension_template % script_path]

	return add_script_extensions_template


func template_extension(script_path: String, method_names: Array) -> String:
	var template_extension := """
extends "{%SCRIPT_PATH%}"


# --- This file is automatically generated by the Mod Tool ---
{%TEMPLATE_METHODS%}

	""".format({
		"%SCRIPT_PATH%": script_path,
		"%TEMPLATE_METHODS%": tempalte_methods(script_path, method_names),
	})

	return template_extension


#func write(translation_key: String,  format_string_values := [],  format_string_value_signs := []):
#	ModLoaderMod.call_from_callable_stack(self, "res://singletons/text_manager.gd", "write", true)
#	super.write(translation_key,  format_string_values,  format_string_value_signs)
#	ModLoaderMod.call_from_callable_stack(self, "res://singletons/text_manager.gd", "write", false)

func tempalte_methods(script_path: String, method_names: Array) -> String:
	var template_methods := ""

	for method_name in method_names:
		var template_method := """


{%STATIC%}func {%METHOD_NAME%}({%METHOD_ARGS_WITH_DEFAULTS%}):
	ModLoaderMod.call_from_callable_stack({%SELF%}, "{%SCRIPT_PATH%}", "{%METHOD_NAME%}", true)
	super.{%METHOD_NAME%}({%METHOD_ARGS_NO_DEFAULTS%})
	ModLoaderMod.call_from_callable_stack({%SELF%}, "{%SCRIPT_PATH%}", "{%METHOD_NAME%}", false)
	""".format({
			"%STATIC%": "static " if callable_stack[script_path][method_name].is_static else "",
			"%METHOD_NAME%": method_name,
			"%SCRIPT_PATH%": script_path,
			"%METHOD_ARGS_WITH_DEFAULTS%": ", ".join(callable_stack[script_path][method_name].args_no_defaults) if callable_stack[script_path][method_name].args_with_defaults == "" else callable_stack[script_path][method_name].args_with_defaults,
			"%METHOD_ARGS_NO_DEFAULTS%": ", ".join(callable_stack[script_path][method_name].args_no_defaults),
			"%SELF%": "null" if callable_stack[script_path][method_name].is_static else "self",
		})

		template_methods = "%s%s" % [template_methods, template_method]

	return template_methods
