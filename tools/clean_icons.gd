extends SceneTree
## İkon paketinin kırpma artıklarını temizler (UI-4): kenara değen, ana görselden en az GAP piksellik boş şeritle
## ayrılmış ve görselin MAX_PART oranından ince parçalar (komşu ikondan kalan kenar) saydam yapılır.
## Çalıştırma: godot --headless --script res://tools/clean_icons.gd [-- --dry]   (varsayılan klasör assets/ui/icons)

const DIR: String = "res://assets/ui/icons"
const GAP: int = 3
const MAX_PART: float = 0.3
const ALPHA: float = 0.08


func _init() -> void:
	var dry: bool = OS.get_cmdline_user_args().has("--dry")
	var fixed: int = 0
	for f: String in DirAccess.get_files_at(DIR):
		if not f.ends_with(".png"):
			continue
		var path: String = ProjectSettings.globalize_path(DIR.path_join(f))
		var img: Image = Image.load_from_file(path)
		if img == null or not img.detect_alpha():
			continue
		img.convert(Image.FORMAT_RGBA8)
		var cleared: Array[String] = []
		# Alt kenar bilerek yok: ampulün dibi, satranç atının kaidesi gibi ayrık ama ikona ait parçalar orada.
		for side: String in ["top", "left", "right"]:
			var band: int = _edge_part(img, side)
			if band > 0:
				cleared.append("%s %dpx" % [side, band])
				if not dry:
					_clear(img, side, band)
		if cleared.is_empty():
			continue
		fixed += 1
		print("%s: %s" % [f, ", ".join(cleared)])
		if not dry:
			img.save_png(path)
	print("Temizlenen ikon: %d%s" % [fixed, " (deneme, dosyalar değişmedi)" if dry else ""])
	quit()


## Kenardan başlayan dolu şerit, ardından en az GAP boş satır/sütun, ardından yine dolu: ince şeridin kalınlığı.
func _edge_part(img: Image, side: String) -> int:
	var horizontal: bool = side == "top" or side == "bottom"
	var n: int = img.get_height() if horizontal else img.get_width()
	var filled: Array[bool] = []
	for i: int in n:
		var line: int = n - 1 - i if (side == "bottom" or side == "right") else i
		filled.append(_line_has_ink(img, line, horizontal))
	if not filled[0]:
		return 0
	var i2: int = 0
	while i2 < n and filled[i2]:
		i2 += 1
	var band: int = i2
	var gap: int = 0
	while i2 < n and not filled[i2]:
		i2 += 1
		gap += 1
	if gap < GAP or i2 >= n or band > int(n * MAX_PART):
		return 0
	return band


func _line_has_ink(img: Image, line: int, horizontal: bool) -> bool:
	var len: int = img.get_width() if horizontal else img.get_height()
	for k: int in len:
		var c: Color = img.get_pixel(k, line) if horizontal else img.get_pixel(line, k)
		if c.a > ALPHA:
			return true
	return false


func _clear(img: Image, side: String, band: int) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for i: int in band:
		for k: int in (w if side == "top" or side == "bottom" else h):
			match side:
				"top":
					img.set_pixel(k, i, Color(0, 0, 0, 0))
				"bottom":
					img.set_pixel(k, h - 1 - i, Color(0, 0, 0, 0))
				"left":
					img.set_pixel(i, k, Color(0, 0, 0, 0))
				"right":
					img.set_pixel(w - 1 - i, k, Color(0, 0, 0, 0))
