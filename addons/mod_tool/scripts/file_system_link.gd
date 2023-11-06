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
			params.append("-command New-Item -Path")
			params.append(linkpath)
			params.append("-ItemType")
			params.append("SymbolicLink")
			params.append("-value")
			params.append(target)
			params.append("-name")
			params.append(target.get_file())
			OS.execute("powershell.exe", ["-command", "Start-Process -FilePath \"powershell\" -Verb RunAs -ArgumentList '%s'" % " ".join(params)], true, output)
			return OK

		"X11", "OSX", "LinuxBSD":
			params.append("-s")
			params.append(target)
			params.append(linkpath)
			OS.execute("ln", params, true, output)
			return OK
		_:
			return ERR_UNAVAILABLE
