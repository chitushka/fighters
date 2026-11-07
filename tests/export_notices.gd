extends SceneTree

func _initialize() -> void:
	var file=FileAccess.open("res://build/GODOT-LICENSE.txt",FileAccess.WRITE)
	file.store_string("WILD INSTINCT — GODOT ENGINE AND THIRD-PARTY NOTICES\n\n")
	file.store_string(Engine.get_license_text())
	file.store_string("\n\nTHIRD-PARTY COMPONENTS\n\n")
	for entry in Engine.get_copyright_info():
		file.store_string(str(entry)+"\n\n")
	for name in Engine.get_license_info():
		file.store_string("\n\n"+name+"\n"+Engine.get_license_info()[name])
	file.close()
	print("Engine license and third-party notices saved")
	quit()
