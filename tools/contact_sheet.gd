extends SceneTree
## Bir klasördeki PNG'leri 3x3 sayfalara birleştirir (ekran turunu tek bakışta görmek için).
## godot --headless --script res://tools/contact_sheet.gd -- <klasör>
func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var dir: String = args[0]
	var files: Array = Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool: return f.ends_with(".png") and not f.begins_with("sheet"))
	files.sort()
	var page: int = 0
	for i: int in range(0, files.size(), 9):
		var sheet: Image = Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
		for k: int in mini(9, files.size() - i):
			var img: Image = Image.load_from_file(dir.path_join(files[i + k]))
			img.convert(Image.FORMAT_RGBA8)
			img.resize(640, 360)
			sheet.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i((k % 3) * 640, (k / 3) * 360))
		sheet.save_png(dir.path_join("sheet_%d.png" % page))
		print("sheet_%d: %s" % [page, ", ".join(files.slice(i, i + 9))])
		page += 1
	quit()
