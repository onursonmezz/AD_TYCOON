extends SceneTree
## UI kitinin temasını (UiTheme.build) proje teması olarak kaydeder: src/ui/theme/main_theme.tres.
## Çalıştırma: godot --headless --script res://tools/build_theme.gd
## UiTheme'deki renk ya da ölçü değişince yeniden çalıştır.


func _init() -> void:
	var path: String = "res://src/ui/theme/main_theme.tres"
	var err: Error = ResourceSaver.save(UiTheme.build(), path)
	print("Tema: %s (%s)" % [path, error_string(err)])
	quit(0 if err == OK else 1)
