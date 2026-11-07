extends SceneTree
## UI kitinin temasını (CozyTheme.build, UI-2) proje teması olarak kaydeder: src/ui/theme/main_theme.tres.
## Çalıştırma: godot --headless --script res://tools/build_theme.gd
## CozyTheme'deki renk ya da ölçü değişince yeniden çalıştır.


func _init() -> void:
	var path: String = "res://src/ui/theme/main_theme.tres"
	var err: Error = ResourceSaver.save(CozyTheme.build(), path)
	print("Tema: %s (%s)" % [path, error_string(err)])
	quit(0 if err == OK else 1)
