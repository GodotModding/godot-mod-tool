class_name FileSystemLink
extends Reference


# https://github.com/godot-extended-libraries/godot-next/blob/master/addons/godot-next/global/file_system_link.gd


static func mk_soft_dir(p_target: String, p_linkpath: String = "") -> int:
	var params := PoolStringArray()
	var dir := Directory.new()
	var output := []
	var target := ProjectSettings.globalize_path(p_target)
	var linkpath := ProjectSettings.globalize_path(p_linkpath)

	if not dir.dir_exists(target):
		return ERR_FILE_NOT_FOUND

	match OS.get_name():
		"Windows":
			params = [
				"-command New-Item -Path",
				linkpath,
				"-ItemType",
				"SymbolicLink",
				"-value",
				target,
				"-name",
				target.get_file(),

			]
			OS.execute("powershell.exe", ["-command", "Start-Process -FilePath \"powershell\" -Verb RunAs -ArgumentList '%s'" % " ".join(params)], true, output)
			return OK

		"X11", "OSX", "LinuxBSD":
			params = [
				"-s",
				target,
				linkpath,
			]
			OS.execute("ln", params, true, output)
			return OK
		_:
			return ERR_UNAVAILABLE
