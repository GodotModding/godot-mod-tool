class_name ModToolSteamWorkshopData
extends Resource


export var file_id: int
export var title: String
export var description: String
export var preview: Texture
export var preview_file_path: String
export var tags: PoolStringArray


func _init(
	_file_id: int,
	_title: String,
	_description: String,
	_preview: Texture = null,
	_tags := PoolStringArray()
) -> void:
	file_id = _file_id
	title = _title
	description = _description
	preview = _preview
	tags = _tags


func get_file_id_as_string() -> String:
	return str(file_id)
