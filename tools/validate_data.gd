extends SceneTree
## Veri doğrulama (GDD 8.0 + id tutarlılığı).
## Çalıştırma: godot --headless --script res://tools/validate_data.gd
## Başka klasör: godot --headless --script res://tools/validate_data.gd -- --data-dir=<yol>

const DataValidatorScript: GDScript = preload("res://tools/data_validator.gd")


func _init() -> void:
	var data_dir: String = DataValidatorScript.DEFAULT_DATA_DIR
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--data-dir="):
			data_dir = arg.trim_prefix("--data-dir=")
	var validator: DataValidator = DataValidatorScript.new()
	var errors: PackedStringArray = validator.validate_dir(data_dir)
	if errors.is_empty():
		print("Veri doğrulama BAŞARILI: %s" % data_dir)
		quit(0)
		return
	for message: String in errors:
		printerr("HATA: " + message)
	printerr("Veri doğrulama BAŞARISIZ: %d hata (%s)" % [errors.size(), data_dir])
	quit(1)
